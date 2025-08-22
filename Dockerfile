ARG BASE_IMAGE_NAME=oraclelinux
ARG BASE_IMAGE_TAG=9
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS base

LABEL \
    maintainer="Truong Thanh Tung <ttungbmt@gmail.com>" \
    usage="docker run -it --rm gtelots/ws-oracle-linux:${VERSION}" \
    summary="Oracle Linux 9 development container with modern tooling" \
    org.opencontainers.image.title="Oracle Linux 9 DevOps Base" \
    org.opencontainers.image.description="A comprehensive, production-ready development environment built on Oracle Linux 9 with modern tooling, beautiful UI, and optimized architecture" \
    org.opencontainers.image.vendor="GTEL OTS" \
    org.opencontainers.image.authors="Truong Thanh Tung <ttungbmt@gmail.com>" \
    org.opencontainers.image.maintainer="Truong Thanh Tung <ttungbmt@gmail.com>, Ho Manh Cuong <homanhcuongit@gmail.com>" \
    org.opencontainers.image.licenses="MIT" 

# -----------------------------
COPY resources/prebuildfs /
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color

# -----------------------------
ARG TZ=UTC
ENV TZ=${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#--------------------------------------------------------------------------
# User Setup
#--------------------------------------------------------------------------

ARG USER_UID=1000 \
    USER_GID=1000 \
    USER_NAME=dev \
    ROOT_PASSWORD=root \
    USER_PASSWORD=dev \
    WORKSPACE_DIR=/workspace \
    DATA_DIR=/data

ENV USER_UID ${PUID} \
    USER_GID=${PGID} \
    USER_NAME=${USER_NAME} \
    WORKSPACE_DIR=${WORKSPACE_DIR} \
    HOME_DIR=/home/${USER_NAME} \
    DATA_DIR=${DATA_DIR}

# Setup non-root user
RUN pkg-install sudo


# -----------------------------
# OS core & repository setup
RUN dnf -y update-minimal --security --setopt=install_weak_deps=False || true; \
    pkg-install oracle-epel-release-el9 || dnf -y config-manager --enable ol9_developer_EPEL; 

# Core packages
RUN set -eu; \
  pkg-install ca-certificates tzdata shadow-utils

# Essential packages
RUN set -eu; \
  pkg-install \
    curl wget openssl bind-utils iproute iputils tar gzip bzip2 xz unzip zip procps-ng util-linux findutils which diffutils less

# Dev packages
RUN set -eu; \
  pkg-install \
    gcc gcc-c++ make cmake ninja-build pkgconf-pkg-config autoconf automake libtool patch \
    openssl-devel zlib-devel libffi-devel readline-devel bzip2-devel xz-devel \
    libxml2-devel libxslt-devel libcurl-devel sqlite-devel \
    python3 python3-pip python3-devel git \
    crontab supervisor

# Modern packages
RUN set -eu; \
  pkg-install \
    ripgrep fd-find fzf bat eza zoxide jq yq htop tree && \
    { command -v bat >/dev/null && ! command -v batcat >/dev/null && ln -s "$(command -v bat)" /usr/local/bin/batcat || true; } && \
    { command -v fdfind >/dev/null && ! command -v fd >/dev/null && ln -s "$(command -v fdfind)" /usr/local/bin/fd || true; }

# -----------------------------
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN set -eu; \
    pkg-install glibc-langpack-en glibc-langpack-vi

# -----------------------------

# - ansible
# - aws-cli
# - github-cli
# - cloudflare-cli
# - dbeaver
# - docker
# - dry / lazydocker
# - gotemplate
# - gum
# - lazygit
# - thefuck / tldr / zoxide / webdriver / 
# - neovim
# - ngox
# - starship
# - tailscale
# - task
# - teleport
# - volta
# - wp-cli
# - zellij
# - python3.11
# - kubectl
# - helm
# - k9s
# - mise

# -----------------------------

COPY resources/rootfs /
RUN chmod g+rwX /opt/bitnami

RUN /opt/laragis/scripts/workspace/postunpack.sh

#--------------------------------------------------------------------------
# Final Touch
#--------------------------------------------------------------------------

USER ${USER_NAME}
WORKDIR ${WORKSPACE_DIR}


EXPOSE 2222

ENTRYPOINT [ "/opt/laragis/scripts/workspace/entrypoint.sh" ]
CMD [ "/opt/laragis/scripts/workspace/run.sh" ]
