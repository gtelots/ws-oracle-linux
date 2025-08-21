# -----------------------------------------------------------------------------
# Dev Container: Oracle Linux 9 Development Environment
# -----------------------------------------------------------------------------
# Set the base image to use for the build
ARG ORACLE_LINUX_IMAGE=oraclelinux
ARG ORACLE_LINUX_VERSION=9
FROM ${ORACLE_LINUX_IMAGE}:${ORACLE_LINUX_VERSION} AS base

# -----------------------------------------------------------------------------
# Metadata (OCI labels)
# -----------------------------------------------------------------------------

LABEL \
    org.opencontainers.image.title="Oracle Linux 9 DevOps Base" \
    org.opencontainers.image.description="A comprehensive, production-ready development environment built on Oracle Linux 9 with modern tooling, beautiful UI, and optimized architecture" \
    org.opencontainers.image.vendor="GTEL OTS" \
    org.opencontainers.image.authors="Truong Thanh Tung <ttungbmt@gmail.com>" \
    org.opencontainers.image.maintainer="Truong Thanh Tung <ttungbmt@gmail.com>, Ho Manh Cuong <homanhcuongit@gmail.com>" \
    org.opencontainers.image.source="https://github.com/gtelots/ws-oracle-linux" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.base.name="docker.io/oraclelinux:9" \
    org.opencontainers.image.documentation="https://github.com/gtelots/ws-oracle-linux/README.md"

# -----------------------------------------------------------------------------
# Shell configuration for safer builds
# -----------------------------------------------------------------------------
# Set the shell for subsequent RUN instructions to bash with strict error handling
# - errexit: Exit immediately if any command exits with a non-zero status
# - nounset: Treat unset variables as an error when substituting
# - pipefail: Return exit status of the last command in the pipe that failed
# This ensures build failures are caught early and builds are more reliable
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

# -----------------------------------------------------------------------------
# System & User Configuration
# -----------------------------------------------------------------------------
ARG TZ=UTC
ARG ROOT_PASSWORD=root
ARG USERNAME=dev
ARG USER_PASSWORD=dev
ARG USER_UID=1000
ARG USER_GID=1000
ARG SSH_PORT=22

# -----------------------------------------------------------------------------
# Core Install Flags
# -----------------------------------------------------------------------------
ARG INSTALL_PYTHON=1
ARG INSTALL_OPENSSH_SERVER=1
ARG INSTALL_SUPERVISOR=1

# -----------------------------------------------------------------------------
# CLI Tools Install Flags
# -----------------------------------------------------------------------------
ARG INSTALL_GUM=1
ARG INSTALL_ZELLIJ=1
ARG INSTALL_TASK=1
ARG INSTALL_LAZYDOCKER=1
ARG INSTALL_LAZYGIT=1
ARG INSTALL_YQ=1

# -----------------------------------------------------------------------------
# Container & DevOps Tools Install Flags
# -----------------------------------------------------------------------------
ARG INSTALL_DOCKER=1
ARG INSTALL_DRY=1
ARG INSTALL_K8S=1
ARG INSTALL_ANSIBLE=1
ARG INSTALL_TERRAFORM=1
ARG INSTALL_CLOUDFLARE=1

# -----------------------------------------------------------------------------
# Development Tools Install Flags
# -----------------------------------------------------------------------------
ARG INSTALL_VOLTA=1
ARG INSTALL_R_LANGUAGE=0
ARG INSTALL_DBEAVER=0
ARG INSTALL_WP_CLI=1

# -----------------------------------------------------------------------------
# Optional Tools Install Flags
# -----------------------------------------------------------------------------
ARG INSTALL_GOMPLATE=0
ARG INSTALL_CRONTAB=1
ARG INSTALL_NGROK=0
ARG INSTALL_TAILSCALE=0
ARG INSTALL_TELEPORT=0

# -----------------------------------------------------------------------------
# CLI Tools Versions
# -----------------------------------------------------------------------------
ARG GUM_VERSION=0.16.2
ARG STARSHIP_VERSION=1.17.1
ARG ZINIT_VERSION=latest
ARG ZELLIJ_VERSION=0.43.1
ARG TASK_VERSION=3.44.1
ARG LAZYDOCKER_VERSION=0.24.1
ARG LAZYGIT_VERSION=0.54.2
ARG YQ_VERSION=4.47.1

# -----------------------------------------------------------------------------
# Container & DevOps Tools Versions
# -----------------------------------------------------------------------------
ARG DOCKER_VERSION=28.3.2
ARG DRY_VERSION=0.11.2
ARG KUBECTL_VERSION=1.31.12
ARG HELM_VERSION=3.18.5
ARG K9S_VERSION=0.50.9
ARG TERRAFORM_VERSION=1.12.2
ARG CLOUDFLARE_VERSION=2025.8.0

