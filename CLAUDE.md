# Notes for agents

## Building and pushing the images

The current images come from `main` with upstream releases: rtex v0.0.6, TeX Live 2026 with the packages as of 2026-11-01. The extension is not in the image: devcontainer.json installs `henryxiaoyang.realtime-tex@0.0.3` from the Marketplace.

1. Bump versions in BOTH the Dockerfile `ARG` defaults and the `docker-bake.hcl` variables (the dev container builds from the Dockerfile without bake; bake passes them as build args). `TEXLIVE_VERSION` is `2026`; the base stage fails the build when the installed TeX Live year differs, which happens once TeX Live 2027 is out (around April 2027). When bumping the extension, change the version in both devcontainer.json files.
2. Push to `main`, then run the `images` workflow (`.github/workflows/images.yml`, manual trigger). It builds, runs `tests/smoke.sh` in the dev image (bake target `smoketest`), and only then pushes with `GITHUB_TOKEN`. Images are only on ghcr.io now: `ghcr.io/steve-li-1998/texlive-ci` and `-devcontainer`, tagged `latest` and `texlive<year>.<date>-rtex<ver>` (e.g. `texlive2026.20261101-rtex0.0.6`). The date is the day TeX Live was installed (UTC). The GitLab registry images are no longer updated.
3. The workflow's `reuse_base` input (default on) reuses `texlive-ci:latest` as the base of both targets (bake `--set '*.contexts.base=…'`; overriding only `dev.contexts.base` would still rebuild the base for ci) and takes `TEXLIVE_DATE` from the dated tag on that image. This keeps the old TeX Live packages, so package fixes need a run with `reuse_base` off.
4. The `check-upstream` workflow runs daily (`scripts/check-upstream.sh`): when rtex or the extension has a newer usable release, it opens or updates a PR from the `upstream-update` branch that bumps the Dockerfile, `docker-bake.hcl` and `.devcontainer/devcontainer.json`. If rtex changed, the PR is labeled `build-images`, and merging it runs `images` with the base reused. It cannot change the template repository: bump the extension in `template/` by hand.
5. Prefer the workflows over building locally. Locally, `docker buildx bake smoketest` builds and tests without pushing.

## Template submodule

`template/` is a submodule: [Steve-Li-1998/texlive-devcontainer-template](https://github.com/Steve-Li-1998/texlive-devcontainer-template). Clone with `--recurse-submodules` (or run `git submodule update --init`). To change the template, commit and push inside `template/` first, then commit the new submodule pointer in this repository. Its `.devcontainer/devcontainer.json` must stay in step with this repository's when settings or the extension version change.

## Hotfixes

Do NOT delete the `hotfix` and `hotfix-rtex-stale-diagnostics` branches, the fork fix branches or the fork releases (`v0.0.4.0.1`, `v0.0.5.0.1`, `v0.0.1-fix-jump`): the user keeps them for future hotfixes. Old `:dev`, `texlive2026-rtex…-ext…` and GitLab `thesis:latest`-style tags can optionally go once nothing uses them.

## Working with the user

- Make only the change asked for; add alternatives alongside instead of deleting existing text or spreading the change to other files.
