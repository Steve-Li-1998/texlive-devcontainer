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

RUN command -v latexmk && latexmk -v

# ---------------------------------------------------------------------------
# Dev container: base + rtex (realtime-tex) + non-root user
# Build with: docker build --target dev .
# ---------------------------------------------------------------------------
FROM base AS dev

ARG RTEX_VERSION=v0.0.4
ARG RTEX_VSIX_VERSION=0.0.1
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
    base_url="https://github.com/HenryXiaoYang/realtime-tex/releases/download/${RTEX_VERSION}" && \
    curl -fsSLO "${base_url}/rtex-${triple}.tar.gz" && \
    curl -fsSLO "${base_url}/rtex-${triple}.tar.gz.sha256" && \
    sha256sum -c "rtex-${triple}.tar.gz.sha256" && \
    tar -xzf "rtex-${triple}.tar.gz" -C /opt/rtex --strip-components=1 && \
    vsix_url="https://github.com/HenryXiaoYang/realtime-tex-vsc-plugin/releases/download/v${RTEX_VSIX_VERSION}" && \
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
