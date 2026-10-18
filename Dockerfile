FROM debian:bookworm AS base

LABEL maintainer="Hao LI <hao3.li@tu-dortmund.de>"
LABEL description="TeX Live full with Python 3 and Pygments for LaTeX minted support"

# 安装依赖
RUN apt-get update && \
    apt-get install -y \
    wget \
    perl \
    fontconfig \
    xz-utils \
    git \
    curl \
    make \
    build-essential \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 下载 TeX Live 安装器# 安装 TeX Live
RUN mkdir -p /install-tl && \
    cd /install-tl && \
    wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
    tar -xzf install-tl-unx.tar.gz --strip-components=1 && \
    printf '%s\n' \
      'selected_scheme scheme-full' \
      'instopt_adjustpath 1' \
      'tlpdbopt_sys_bin /usr/local/bin' \
      'tlpdbopt_sys_man /usr/local/share/man' \
      'tlpdbopt_sys_info /usr/local/share/info' \
      > texlive.profile && \
    ./install-tl -no-interaction -profile texlive.profile && \
    rm -rf /install-tl

# install Python 3 and pip，then install pygments
RUN apt-get update && \
    apt-get install -y python3 python3-pip inkscape && \
    pip3 install --break-system-packages --no-cache-dir pygments && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# # verify whether pygmentize successfully installed（optional）
# RUN which pygmentize && pygmentize -V

# Diagram tools for the plantuml and mermaid LaTeX packages
ARG PLANTUML_VERSION=1.2026.8
ARG NODE_VERSION=22.23.3
# mermaid.sty calls `mmdc -f`; mermaid-cli 12 dropped -f/--pdfFit, so stay on 11.x
ARG MERMAID_CLI_VERSION=11.17.0

ENV PLANTUML_JAR=/opt/plantuml/plantuml.jar \
    PUPPETEER_SKIP_DOWNLOAD=1

# PlantUML: Java + Graphviz + pinned plantuml.jar
RUN apt-get update && \
    apt-get install -y default-jre-headless graphviz && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /opt/plantuml && \
    curl -fsSL -o "${PLANTUML_JAR}" \
        "https://github.com/plantuml/plantuml/releases/download/v${PLANTUML_VERSION}/plantuml-${PLANTUML_VERSION}.jar" && \
    printf '#!/bin/sh\nexec java -Djava.awt.headless=true -jar "%s" "$@"\n' "${PLANTUML_JAR}" > /usr/local/bin/plantuml && \
    chmod +x /usr/local/bin/plantuml && \
    plantuml -version

