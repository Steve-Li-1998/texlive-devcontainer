# Notes for agents

## Building and pushing the images

The images are multi-platform (`linux/amd64`, `linux/arm64`) and come from `main` with upstream releases. The extension is not in the image: devcontainer.json installs `henryxiaoyang.realtime-tex@<version>` from the Marketplace.

The current `texlive-ci:latest` base was assembled by hand on 2026-11-06 from the amd64 base installed 2026-11-01 and an arm64 base installed 2026-11-06 by a test run on the `arm64` branch; its tags say `20261101` for both platforms. The user accepted that mismatch: the next run with `reuse_base` off brings both platforms to the same TeX Live date.

1. Bump versions in BOTH the Dockerfile `ARG` defaults and the `docker-bake.hcl` variables (the dev container builds from the Dockerfile without bake; bake passes them as build args). `TEXLIVE_VERSION` is `2026`; the base stage fails the build when the installed TeX Live year differs, which happens once TeX Live 2027 is out (around April 2027). When bumping the extension, change the version in both devcontainer.json files.
2. Push to `main`, then run the `images` workflow (`.github/workflows/images.yml`, manual trigger). A `prepare` job picks the base and TeX Live date; a `build` matrix builds each platform on a native runner (`ubuntu-24.04`, `ubuntu-24.04-arm`), runs `tests/smoke.sh` in the dev image (bake target `smoketest`) and pushes by digest; a `merge` job tags the multi-platform images, all with `GITHUB_TOKEN`. Only builds of `main` (or a merged `build-images` PR) get `latest` and the version tag; other branches get `test-<branch>`. Images are only on ghcr.io now: `ghcr.io/steve-li-1998/texlive-ci` and `-devcontainer`, tagged `latest` and `texlive<year>.<date>-rtex<ver>` (e.g. `texlive2026.20261101-rtex0.0.6`). The date is the day TeX Live was installed (UTC). The GitLab registry images are no longer updated.
3. The workflow's `reuse_base` input (default on) reuses `texlive-ci:latest` (which must contain both platforms) as the base of both targets (bake `--set '*.contexts.base=…'`; overriding only `dev.contexts.base` would still rebuild the base for ci) and takes `TEXLIVE_DATE` from the dated tag on that image. This keeps the old TeX Live packages, so package fixes need a run with `reuse_base` off.
4. The `check-upstream` workflow runs daily (`scripts/check-upstream.sh`): when rtex or the extension has a newer usable release, it opens or updates a PR from the `upstream-update` branch that bumps the Dockerfile, `docker-bake.hcl` and `.devcontainer/devcontainer.json`. If rtex changed, the PR is labeled `build-images`, and merging it runs `images` with the base reused. It also moves the `template/` submodule pointer to the template repository's `main`. That repository has its own daily `check-upstream` at 04:11 UTC (only runs in that repository, not in projects made from it) that opens a PR bumping the extension there and merges it right away, an hour before this one at 05:17; this workflow's `GITHUB_TOKEN` cannot push to it.
5. Prefer the workflows over building locally. Locally, `docker buildx bake smoketest` builds and tests without pushing.

## Template submodule

`template/` is a submodule: [Steve-Li-1998/texlive-devcontainer-template](https://github.com/Steve-Li-1998/texlive-devcontainer-template). Clone with `--recurse-submodules` (or run `git submodule update --init`). To change the template, commit and push inside `template/` first, then commit the new submodule pointer in this repository. Its `.devcontainer/devcontainer.json` must stay in step with this repository's when settings or the extension version change.

## Hotfixes

Do NOT delete the `hotfix` and `hotfix-rtex-stale-diagnostics` branches, the fork fix branches or the fork releases (`v0.0.4.0.1`, `v0.0.5.0.1`, `v0.0.1-fix-jump`): the user keeps them for future hotfixes. Old `:dev`, `texlive2026-rtex…-ext…` and GitLab `thesis:latest`-style tags can optionally go once nothing uses them.

## Working with the user

- Make only the change asked for; add alternatives alongside instead of deleting existing text or spreading the change to other files.
