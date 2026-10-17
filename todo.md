# Dockerfile 改进 TODO

## 主要问题

- [x] **单独一层的清理不会让镜像变小**：`RUN rm -rf /install-tl` 是单独一层，安装器仍留在前面的层里。下载、安装、删除要合并到同一个 `RUN`。
- [x] **不安装文档和源码**：在 profile 中加入以下两行，预计可省 3–4 GB：
  ```
  tlpdbopt_install_docfiles 0
  tlpdbopt_install_srcfiles 0
  ```
- [x] **PATH 写死了年份和架构**：`ENV PATH="/usr/local/texlive/2026/bin/x86_64-linux:..."` 在 TeX Live 2027 发布后，或在 ARM（`aarch64-linux`）上会失效。
  - 在 profile 中加入 `instopt_adjustpath 1`，让安装器在 `/usr/local/bin` 建软链接（不加的话，现在的 `tlpdbopt_sys_bin` 不起作用），然后删掉 `ENV PATH`。
- [x] **精简 apt 依赖**
  - 加上 `--no-install-recommends`（`inkscape` 会拖进来大量推荐包）
  - 去掉用不到的 `build-essential`、`make`、`git`、`curl`（如果 CI 需要 `git`/`make` 就保留）
  - 设置 `ARG DEBIAN_FRONTEND=noninteractive`

## 次要问题

- [ ] Pygments 改用 apt 安装 `python3-pygments`，不再需要 pip 和 `--break-system-packages`
- [ ] 镜像地址改成 https，并用 `ARG TL_MIRROR` 支持指定固定镜像（`-repository`），避免 `mirror.ctan.org` 随机跳转导致安装中途失败
- [ ] 设置 `LANG=C.UTF-8` / `LC_ALL=C.UTF-8`，避免 minted 和 Python 遇到编码问题
- [ ] 把两次 `apt-get update` 合并成一层，放在前面
- [ ] 统一注释语言；删除第 46–47 行注释掉的验证（最后一行已经验证过）
- [ ] 可选：基础镜像改用 `debian:bookworm-slim`

## 参考改写

```dockerfile
FROM debian:bookworm-slim

LABEL maintainer="Hao LI <hao3.li@tu-dortmund.de>"
LABEL description="TeX Live full with Python 3 and Pygments for LaTeX minted support"

ARG TL_MIRROR=https://mirror.ctan.org/systems/texlive/tlnet

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# System dependencies
RUN apt-get update && \
    apt-get install -y \
        ca-certificates wget curl perl fontconfig xz-utils \
        git make build-essential \
        python3 python3-pygments inkscape && \
    rm -rf /var/lib/apt/lists/*

# Download, install and clean up TeX Live in a single layer
RUN mkdir /tmp/install-tl && cd /tmp/install-tl && \
    wget -qO- "${TL_MIRROR}/install-tl-unx.tar.gz" | tar -xz --strip-components=1 && \
    printf '%s\n' \
        'selected_scheme scheme-full' \
        'instopt_adjustpath 1' \
        'tlpdbopt_sys_bin /usr/local/bin' \
        'tlpdbopt_sys_man /usr/local/share/man' \
        'tlpdbopt_sys_info /usr/local/share/info' \
        > texlive.profile && \
    ./install-tl -no-interaction -profile texlive.profile -repository "${TL_MIRROR}" && \
    cd / && rm -rf /tmp/install-tl

RUN latexmk -v && pygmentize -V
```

固定镜像示例（德国）：`--build-arg TL_MIRROR=https://ftp.fau.de/ctan/systems/texlive/tlnet`
