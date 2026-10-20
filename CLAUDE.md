# Notes for agents

## Pending: next image build and push

The current images (`<base>-ci` and `<base>-devcontainer`, tagged `latest` and `texlive2026-rtex0.0.4.0.1-ext0.0.1-fix-jump`) were built from the `hotfix` branch with forked releases:

- rtex `Steve-Li-1998/realtime-tex` v0.0.4.0.1: fix for pages without glyphs (empty fonts table). Upstream PR [realtime-tex#9](https://github.com/HenryXiaoYang/realtime-tex/pull/9) is merged and released in v0.0.5.
- Extension `Steve-Li-1998/realtime-tex-vsc-plugin` 0.0.1-fix-jump: double-click in the preview jumps to files no editor has open. Upstream PR [realtime-tex-vsc-plugin#7](https://github.com/HenryXiaoYang/realtime-tex-vsc-plugin/pull/7) is merged but not released yet (latest release 0.0.1, from before the merge).

The user rebuilds only once both fixes are released upstream. Then:

1. Before building anything, remind the user and check that BOTH upstream fixes are released: the latest realtime-tex release contains #9 and the latest realtime-tex-vsc-plugin release contains #7 (compare each PR's merge commit with the release tag, e.g. via the GitHub compare API). If either is missing, don't build yet.
2. On `main`, bump in BOTH the Dockerfile `ARG` defaults and the `docker-bake.hcl` variables (the dev container builds from the Dockerfile without bake; bake passes them as build args):
   - `RTEX_VERSION` → `v0.0.5` or later
   - `RTEX_VSIX_VERSION` → the new extension release
   - `TEXLIVE_VERSION` stays `2026`; the base stage fails the build when the installed TeX Live year differs, which happens once TeX Live 2027 is out (around April 2027).
3. Build and push with `docker buildx bake --push`. Images are now `<base>-ci` and `<base>-devcontainer`, tagged `latest` and `texlive<year>-rtex<ver>-ext<ver>` (e.g. `texlive2026-rtex0.0.5-ext0.0.2`), with bases `registry.gitlab.fachschaften.org/masterarbeit/{thesis,final-presentation}/texlive` and `ghcr.io/steve-li-1998/texlive`. To skip reinstalling TeX Live, build only the dev stage on an existing ci image with `--set dev.contexts.base=docker-image://ghcr.io/steve-li-1998/texlive-ci:latest`. If you copy images by pulling, re-tagging and pushing instead, GitLab rejects the multi-platform index with `blob unknown`: push the amd64 platform manifest by digest instead.
4. If the ghcr.io package `texlive-ci` is still private (it was created private on 2026-10-20), remind the user to make it public and link it to this repository.
5. Delete the `hotfix` branch locally and on GitHub. Optionally delete the fork fix branches and fork releases (`v0.0.4.0.1`, `v0.0.1-fix-jump`), and old `:dev` / GitLab `thesis:latest`-style tags once nothing uses them.

## Working with the user

- Make only the change asked for; add alternatives alongside instead of deleting existing text or spreading the change to other files.
