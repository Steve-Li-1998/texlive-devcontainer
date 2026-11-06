#!/usr/bin/env bash
# Look for rtex and Realtime TeX releases newer than the versions pinned here, and bump the
# pins in place. Also move the template/ submodule to the template repository's main (staged
# in the index; the submodule itself need not be checked out). Prints KEY=VALUE lines (for
# $GITHUB_OUTPUT):
#   rtex_old, rtex_new, ext_old, ext_new, template_old, template_new, changed=true|false
# A release counts only once it is usable: rtex's Linux binaries (amd64 and arm64) are
# attached to the release, and the extension version is on the Marketplace (devcontainer.json
# installs it from there).
set -euo pipefail
cd "$(dirname "$0")/.."

api() { curl -fsSL ${GH_TOKEN:+-H "Authorization: Bearer $GH_TOKEN"} "https://api.github.com/repos/$1"; }
newer() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" = "$2" ]; }

rtex_old=$(sed -n -E 's/^ARG RTEX_VERSION=//p' Dockerfile)
ext_old=$(grep -o -E 'henryxiaoyang\.realtime-tex@[0-9][0-9.]*' .devcontainer/devcontainer.json | head -n 1 | cut -d@ -f2)

release=$(api HenryXiaoYang/realtime-tex/releases/latest)
rtex_new=$(jq -r .tag_name <<<"$release")
for asset in rtex-x86_64-unknown-linux-gnu.tar.gz rtex-aarch64-unknown-linux-gnu.tar.gz; do
    if ! jq -e --arg a "$asset" '.assets[] | select(.name == $a)' <<<"$release" >/dev/null; then
        rtex_new=$rtex_old  # the binaries are attached a few minutes after the release is published
    fi
done

ext_new=$(api HenryXiaoYang/realtime-tex-vsc-plugin/releases/latest | jq -r '.tag_name | ltrimstr("v")')
marketplace=$(curl -fsS -X POST https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery \
    -H 'Content-Type: application/json' -H 'Accept: application/json;api-version=3.0-preview.1' \
    -d '{"filters":[{"criteria":[{"filterType":7,"value":"henryxiaoyang.realtime-tex"}]}],"flags":1}' \
    | jq -r '.results[0].extensions[0].versions[].version')
grep -qxF "$ext_new" <<<"$marketplace" || ext_new=$ext_old

changed=false
if newer "$rtex_old" "$rtex_new"; then
    sed -i -E "s/^ARG RTEX_VERSION=.*/ARG RTEX_VERSION=$rtex_new/" Dockerfile
    sed -i -E "/^variable \"RTEX_VERSION\"/,/^}/ s/default = \".*\"/default = \"$rtex_new\"/" docker-bake.hcl
    changed=true
else
    rtex_new=$rtex_old
fi
if newer "$ext_old" "$ext_new"; then
    sed -i -E "s/henryxiaoyang\.realtime-tex@[0-9][0-9.]*/henryxiaoyang.realtime-tex@$ext_new/" .devcontainer/devcontainer.json
    changed=true
else
    ext_new=$ext_old
fi

# the template repository has its own daily check for the extension; follow its main
template_old=$(git ls-tree HEAD template | awk '{print $3}')
template_new=$(git ls-remote "$(git config -f .gitmodules submodule.template.url)" refs/heads/main | cut -f1)
if [ -n "$template_new" ] && [ "$template_new" != "$template_old" ]; then
    git update-index --cacheinfo "160000,$template_new,template"
    changed=true
else
    template_new=$template_old
fi

printf 'rtex_old=%s\nrtex_new=%s\next_old=%s\next_new=%s\ntemplate_old=%s\ntemplate_new=%s\nchanged=%s\n' \
    "$rtex_old" "$rtex_new" "$ext_old" "$ext_new" "$template_old" "$template_new" "$changed"
