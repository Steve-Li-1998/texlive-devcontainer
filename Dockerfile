FROM debian:bookworm

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

# Set up the path for texlive
ENV PATH="/usr/local/texlive/2026/bin/x86_64-linux:${PATH}"

RUN command -v latexmk && latexmk -v
