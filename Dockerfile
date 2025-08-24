# syntax=docker/dockerfile:1.7-labs
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
ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color
USER root

ARG TZ=UTC

ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_NAME=dev
ARG ROOT_PASSWORD=root
ARG USER_PASSWORD=dev
ARG USER_SHELL=/bin/bash
ARG WORKSPACE_DIR=/workspace
ARG DATA_DIR=/data

ARG INSTALL_GUM=true
ARG INSTALL_ZELLIJ=true
ARG INSTALL_K8S=true
ARG INSTALL_ANSIBLE=true
ARG INSTALL_PYTHON=true
ARG INSTALL_VOLTA=true
ARG INSTALL_TASK=true
ARG INSTALL_LAZYDOCKER=true
ARG INSTALL_LAZYGIT=true
ARG INSTALL_OPENSSH_SERVER=true
ARG INSTALL_CRONTAB=true
ARG INSTALL_NGROK=true
ARG INSTALL_TAILSCALE=true
ARG INSTALL_TERRAFORM=true
ARG INSTALL_CLOUDFLARE=true
ARG INSTALL_TELEPORT=true
ARG INSTALL_DRY=true
ARG INSTALL_WP_CLI=true
ARG INSTALL_AWS_CLI=true
ARG AWS_CLI_VERSION=latest
ARG INSTALL_DOCKER=true
ARG INSTALL_SUPERVISOR=true
ARG INSTALL_DBEAVER=true

ARG GUM_VERSION=0.16.2
ARG STARSHIP_VERSION=1.17.1
ARG ZELLIJ_VERSION=0.43.1
ARG GOMPLATE_VERSION=v4.3.3
ARG K8S_VERSION=1.31.12
ARG HELM_VERSION=3.18.5
ARG K9S_VERSION=0.50.9
# ARG ANSIBLE_VERSION=
ARG PYTHON_VERSION=3.11
# ARG VOLTA_VERSION=
ARG TASK_VERSION=3.44.1
ARG LAZYDOCKER_VERSION=0.24.1
ARG LAZYGIT_VERSION=0.54.2
ARG YQ_VERSION=4.47.1
# ARG OPENSSH_SERVER_VERSION=
# ARG CRONTAB_VERSION=
ARG NGROK_VERSION=3.26.0
ARG TAILSCALE_VERSION=1.86.4
ARG TERRAFORM_VERSION=1.12.2
ARG CLOUDFLARE_VERSION=2025.8.0
ARG TELEPORT_VERSION=18.1.5
ARG DRY_VERSION=0.11.2
ARG WP_CLI_VERSION=2.12.0
ARG DOCKER_VERSION=28.3.2
# ARG SUPERVISOR_VERSION=
ARG DBEAVER_VERSION=25.1.5	

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

ENV TZ=${TZ}

ENV USER_UID=${USER_UID}
ENV USER_GID=${USER_GID}
ENV USER_NAME=${USER_NAME}
ENV WORKSPACE_DIR=${WORKSPACE_DIR}
ENV HOME_DIR=/home/${USER_NAME}
ENV DATA_DIR=${DATA_DIR}

# AWS CLI Configuration
ENV INSTALL_AWS_CLI=${INSTALL_AWS_CLI}
ENV AWS_CLI_VERSION=${AWS_CLI_VERSION}

COPY --exclude=**/setup --exclude=**/tools resources/prebuildfs/ /

SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

RUN log install-deps && log --version

# --------------------------------------------------------------------------
# User Setup
# --------------------------------------------------------------------------

# Setup non-root user + sudo (wheel)
COPY resources/prebuildfs/opt/laragis/common/setup/setup-user.sh /opt/laragis/common/setup/setup-user.sh
RUN ./opt/laragis/common/setup/setup-user.sh ${ROOT_PASSWORD} ${USER_PASSWORD}

ENV PATH="/home/${USER_NAME}/.local/bin:${PATH}"

# -----------------------------
# Core System Packages Installation
COPY resources/prebuildfs/opt/laragis/common/tools/01-core-pkgs.sh /opt/laragis/common/tools/01-core-pkgs.sh
RUN /opt/laragis/common/tools/01-core-pkgs.sh

# Essential System Utilities Installation
COPY resources/prebuildfs/opt/laragis/common/tools/02-essential-pkgs.sh /opt/laragis/common/tools/02-essential-pkgs.sh
RUN /opt/laragis/common/tools/02-essential-pkgs.sh

# Development Tools & Libraries Installation
COPY resources/prebuildfs/opt/laragis/common/tools/03-dev-pkgs.sh /opt/laragis/common/tools/03-dev-pkgs.sh
RUN /opt/laragis/common/tools/03-dev-pkgs.sh

# # Enhanced Development Tools Installation Script
# COPY resources/prebuildfs/opt/laragis/common/tools/04-modern-pkgs.sh /opt/laragis/common/tools/04-modern-pkgs.sh
# # RUN /opt/laragis/common/tools/04-modern-pkgs.sh

# AWS CLI Installation
COPY resources/prebuildfs/opt/laragis/common/tools/aws-cli.sh /opt/laragis/common/tools/aws-cli.sh
RUN /opt/laragis/common/tools/aws-cli.sh

# -----------------------------
# Language Runtimes (Conditional Installation)

# Dev Tools
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

# # -----------------------------
# COPY ./ca-certificates/* /usr/local/share/ca-certificates/
# RUN update-ca-trust

# # -----------------------------
# COPY ./.ssh ${HOME_DIR}/.ssh

# -----------------------------

# COPY resources/rootfs /
# RUN chmod g+rwX /opt/bitnami

# RUN /opt/laragis/scripts/workspace/postunpack.sh

# #--------------------------------------------------------------------------
# # Final setup and cleanup
# #--------------------------------------------------------------------------
# RUN mkdir -p ${WORKSPACE_DIR} && chown ${USER_UID}:${USER_GID} ${WORKSPACE_DIR}

# # RUN dnf clean all && rm -rf /var/cache/dnf/* /root/.cache/* /tmp/*

# EXPOSE 2222

# #--------------------------------------------------------------------------
# # Container startup configuration
# #--------------------------------------------------------------------------
# WORKDIR ${WORKSPACE_DIR}

# USER ${USER_NAME}

# ENTRYPOINT [ "/opt/laragis/scripts/workspace/entrypoint.sh" ]
# CMD [ "/opt/laragis/scripts/workspace/run.sh" ]
