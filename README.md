# TeX Live dev container

Docker images for writing LaTeX: a full TeX Live 2026 with diagram and code-listing tools, plus a VS Code dev container with live preview. The same base is used for local editing and for CI, so a document builds the same way in both.

## Images

| Image | Use | Default user |
|---|---|---|
| `ghcr.io/steve-li-1998/texlive-devcontainer` | VS Code dev container | `vscode` |
| `ghcr.io/steve-li-1998/texlive-ci` | CI and one-off builds | `root` |

Both are public and need no login. Each is tagged `latest` and `texlive<year>.<date>-rtex<version>`, for example `texlive2026.20261101-rtex0.0.6`. The date is the day TeX Live was installed, because its packages keep changing within a TeX Live year. Pin that tag if you need a build to stay reproducible.

The images are `linux/amd64` only and about 8 GB to download.

### What's inside

Both images contain:

- TeX Live 2026 (`scheme-full`) with `latexmk`
- Python and Pygments, for `minted`
- Java, Graphviz and PlantUML, for `plantuml`
- Node.js, Mermaid CLI and Chromium, for `mermaid` and `ltmermaid`
- Inkscape, Git and `make`

The dev container image also has the [rtex](https://github.com/HenryXiaoYang/realtime-tex) live preview engine and a non-root user with passwordless `sudo`.

## Start a new project

Start from [texlive-devcontainer-template](https://github.com/Steve-Li-1998/texlive-devcontainer-template) (**Use this template** on GitHub, or copy its files into your project) and fill in the placeholders. Its README has the steps and some notes on writing documents with these images. In this repository it is the `template/` submodule.

The template contains a dev container configuration, a GitLab CI job, a `.latexmkrc` and a `.gitignore`. Opening the project with **Dev Containers: Reopen in Container** gives you:

- [Realtime TeX](https://marketplace.visualstudio.com/items?itemName=henryxiaoyang.realtime-tex) for the live preview
- [LaTeX Workshop](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop) for editing support and on-demand builds into `out/`
- [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker) for spelling and [LTeX+](https://marketplace.visualstudio.com/items?itemName=ltex-plus.vscode-ltex-plus) for grammar

## Build a document without VS Code

```bash
docker run --rm -v "$PWD":/work -w /work ghcr.io/steve-li-1998/texlive-ci:latest \
  latexmk -lualatex main.tex
```

The container runs as `root`, so the files it writes on Linux belong to `root`.

Use LuaLaTeX: `plantuml.sty` and rtex don't support other engines.

## Security

The images run LaTeX with shell escape enabled, which `minted`, `plantuml` and `mermaid` need: `latexmk` always passes `-shell-escape`, and the dev container sets `shell_escape=t`. A `.tex` file compiled here can run any command in the container, and in a dev container that includes using your forwarded SSH agent. Only compile documents you trust.

## Build the images yourself

```bash
docker build -t texlive-ci .               # the ci image (default target)
docker build --target dev -t texlive-dev . # the dev container image
```

A build installs TeX Live from CTAN, which takes about 20 minutes and over 20 GB of disk space.

The published images are built by the [`images`](.github/workflows/images.yml) workflow, started by hand from the Actions tab. It compiles a test document in the dev image ([`tests/smoke.sh`](tests/smoke.sh)) and pushes only if that succeeds. By default it reuses the published TeX Live base and only rebuilds the rest; turn off **reuse_base** to reinstall TeX Live with the latest CTAN packages.

The [`check-upstream`](.github/workflows/check-upstream.yml) workflow checks daily for new releases of rtex and the Realtime TeX extension and opens a pull request that updates them. Merging a PR that updates rtex runs `images`.

The same build runs locally with [`docker-bake.hcl`](docker-bake.hcl):

```bash
docker buildx bake smoketest   # build and test, push nothing
```

`.devcontainer/` opens this repository in an image built from the local `Dockerfile`, for testing changes to it. New projects should use the template instead, which pulls the published image.
