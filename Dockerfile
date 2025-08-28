# syntax=docker/dockerfile:1.7-labs

# -----------------------------------------------------------------------------
# Base Image Configuration
# -----------------------------------------------------------------------------
ARG BASE_IMAGE_NAME=oraclelinux
ARG BASE_IMAGE_TAG=9
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS base

# --------------------------------------------------------------------------
# Container Metadata - OCI Compliant Labels
# --------------------------------------------------------------------------

LABEL \
    maintainer="Truong Thanh Tung <ttungbmt@gmail.com>" \
    usage="docker run -it --rm gtelots/ws-oracle-linux:${VERSION}" \
    summary="Oracle Linux 9 development container with modern tooling" \
    org.opencontainers.image.title="Oracle Linux 9 DevOps Base" \
    org.opencontainers.image.description="A comprehensive, production-ready development environment built on Oracle Linux 9 with modern tooling, beautiful UI, and optimized architecture" \
    org.opencontainers.image.vendor="GTEL OTS" \
    org.opencontainers.image.authors="Truong Thanh Tung <ttungbmt@gmail.com>" \
    org.opencontainers.image.maintainer="Truong Thanh Tung <ttungbmt@gmail.com>" \
    org.opencontainers.image.licenses="MIT" 

# -----------------------------------------------------------------------------
# Build Arguments - Container Configuration Parameters
# -----------------------------------------------------------------------------

ARG TZ=UTC

# User security configuration - following principle of least privilege
ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_NAME=dev
ARG ROOT_PASSWORD
ARG USER_PASSWORD
ARG USER_SHELL=/bin/bash

# Directory structure for organized workspace management
ARG WORKSPACE_DIR=/workspace
ARG DATA_DIR=/data

# -----------------------------------------------------------------------------
# Environment Variables - Runtime Configuration
# -----------------------------------------------------------------------------

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

ENV TZ=${TZ}

# User security configuration
ENV USER_UID=${USER_UID} \
    USER_GID=${USER_GID} \
    USER_NAME=${USER_NAME} \
    USER_SHELL=${USER_SHELL}

# Directory structure for organized workspace management
ENV WORKSPACE_DIR=${WORKSPACE_DIR}
ENV HOME_DIR=/home/${USER_NAME}
ENV DATA_DIR=${DATA_DIR}

# --------------------------------------------------------------------------
# 
# --------------------------------------------------------------------------
USER root