# -----------------------------------------------------------------------------
# Development Tools Versions
# -----------------------------------------------------------------------------
ARG R_VERSION=latest
ARG DBEAVER_VERSION=25.1.5
ARG WP_CLI_VERSION=2.12.0

# -----------------------------------------------------------------------------
# Optional Tools Versions
# -----------------------------------------------------------------------------
ARG GOMPLATE_VERSION=v4.3.3
ARG NGROK_VERSION=3.26.0
ARG TAILSCALE_VERSION=1.86.4
ARG TELEPORT_VERSION=18.1.5

# -----------------------------------------------------------------------------
# Certificate Authorities & System Setup
# -----------------------------------------------------------------------------
COPY ./ca-certificates/* /usr/local/share/ca-certificates/
RUN update-ca-trust

# Set locales & timezone
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=${TZ}

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# -----------------------------------------------------------------------------
# Create non-root user
# -----------------------------------------------------------------------------
USER root

# Use dedicated script for user setup (cleaner and maintainable)
# Copy both setup script and common functions
COPY scripts/common/ /usr/local/scripts/common/
COPY scripts/setup/setup-user.sh /usr/local/scripts/setup/

# Setup smart package installer for easy use
RUN chmod +x /usr/local/scripts/common/pkg-install.sh && \
    ln -sf /usr/local/scripts/common/pkg-install.sh /usr/local/bin/pkg-install

# Create environment shortcut for even easier use
# ENV PKG="pkg-install"

RUN chmod +x /usr/local/scripts/setup/setup-user.sh && \
    USERNAME=${USERNAME} \
    USER_UID=${USER_UID} \
    USER_GID=${USER_GID} \
    ROOT_PASSWORD=${ROOT_PASSWORD} \
    USER_PASSWORD=${USER_PASSWORD} \
    /usr/local/scripts/setup/setup-user.sh

# -----------------------------------------------------------------------------
# Base OS setup & essential packages
# Enhanced package installation using smart pkg-install tool
# -----------------------------------------------------------------------------
RUN set -euxo pipefail; \
    ##############################################################################
    # Stage 1: OS core & repository setup (critical foundation)
    ##############################################################################
    # Install core tooling first so security flags/plugins are available
    dnf -y install --setopt=install_weak_deps=False --nodocs \
            dnf-plugins-core ca-certificates tzdata; \
    # Initialize system CA trust (requires ca-certificates)
    update-ca-trust; \
    # Apply security-only updates (avoid full distribution upgrade)
    dnf -y update-minimal --security --setopt=install_weak_deps=False || true; \
    # Enable EPEL: prefer oracle-epel-release-el9; if unavailable, enable developer EPEL
    dnf -y install --setopt=install_weak_deps=False --nodocs oracle-epel-release-el9 \
			|| dnf -y config-manager --enable ol9_developer_EPEL; 
#     \
#     ##############################################################################
#     # Stage 2: Essential system packages
#     ##############################################################################
#     dnf -y install --setopt=install_weak_deps=False --nodocs \
# 			tar xz gzip bzip2 unzip zip \
# 			# Network utilities (essential for containers)
# 			curl wget rsync iproute iputils \ 
# 			# Locale support (English + Vietnamese)
# 			glibc-langpack-en glibc-langpack-vi; \
#     \
#     ##############################################################################
#     # Stage 3: Development essentials (install after EPEL is enabled)
#     ##############################################################################
#     dnf -y install --setopt=install_weak_deps=False --nodocs \
# 			# Security & cryptography
# 			gnupg2 openssl ca-certificates \
# 			# Version control & SSH
# 			git git-lfs openssh-clients \
# 			# Text processing & search tools
# 			grep sed gawk diffutils patch file less tree jq \
# 			# Network diagnostics & tools
# 			bind-utils net-tools traceroute nmap-ncat socat \
# 			# Process management & monitoring
# 			psmisc lsof htop \
# 			# Shell & editor environment
# 			vim nano bash-completion zsh man-pages \
# 			# C/C++ development toolchain
# 			gcc gcc-c++ make automake autoconf libtool pkgconf-pkg-config \
# 			# Modern build systems
# 			cmake \
# 			# Debugging tools (essential for development)
# 			gdb strace;
    
# # -----------------------------------------------------------------------------
# # Final cleanup to minimize image size
# # -----------------------------------------------------------------------------
# RUN dnf clean all; \
# 			rm -rf /var/cache/dnf/* /var/tmp/* /tmp/*;

# # Add user's local bin to PATH
# ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# Switch to non-root user for security
USER ${USERNAME}

CMD [ "bash", "-lc", "sleep infinity" ]