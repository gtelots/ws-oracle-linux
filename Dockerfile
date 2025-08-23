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
ARG LANG_PACKS="glibc-langpack-en glibc-langpack-vi"


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

COPY resources/prebuildfs /
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

#--------------------------------------------------------------------------
# User Setup
#--------------------------------------------------------------------------

# Setup non-root user + sudo (wheel)
RUN set -eu; \
  # --- Guards: require these vars; set sane defaults ---
  : "${USER_NAME:?}"; : "${USER_UID:?}"; : "${USER_GID:?}"; \
  : "${USER_SHELL:=/bin/bash}"; : "${HOME_DIR:=/home/${USER_NAME}}"; \
  \
  # --- Packages required for user/group management and sudo ---
  pkg-install sudo shadow-utils; \
  # --- Ensure primary group exists: reuse by name or GID; create if missing ---
  { getent group "${USER_NAME}" || getent group "${USER_GID}"; } >/dev/null 2>&1 || \
    groupadd -g "${USER_GID}" "${USER_NAME}"; \
  # --- Ensure wheel group exists (shared sudo policy for multiple dev users) ---
  getent group wheel >/dev/null 2>&1 || groupadd wheel; \
  # --- Ensure user exists; add to wheel; idempotent ---
  id -u "${USER_NAME}" >/dev/null 2>&1 || \
    useradd -u "${USER_UID}" -g "${USER_GID}" -G wheel -m -s "${USER_SHELL}" "${USER_NAME}"; \
  # --- Set passwords: prefer BuildKit secrets, fallback to ARGs; lock if empty ---
  ROOT_PW="$( [ -f /run/secrets/root_pw ] && cat /run/secrets/root_pw || echo "${ROOT_PASSWORD:-}" )"; \
  USER_PW="$( [ -f /run/secrets/user_pw ] && cat /run/secrets/user_pw || echo "${USER_PASSWORD:-}" )"; \
  if [ -n "$ROOT_PW" ]; then case "$ROOT_PW" in \$*) echo "root:$ROOT_PW" | chpasswd -e ;; *) echo "root:$ROOT_PW" | chpasswd ;; esac; \
  else passwd -l root || true; fi; \
  if [ -n "$USER_PW" ]; then case "$USER_PW" in \$*) echo "${USER_NAME}:$USER_PW" | chpasswd -e ;; *) echo "${USER_NAME}:$USER_PW" | chpasswd ;; esac; \
  else passwd -l "${USER_NAME}" || true; fi; \
  # --- Sudo configuration via sudoers.d (safer than editing /etc/sudoers directly) ---
  install -d -m 0755 /etc/sudoers.d; \
  : > /etc/sudoers.d/00-defaults; \
  echo 'Defaults !requiretty' >> /etc/sudoers.d/00-defaults; \
  echo 'Defaults env_reset' >> /etc/sudoers.d/00-defaults; \
  echo 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> /etc/sudoers.d/00-defaults; \
  chmod 0440 /etc/sudoers.d/00-defaults; \
  # Choose ONE policy:
  # Safer (password required):  echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/99-wheel; \
  printf '%%wheel ALL=(ALL:ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/99-wheel; \
  chmod 0440 /etc/sudoers.d/99-wheel; \
  # Ensure /etc/sudoers includes sudoers.d (if the distro file lacks it)
  grep -q '^#includedir /etc/sudoers.d' /etc/sudoers || echo '#includedir /etc/sudoers.d' >> /etc/sudoers; \
  # Validate the complete sudoers configuration (includes) when visudo is available
  ! command -v visudo >/dev/null || visudo -cf /etc/sudoers || exit 1; \
  # --- Prepare HOME ownership and basic dirs ---
  mkdir -p "${HOME_DIR}"/{.ssh,.local/bin,.config,.cache}; \
  chown -R "${USER_UID}:${USER_GID}" "${HOME_DIR}"; \
  chmod 700 "${HOME_DIR}/.ssh"

ENV PATH="/home/${USER_NAME}/.local/bin:${PATH}"

# # -----------------------------
# # OS core & repository setup
# RUN --mount=type=cache,target=/var/cache/dnf \
# 		set -eu; \
#     dnf -y update-minimal --security --setopt=install_weak_deps=False || true; \
#     pkg-install oracle-epel-release-el9 || dnf -y config-manager --enable ol9_developer_EPEL; 

# # Core packages
# RUN set -eu; \
#   pkg-install ca-certificates tzdata shadow-utils

# # Essential packages
# RUN set -eu; \
#   pkg-install \
#     curl wget openssl bind-utils iproute iputils tar gzip bzip2 xz unzip zip procps-ng util-linux findutils which diffutils less

# # Dev packages
# RUN set -eu; \
#   pkg-install \
#     gcc gcc-c++ make cmake ninja-build pkgconf-pkg-config autoconf automake libtool patch \
#     openssl-devel zlib-devel libffi-devel readline-devel bzip2-devel xz-devel \
#     libxml2-devel libxslt-devel libcurl-devel sqlite-devel \
#     python3 python3-pip python3-devel git \
#     crontab supervisor

# # Enhanced Development Tools (Optional but Recommended)
# RUN set -eu; \
#   pkg-install \
#     ripgrep fd-find fzf bat eza zoxide jq yq htop tree && \
#     { command -v bat >/dev/null && ! command -v batcat >/dev/null && ln -s "$(command -v bat)" /usr/local/bin/batcat || true; } && \
#     { command -v fdfind >/dev/null && ! command -v fd >/dev/null && ln -s "$(command -v fdfind)" /usr/local/bin/fd || true; }

# # -----------------------------

# RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# # -----------------------------

# RUN set -eu; \
#     pkg-install ${LANG_PACKS}

# # -----------------------------
# COPY ./ca-certificates/* /usr/local/share/ca-certificates/
# RUN update-ca-trust

# # -----------------------------
# COPY ./.ssh ${HOME_DIR}/.ssh

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

# -----------------------------

COPY resources/rootfs /
RUN chmod g+rwX /opt/bitnami

RUN /opt/laragis/scripts/workspace/postunpack.sh

#--------------------------------------------------------------------------
# Final setup and cleanup
#--------------------------------------------------------------------------
RUN mkdir -p ${WORKSPACE_DIR} && chown ${USER_UID}:${USER_GID} ${WORKSPACE_DIR}

RUN dnf clean all && rm -rf /var/cache/dnf/* /root/.cache/* /tmp/*

EXPOSE 2222

#--------------------------------------------------------------------------
# Container startup configuration
#--------------------------------------------------------------------------
WORKDIR ${WORKSPACE_DIR}

# USER ${USER_NAME}

ENTRYPOINT [ "/opt/laragis/scripts/workspace/entrypoint.sh" ]
CMD [ "/opt/laragis/scripts/workspace/run.sh" ]
