# Project template

Files to copy into a new LaTeX project that uses these images:

```bash
cp -r template/. /path/to/new-project/
```

| File | Purpose |
|---|---|
| `.devcontainer/devcontainer.json` | Opens the project in the prebuilt `dev` image, with rtex live preview and shell escape |
| `.gitlab-ci.yml` | Builds `main.pdf` in the `ci` image |
| `.latexmkrc` | Makes `latexmk` use LuaLaTeX |
| `.gitignore` | Ignores LaTeX build files and minted/mermaid/plantuml output |

## After copying

Replace the placeholders:

| Placeholder | In | Example |
|---|---|---|
| `<IMAGE>` | `.devcontainer/devcontainer.json`, `.gitlab-ci.yml` | `registry.gitlab.fachschaften.org/masterarbeit/thesis` or `ghcr.io/steve-li-1998/texlive-devcontainer` |
| `<PROJECT_NAME>` | `.devcontainer/devcontainer.json` | `Masterarbeit` |

`<IMAGE>` is the repository without a tag: the dev container appends `:dev`, CI appends `:latest`. For example:

```bash
cd /path/to/new-project
sed -i 's|<IMAGE>|registry.gitlab.fachschaften.org/masterarbeit/thesis|; s|<PROJECT_NAME>|Masterarbeit|' \
  .devcontainer/devcontainer.json .gitlab-ci.yml
```

Also check:

- **Main file:** CI builds `main.tex`. Change `FILE_NAME` in `.gitlab-ci.yml` if yours is named differently.
- **Registry access:** `ghcr.io/steve-li-1998/texlive-devcontainer` is public and needs no login. The GitLab registry images are private: run `docker login` for that registry before opening the dev container, and a GitLab CI job in another project can only pull them if that project is allowed in the image project's *Settings → CI/CD → Job token permissions*.
- **First start:** if the Realtime TeX extension is missing, install it via *Extensions: Install from VSIX…* → `/opt/rtex/realtime-tex.vsix`.

## Writing the document

- Compile with LuaLaTeX. Under LuaLaTeX, don't load `\usepackage[T1]{fontenc}`: it turns `ß` into "SS" and `§` into "ğ". If the document must also build with pdfLaTeX, load it only there:
  ```latex
  \usepackage{iftex}
  \ifPDFTeX
    \usepackage[utf8]{inputenc}
    \usepackage[T1]{fontenc}
  \fi
  ```
- With `babel` and `ngerman`, use `\usepackage[ngerman,shorthands=off]{babel}`; the active `"` breaks rtex's live preview.
- For Mermaid, prefer `\usepackage{ltmermaid}`: the LuaLaTeX version of `mermaid.sty`, with the same `mermaid` environment, that handles the output directory (used by rtex and the LaTeX Workshop settings) by itself and needs no extra line.
- With `mermaid`, add this right after `\usepackage{mermaid}`. The package creates `mermaid/` in the working directory, but writes into the output directory, which rtex sets; without the line, rtex's live engine stops with "I can't write on file":
  ```latex
  \ShellEscape{mkdir -p "${TEXMF_OUTPUT_DIRECTORY:-.}/mermaid"}
  ```
- Load `minted` before `csquotes`; the other order warns about `fvextra` and `\@parboxrestore`.