COPY --exclude=setup/** --exclude=tools/** --exclude=packages/** \
     resources/prebuildfs/ /

# Optional: Enable strict shell error handling for debugging
# Uncomment for stricter error handling during development builds
# SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

# --------------------------------------------------------------------------
# System Update + Repos + Core packages
# --------------------------------------------------------------------------

RUN --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    dnf -y update-minimal --security --setopt=install_weak_deps=False --refresh || true; \
    dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs dnf-plugins-core; \
    # Enable EPEL (prefer oracle-epel-release-el9; fallback to developer EPEL)
    (dnf -y install oracle-epel-release-el9 || dnf -y config-manager --enable ol9_developer_EPEL) && \
    # Core & Essential tooling
    dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
        ca-certificates tzdata shadow-utils passwd sudo systemd

ARG PYTHON_VERSION=3.12
ENV PYTHON_VERSION="${PYTHON_VERSION}"

RUN dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
      python3 python3-pip python3-setuptools python3-devel \
      python${PYTHON_VERSION} python${PYTHON_VERSION}-pip python${PYTHON_VERSION}-setuptools python${PYTHON_VERSION}-wheel python${PYTHON_VERSION}-devel && \
      pip${PYTHON_VERSION} install pipx

# --------------------------------------------------------------------------
# User Setup
# --------------------------------------------------------------------------

# Setup non-root user + sudo (wheel)
COPY resources/prebuildfs/opt/laragis/setup/setup-user.sh /opt/laragis/setup/setup-user.sh
RUN ROOT_PASSWORD="${ROOT_PASSWORD}" USER_PASSWORD="${USER_PASSWORD}" ./opt/laragis/setup/setup-user.sh

ENV PATH="/home/${USER_NAME}/.local/bin:${PATH}"

# --------------------------------------------------------------------------
# Locale Setup
# --------------------------------------------------------------------------
RUN dnf -y install glibc-langpack-en glibc-langpack-vi glibc-locale-source && \
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone


# Essential System Utilities Installation

# Development Tools & Libraries Installation

# Enhanced Development Tools Installation Script

# =============================================================================
# OPTIONAL DEVELOPMENT TOOLS INSTALLATION
# =============================================================================

# --------------------------------------------------------------------------
# Supervisor - Supervisor is a process control system
# Repo: https://github.com/Supervisor/supervisor
# --------------------------------------------------------------------------
ARG SUPERVISOR_VERSION=4.3.0

COPY resources/prebuildfs/opt/laragis/tools/supervisor.sh /opt/laragis/tools/supervisor.sh
RUN SUPERVISOR_VERSION="${SUPERVISOR_VERSION}" /opt/laragis/tools/supervisor.sh

# --------------------------------------------------------------------------
# ansible - Radically simple IT automation platform
# Repo: https://github.com/ansible/ansible
# --------------------------------------------------------------------------
ARG ANSIBLE_VERSION=11.9.0

COPY resources/prebuildfs/opt/laragis/tools/ansible.sh /opt/laragis/tools/ansible.sh
RUN ANSIBLE_VERSION="${ANSIBLE_VERSION}" /opt/laragis/tools/ansible.sh

# --------------------------------------------------------------------------
# k6 - A modern load testing tool, using Go and JavaScript
# Repo: https://github.com/grafana/k6
# --------------------------------------------------------------------------
ARG K6_VERSION=1.2.2

COPY resources/prebuildfs/opt/laragis/tools/k6.sh /opt/laragis/tools/k6.sh
RUN K6_VERSION="${K6_VERSION}" /opt/laragis/tools/k6.sh

# --------------------------------------------------------------------------
# Zellij - A terminal workspace with batteries included
# Repo: https://github.com/zellij-org/zellij
# --------------------------------------------------------------------------
ARG ZELLIJ_VERSION=0.43.1

COPY resources/prebuildfs/opt/laragis/tools/gum.sh /opt/laragis/tools/gum.sh
RUN ZELLIJ_VERSION="${ZELLIJ_VERSION}" /opt/laragis/tools/gum.sh

# --------------------------------------------------------------------------
# Gum - A tool for glamorous shell scripts
# Repo: https://github.com/charmbracelet/gum
# --------------------------------------------------------------------------
ARG GUM_VERSION=0.16.2

COPY resources/prebuildfs/opt/laragis/tools/gum.sh /opt/laragis/tools/gum.sh
RUN GUM_VERSION="${GUM_VERSION}" /opt/laragis/tools/gum.sh

# --------------------------------------------------------------------------
# getoptions - An elegant option/argument parser for shell scripts
# Repo: https://github.com/ko1nksm/getoptions
# --------------------------------------------------------------------------
ARG GETOPTIONS_VERSION=3.3.2

COPY resources/prebuildfs/opt/laragis/tools/getoptions.sh /opt/laragis/tools/getoptions.sh
RUN GETOPTIONS_VERSION="${GETOPTIONS_VERSION}" /opt/laragis/tools/getoptions.sh

# --------------------------------------------------------------------------
# awscli - Universal Command Line Interface for Amazon Web Services
# Repo: https://github.com/aws/aws-cli
# --------------------------------------------------------------------------
ARG AWS_CLI_VERSION=2.28.16

COPY resources/prebuildfs/opt/laragis/tools/aws-cli.sh /opt/laragis/tools/aws-cli.sh
RUN AWS_CLI_VERSION="${AWS_CLI_VERSION}" /opt/laragis/tools/aws-cli.sh

# --------------------------------------------------------------------------
# dry - A Docker manager for the terminal
# Repo: https://github.com/moncho/dry
# --------------------------------------------------------------------------
ARG DRY_VERSION=0.11.2

COPY resources/prebuildfs/opt/laragis/tools/dry.sh /opt/laragis/tools/dry.sh
RUN DRY_VERSION="${DRY_VERSION}" /opt/laragis/tools/dry.sh

# --------------------------------------------------------------------------
# lazydocker - The lazier way to manage everything docker
# Repo: https://github.com/jesseduffield/lazydocker
# --------------------------------------------------------------------------
ARG LAZYDOCKER_VERSION=0.24.1

COPY resources/prebuildfs/opt/laragis/tools/lazydocker.sh /opt/laragis/tools/lazydocker.sh
RUN LAZYDOCKER_VERSION="${LAZYDOCKER_VERSION}" /opt/laragis/tools/lazydocker.sh

# --------------------------------------------------------------------------
# Github Cli - GitHub’s official command line tool
# Repo: https://github.com/cli/cli
# --------------------------------------------------------------------------
ARG GITHUB_CLI_VERSION=2.78.0
ARG GH_TOKEN
ENV GH_TOKEN=${GH_TOKEN}

COPY resources/prebuildfs/opt/laragis/tools/github-cli.sh /opt/laragis/tools/github-cli.sh
RUN GITHUB_CLI_VERSION="${GITHUB_CLI_VERSION}" /opt/laragis/tools/github-cli.sh

# --------------------------------------------------------------------------
# cloudflared - Cloudflare Tunnel client (formerly Argo Tunnel)
# Repo: https://github.com/cloudflare/cloudflared
# --------------------------------------------------------------------------
ARG CLOUDFLARED_VERSION=2025.8.1

COPY resources/prebuildfs/opt/laragis/tools/cloudflared.sh /opt/laragis/tools/cloudflared.sh
RUN CLOUDFLARED_VERSION="${CLOUDFLARED_VERSION}" /opt/laragis/tools/cloudflared.sh

# --------------------------------------------------------------------------
# lazygit - simple terminal UI for git commands
# Repo: https://github.com/jesseduffield/lazygit
# --------------------------------------------------------------------------
ARG LAZYGIT_VERSION=0.54.2

COPY resources/prebuildfs/opt/laragis/tools/lazygit.sh /opt/laragis/tools/lazygit.sh
RUN LAZYGIT_VERSION="${LAZYGIT_VERSION}" /opt/laragis/tools/lazygit.sh

# --------------------------------------------------------------------------
# ngrox - front door—and the fastest way to put anything on the internet
# Repo: https://ngrok.com
# --------------------------------------------------------------------------
ARG NGROK_VERSION=3.26.0
ARG NGROK_AUTHTOKEN
ENV NGROK_AUTHTOKEN=${NGROK_AUTHTOKEN}

COPY resources/prebuildfs/opt/laragis/tools/ngrok.sh /opt/laragis/tools/ngrok.sh
RUN NGROK_VERSION="${NGROK_VERSION}" /opt/laragis/tools/ngrok.sh

# --------------------------------------------------------------------------
# starship - The minimal, blazing-fast, and infinitely customizable prompt for any shell!
# Repo: https://github.com/starship/starship
# --------------------------------------------------------------------------
ARG STARSHIP_VERSION=1.23.0

COPY resources/prebuildfs/opt/laragis/tools/starship.sh /opt/laragis/tools/starship.sh
RUN STARSHIP_VERSION="${STARSHIP_VERSION}" /opt/laragis/tools/starship.sh

# --------------------------------------------------------------------------
# tailscale - The easiest, most secure way to use WireGuard and 2FA.
# Repo: https://github.com/tailscale/tailscale
# --------------------------------------------------------------------------
ARG TAILSCALE_VERSION=1.86.2

COPY resources/prebuildfs/opt/laragis/tools/tailscale.sh /opt/laragis/tools/tailscale.sh
RUN TAILSCALE_VERSION="${TAILSCALE_VERSION}" /opt/laragis/tools/tailscale.sh

# --------------------------------------------------------------------------
# task - A task runner / simpler Make alternative written in Go
# Repo: https://github.com/go-task/task
# --------------------------------------------------------------------------
ARG TASK_VERSION=3.44.1

COPY resources/prebuildfs/opt/laragis/tools/task.sh /opt/laragis/tools/task.sh
RUN TASK_VERSION="${TASK_VERSION}" /opt/laragis/tools/task.sh

# --------------------------------------------------------------------------
# Terraform - A tool for building, changing, and versioning infrastructure safely and efficiently
# Repo: https://github.com/hashicorp/terraform
# --------------------------------------------------------------------------
ARG TERRAFORM_VERSION=1.13.0

COPY resources/prebuildfs/opt/laragis/tools/terraform.sh /opt/laragis/tools/terraform.sh
RUN TERRAFORM_VERSION="${TERRAFORM_VERSION}" /opt/laragis/tools/terraform.sh

# --------------------------------------------------------------------------
# Teleport - The easiest, and most secure way to access and protect all of your infrastructure.
# Repo: https://github.com/gravitational/teleport
# --------------------------------------------------------------------------
ARG TELEPORT_VERSION=18.1.6

COPY resources/prebuildfs/opt/laragis/tools/teleport.sh /opt/laragis/tools/teleport.sh
RUN TELEPORT_VERSION="${TELEPORT_VERSION}" /opt/laragis/tools/teleport.sh

# --------------------------------------------------------------------------
# kubectl - Kubernetes command-line tool
# Repo: https://github.com/kubernetes/kubernetes
# --------------------------------------------------------------------------
ARG KUBECTL_VERSION=1.31.12

COPY resources/prebuildfs/opt/laragis/tools/kubectl.sh /opt/laragis/tools/kubectl.sh
RUN KUBECTL_VERSION="${KUBECTL_VERSION}" /opt/laragis/tools/kubectl.sh

# --------------------------------------------------------------------------
# helm - The Kubernetes Package Manager
# Repo: https://github.com/helm/helm
# --------------------------------------------------------------------------
ARG HELM_VERSION=3.18.6

COPY resources/prebuildfs/opt/laragis/tools/helm.sh /opt/laragis/tools/helm.sh
RUN HELM_VERSION="${HELM_VERSION}" /opt/laragis/tools/helm.sh

# --------------------------------------------------------------------------
# k9s - Kubernetes CLI To Manage Your Clusters In Style
# Repo: https://github.com/derailed/k9s
# --------------------------------------------------------------------------
ARG K9S_VERSION=0.50.9

COPY resources/prebuildfs/opt/laragis/tools/k9s.sh /opt/laragis/tools/k9s.sh
RUN K9S_VERSION="${K9S_VERSION}" /opt/laragis/tools/k9s.sh

# --------------------------------------------------------------------------
# gomplate - A flexible commandline tool for template rendering
# Repo: https://github.com/hairyhenderson/gomplate
# --------------------------------------------------------------------------
ARG GOMPLATE_VERSION=4.3.3

COPY resources/prebuildfs/opt/laragis/tools/gomplate.sh /opt/laragis/tools/gomplate.sh
RUN GOMPLATE_VERSION="${GOMPLATE_VERSION}" /opt/laragis/tools/gomplate.sh

# --------------------------------------------------------------------------
# dbeaver - DBeaver Community universal database tool
# Repo: https://github.com/dbeaver/dbeaver
# --------------------------------------------------------------------------
ARG DBEAVER_VERSION=25.1.5

COPY resources/prebuildfs/opt/laragis/tools/dbeaver.sh /opt/laragis/tools/dbeaver.sh
RUN DBEAVER_VERSION="${DBEAVER_VERSION}" /opt/laragis/tools/dbeaver.sh

# --------------------------------------------------------------------------
# mise - dev tools, env vars, task runner
# Repo: https://github.com/jdx/mise
# --------------------------------------------------------------------------
ARG MISE_VERSION=2025.8.20

COPY resources/prebuildfs/opt/laragis/tools/mise.sh /opt/laragis/tools/mise.sh
RUN MISE_VERSION="${MISE_VERSION}" /opt/laragis/tools/mise.sh

# --------------------------------------------------------------------------
# uv - An extremely fast Python package and project manager, written in Rust.
# Repo: https://github.com/astral-sh/uv
# --------------------------------------------------------------------------
ARG UV_VERSION=0.8.13

COPY resources/prebuildfs/opt/laragis/tools/uv.sh /opt/laragis/tools/uv.sh
RUN UV_VERSION="${UV_VERSION}" /opt/laragis/tools/uv.sh

# --------------------------------------------------------------------------
# volta - The Hassle-Free JavaScript Tool Manager
# Repo: https://github.com/volta-cli/volta
# --------------------------------------------------------------------------
ARG VOLTA_VERSION=2.0.2

COPY resources/prebuildfs/opt/laragis/tools/wp-cli.sh /opt/laragis/tools/wp-cli.sh
RUN VOLTA_VERSION="${VOLTA_VERSION}" /opt/laragis/tools/wp-cli.sh

# --------------------------------------------------------------------------
# wp-cli - WP-CLI is the command-line interface for WordPress
# Repo: https://github.com/wp-cli/wp-cli
# --------------------------------------------------------------------------
ARG WP_CLI_VERSION=2.12.0

COPY resources/prebuildfs/opt/laragis/tools/wp-cli.sh /opt/laragis/tools/wp-cli.sh
RUN WP_CLI_VERSION="${WP_CLI_VERSION}" /opt/laragis/tools/wp-cli.sh

# --------------------------------------------------------------------------
# docker - A platform for developing, shipping, and running applications
# Repo: https://github.com/docker/cli
# --------------------------------------------------------------------------
ARG DOCKER_VERSION=28.3.2

COPY resources/prebuildfs/opt/laragis/tools/docker.sh /opt/laragis/tools/docker.sh
RUN DOCKER_VERSION="${DOCKER_VERSION}" /opt/laragis/tools/docker.sh

# --------------------------------------------------------------------------
# Language Runtimes 
# --------------------------------------------------------------------------


# --------------------------------------------------------------------------
# 
# --------------------------------------------------------------------------

COPY resources/ca-certificates/* /usr/local/share/ca-certificates/
RUN update-ca-trust

# --------------------------------------------------------------------------
# 
# --------------------------------------------------------------------------

COPY resources/.ssh ${HOME_DIR}/.ssh

# --------------------------------------------------------------------------
# 
# --------------------------------------------------------------------------

COPY resources/rootfs /

RUN /opt/laragis/scripts/workspace/postunpack.sh

#--------------------------------------------------------------------------
# Final System Configuration and Cleanup
#--------------------------------------------------------------------------

# Create and configure workspace directory with proper ownership
RUN mkdir -p "${WORKSPACE_DIR}" "${DATA_DIR}" && \
    chown "${USER_UID}:${USER_GID}" "${WORKSPACE_DIR}" "${DATA_DIR}" && \
    chmod 755 "${WORKSPACE_DIR}" "${DATA_DIR}"


# Comprehensive final cleanup to minimize image size
# Remove package caches, temporary files, documentation, and other artifacts
RUN dnf clean all && rm -rf /var/cache/dnf/* /root/.cache/* /tmp/*

# -----------------------------------------------------------------------------
# Network Port Configuration
# -----------------------------------------------------------------------------
# Expose ports for services that may run within the container:
# - 2222: SSH service (non-standard port for security)
# - 9001: Supervisor web interface for process management
# - 80: HTTP service for web applications
# - 443: HTTPS service for secure web applications
EXPOSE 2222 9001 80 443

# -----------------------------------------------------------------------------
# Container Runtime Configuration
# -----------------------------------------------------------------------------
# Configure the container's runtime behavior including working directory,
# user context, and startup commands for optimal security and functionality.

# Set working directory for container operations
# This provides a consistent starting point for interactive sessions
WORKDIR ${WORKSPACE_DIR}


# Switch to non-root user for security best practices
# All application processes will run under this unprivileged user account
USER ${USER_NAME}

ENTRYPOINT [ "/opt/laragis/scripts/workspace/entrypoint.sh" ]
CMD [ "/opt/laragis/scripts/workspace/run.sh" ]

# =============================================================================
# BUILD COMPLETE - Oracle Linux 9 Development Container
# =============================================================================
# This container provides a comprehensive development environment with:
# ✓ Security-hardened configuration with non-root user
# ✓ Comprehensive development tools and runtimes
# ✓ SSH server with security best practices
# ✓ Process management via Supervisor
# ✓ Flexible tool installation via build arguments
# ✓ Optimized build process with layer caching
# ✓ Extensive documentation and configuration options
#
# Usage Examples:
#   docker run -it --rm -p 2222:2222 -p 9001:9001 ws-oracle-linux
#   docker run -d -p 2222:2222 --name dev-container ws-oracle-linux
#   ssh -p 2222 dev@localhost  # After configuring SSH keys
# =============================================================================