# Mermaid: Node.js (official build) + mermaid-cli, rendering with Debian's Chromium
RUN apt-get update && \
    apt-get install -y chromium && \
    rm -rf /var/lib/apt/lists/* && \
    case "$(dpkg --print-architecture)" in \
        amd64) node_arch=x64 ;; \
        arm64) node_arch=arm64 ;; \
        *) echo "unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac && \
    node_tar="node-v${NODE_VERSION}-linux-${node_arch}.tar.xz" && \
    cd /tmp && \
    curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/${node_tar}" && \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" | grep " ${node_tar}\$" | sha256sum -c - && \
    tar -xJf "${node_tar}" -C /usr/local --strip-components=1 --exclude='*.md' --exclude=LICENSE && \
    rm "${node_tar}" && \
    npm install --prefix /opt/mermaid-cli "@mermaid-js/mermaid-cli@${MERMAID_CLI_VERSION}" && \
    npm cache clean --force && \
    mkdir -p /etc/mermaid && \
    printf '{"executablePath": "/usr/bin/chromium", "args": ["--no-sandbox", "--disable-gpu"]}\n' > /etc/mermaid/puppeteer.json && \
    printf '%s\n' \
        '#!/bin/sh' \
        '# mermaid.sty runs mmdc in the cwd but writes the .mmd into --output-directory (e.g. rtex)' \
        '[ -n "$TEXMF_OUTPUT_DIRECTORY" ] && cd "$TEXMF_OUTPUT_DIRECTORY"' \
        'exec /opt/mermaid-cli/node_modules/.bin/mmdc -p /etc/mermaid/puppeteer.json "$@"' \
        > /usr/local/bin/mmdc && \
    chmod +x /usr/local/bin/mmdc && \
    printf 'graph LR\n  A --> B\n' > /tmp/check.mmd && \
    mmdc -i /tmp/check.mmd -o /tmp/check.pdf && \
    rm /tmp/check.mmd /tmp/check.pdf

# Both packages call external tools, so latexmk runs every engine with -shell-escape.
# mermaid.sty re-renders on every run and Chromium stamps the PDF with the current time;
# ignore those lines so latexmk doesn't rerun until "too many passes".
RUN printf '%s\n' \
        "set_tex_cmds('-shell-escape %O %S');" \
        "\$hash_calc_ignore_pattern{'pdf'} = '^/(CreationDate|ModDate) \\(D:';" \
        > /etc/LatexMk

RUN command -v latexmk && latexmk -v

# The installer always fetches the current TeX Live; fail once it moves to a new year so
# TEXLIVE_VERSION (here and in docker-bake.hcl, which puts it in the image tag) gets bumped
ARG TEXLIVE_VERSION=2026
RUN test -d "/usr/local/texlive/${TEXLIVE_VERSION}" || \
    { echo "Expected TeX Live ${TEXLIVE_VERSION}, found: $(ls /usr/local/texlive)" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Dev container: base + rtex (realtime-tex) + non-root user
# Build with: docker build --target dev .
# ---------------------------------------------------------------------------
FROM base AS dev

# Fork release with a fix for blank pages (empty fonts table); switch back to
# HenryXiaoYang/realtime-tex once upstream releases it
ARG RTEX_REPO=Steve-Li-1998/realtime-tex
ARG RTEX_VERSION=v0.0.4.0.1
# Fork release with a fix for jumping from the preview to files no editor has open;
# switch back to HenryXiaoYang/realtime-tex-vsc-plugin once upstream releases it
ARG RTEX_VSIX_REPO=Steve-Li-1998/realtime-tex-vsc-plugin
ARG RTEX_VSIX_VERSION=0.0.1-fix-jump
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

# Stable TeX Live bin path, independent of year and architecture
RUN ln -s "$(dirname "$(readlink -f "$(command -v lualatex)")")" /usr/local/texlive/bin-current
ENV RTEX_TEXLIVE_BIN=/usr/local/texlive/bin-current

# rtex engine (prebuilt release) and the VS Code extension (.vsix)
RUN case "$(dpkg --print-architecture)" in \
        amd64) triple=x86_64-unknown-linux-gnu ;; \
        arm64) triple=aarch64-unknown-linux-gnu ;; \
        *) echo "unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac && \
    mkdir -p /tmp/rtex /opt/rtex && cd /tmp/rtex && \
    base_url="https://github.com/${RTEX_REPO}/releases/download/${RTEX_VERSION}" && \
    curl -fsSLO "${base_url}/rtex-${triple}.tar.gz" && \
    curl -fsSLO "${base_url}/rtex-${triple}.tar.gz.sha256" && \
    sha256sum -c "rtex-${triple}.tar.gz.sha256" && \
    tar -xzf "rtex-${triple}.tar.gz" -C /opt/rtex --strip-components=1 && \
    vsix_url="https://github.com/${RTEX_VSIX_REPO}/releases/download/v${RTEX_VSIX_VERSION}" && \
    curl -fsSLO "${vsix_url}/realtime-tex-${RTEX_VSIX_VERSION}.vsix" && \
    curl -fsSLO "${vsix_url}/realtime-tex-${RTEX_VSIX_VERSION}.vsix.sha256" && \
    sha256sum -c "realtime-tex-${RTEX_VSIX_VERSION}.vsix.sha256" && \
    mv "realtime-tex-${RTEX_VSIX_VERSION}.vsix" /opt/rtex/realtime-tex.vsix && \
    ln -s /opt/rtex/bin/rtex /usr/local/bin/rtex && \
    cd / && rm -rf /tmp/rtex && \
    rtex doctor

# Non-root user with passwordless sudo
RUN apt-get update && \
    apt-get install -y sudo && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd --gid "${USER_GID}" "${USERNAME}" && \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}" && \
    echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" && \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"

USER ${USERNAME}

# ---------------------------------------------------------------------------
# CI image (default target, so a plain `docker build .` is unchanged)
# ---------------------------------------------------------------------------
FROM base AS ci
