# syntax=docker/dockerfile:1.7-labs

# -----------------------------------------------------------------------------
# Base Image Configuration
# -----------------------------------------------------------------------------
# Oracle Linux 9 provides enterprise-grade stability, security updates,
# and compatibility with RHEL ecosystem while being freely available.
ARG BASE_IMAGE_NAME=oraclelinux
ARG BASE_IMAGE_TAG=9
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS base

# --------------------------------------------------------------------------
# Container Metadata - OCI Compliant Labels
# --------------------------------------------------------------------------
# These labels provide essential information about the container image
# for registry management, documentation, and automated tooling.
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
# These arguments control container behavior and can be customized during
# build time using --build-arg flags. They provide flexibility for different
# deployment scenarios while maintaining security best practices.

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
# These variables are available during both build and runtime, providing
# consistent configuration across the container lifecycle.

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

# =============================================================================
# SYSTEM FOUNDATION SETUP
# =============================================================================

# -----------------------------------------------------------------------------
# Initial System Configuration and File Preparation
# -----------------------------------------------------------------------------
# Switch to root for system-level operations and copy essential configuration
# files. We exclude heavy installation scripts to optimize build cache layers.
USER root

# Copy essential configuration files and libraries (excluding installation scripts)
# This selective copying improves build cache efficiency by separating stable
# configuration from frequently changing installation scripts.
COPY --exclude=setup/** --exclude=tools/** --exclude=packages/** \
     resources/prebuildfs/ /

# Optional: Enable strict shell error handling for debugging
# Uncomment for stricter error handling during development builds
# SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]


# -----------------------------------------------------------------------------
# Core System Foundation - Repositories, Updates, and Base Packages
# -----------------------------------------------------------------------------
ARG PYTHON_VERSION=3.12
ENV PYTHON_VERSION="${PYTHON_VERSION}"

RUN --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    set -euxo pipefail && \
    # Step 1: Configure repositories and apply security updates
    echo "==> Configuring repositories and applying security updates..." && \
    # Install DNF plugins first for enhanced repository management
    dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
        dnf-plugins-core && \
    # Enable EPEL repository (prefer Oracle's version, fallback to developer EPEL)
    echo "==> Enabling EPEL repository..." && \
    (dnf -y install oracle-epel-release-el9 || \
     dnf -y config-manager --enable ol9_developer_EPEL) && \
    # Apply security updates (non-fatal if no updates available)
    echo "==> Applying security updates..." && \
    dnf -y update-minimal --security \
        --setopt=install_weak_deps=False \
        --refresh || echo "No security updates available or update failed" && \
    # Step 2: Install core system packages in single transaction
    echo "==> Installing core system packages..." && \
    dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
        ca-certificates \
        tzdata \
        shadow-utils \
        passwd \
        sudo \
        systemd \
    # Step 3: Install Python runtime and development tools
    echo "==> Installing Python ${PYTHON_VERSION} runtime and tools..." && \
    dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
        python3 \
        python3-pip \
        python3-setuptools \
        python3-devel \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-pip \
        python${PYTHON_VERSION}-setuptools \
        python${PYTHON_VERSION}-wheel \
        python${PYTHON_VERSION}-devel && \
    # Install pipx for isolated Python tool installation
    echo "==> Installing pipx for isolated Python tools..." && \
    pip${PYTHON_VERSION} install pipx && \
    # Verify repository configuration
    echo "==> Verifying repository configuration..." && \
    dnf repolist enabled && \
    # Clean package manager cache to reduce layer size
    echo "==> Cleaning package manager cache..." && \
    dnf clean all

# --------------------------------------------------------------------------
# Locale Setup
# --------------------------------------------------------------------------
RUN dnf -y install glibc-langpack-en glibc-langpack-vi glibc-locale-source && \
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

# -----------------------------------------------------------------------------
# User Management and Security Configuration
# -----------------------------------------------------------------------------
# Create a non-root user with sudo privileges following security best practices.
# This prevents running applications as root and provides proper access control.
#
# The user setup process handles:
# - Creating user and group with specified UID/GID for consistency
# - Configuring sudo access via wheel group membership
# - Setting up home directory with proper permissions
# - Configuring shell and authentication

# Copy user setup script for secure non-root user creation
COPY resources/prebuildfs/opt/laragis/setup/setup-user.sh /opt/laragis/setup/setup-user.sh

# Execute user setup with secure password handling
# Passwords are passed as environment variables to avoid exposure in layers
RUN echo "==> Setting up non-root user: ${USER_NAME} (UID: ${USER_UID}, GID: ${USER_GID})..." && \
    ROOT_PASSWORD="${ROOT_PASSWORD}" \
    USER_PASSWORD="${USER_PASSWORD}" \
    /opt/laragis/setup/setup-user.sh && \
    echo "==> User setup completed successfully"

# Add user's local bin directory to PATH for user-installed tools
# This enables tools installed via pip --user, npm -g, etc. to be accessible
ENV PATH="/home/${USER_NAME}/.local/bin:${PATH}"

# -----------------------------------------------------------------------------
# Essential System Utilities Installation
# -----------------------------------------------------------------------------

RUN --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    echo "==> Installing essential system utilities..." && \
    dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
        # Network and transfer utilities
        curl wget openssl bind-utils iproute iputils \
        openssh-clients rsync telnet nc \
        # Archive and compression tools
        tar gzip bzip2 xz unzip zip p7zip lz4 zstd \
        # System utilities and process management
        procps-ng util-linux findutils which diffutils \
        less file lsof htop iotop \
        # Terminal and editor tools
        ncurses ncurses-devel readline \
        vim nano tmux screen \
        # Development essentials
        git tree jq \
        # System monitoring and debugging
        strace tcpdump net-tools sysstat dstat && \
    # Clean package manager cache to reduce layer size
    echo "==> Cleaning package manager cache..." && \
    dnf clean all

# -----------------------------------------------------------------------------
# Development Tools & Libraries Installation
# -----------------------------------------------------------------------------

RUN --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    echo "Using direct DNF installation fallback..." && \
    # Install development group packages
    dnf -y groupinstall "Development Tools" --setopt=install_weak_deps=False && \
    # Install additional development tools and libraries
    dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
        # Build essentials and compilers
        gcc gcc-c++ make cmake autoconf automake libtool pkgconfig \
        # Language runtimes
        golang nodejs npm rust cargo \
        # Database development libraries
        sqlite-devel postgresql-devel mysql-devel \
        # System development libraries
        openssl-devel libcurl-devel zlib-devel bzip2-devel \
        xz-devel readline-devel libffi-devel \
        # XML/JSON processing
        libxml2-devel libxslt-devel json-c-devel \
        # Image processing
        libjpeg-turbo-devel libpng-devel \
        # Debugging and profiling
        gdb valgrind perf \
        # Version control
        git-lfs subversion mercurial && \
    dnf clean all;

# =============================================================================
# OPTIONAL DEVELOPMENT TOOLS INSTALLATION
# =============================================================================
# Each tool can be conditionally installed using build arguments and flags.
# Tools are organized into logical categories for better maintainability.
# Use INSTALL_<TOOL> flags to selectively include tools in your build.

# -----------------------------------------------------------------------------
# Development Tools Installation Flags
# -----------------------------------------------------------------------------
ARG INSTALL_SUPERVISOR=true
ARG INSTALL_ANSIBLE=true
ARG INSTALL_K6=true
ARG INSTALL_ZELLIJ=true
ARG INSTALL_GUM=true
ARG INSTALL_GETOPTIONS=true
ARG INSTALL_AWS_CLI=true
ARG INSTALL_DRY=true
ARG INSTALL_LAZYDOCKER=true
ARG INSTALL_GITHUB_CLI=true
ARG INSTALL_CLOUDFLARED=true
ARG INSTALL_LAZYGIT=true
ARG INSTALL_NGROK=true
ARG INSTALL_STARSHIP=true
ARG INSTALL_TAILSCALE=true
ARG INSTALL_TASK=true
ARG INSTALL_TERRAFORM=true
ARG INSTALL_TELEPORT=true
ARG INSTALL_KUBECTL=true
ARG INSTALL_HELM=true
ARG INSTALL_K9S=true
ARG INSTALL_GOMPLATE=true
ARG INSTALL_DBEAVER=true
ARG INSTALL_MISE=true
ARG INSTALL_UV=true
ARG INSTALL_VOLTA=true
ARG INSTALL_WP_CLI=true

# -----------------------------------------------------------------------------
# Process Management - Supervisor Installation and Configuration
# -----------------------------------------------------------------------------
# Install Supervisor for managing multiple processes within the container.
# Supervisor provides robust process control, automatic restart capabilities,
# centralized logging, and web-based monitoring interface.

ARG SUPERVISOR_VERSION=4.3.0

COPY resources/prebuildfs/opt/laragis/tools/supervisor.sh /opt/laragis/tools/supervisor.sh

RUN if [ "${INSTALL_SUPERVISOR}" = "true" ]; then \
        SUPERVISOR_VERSION="${SUPERVISOR_VERSION}" /opt/laragis/tools/supervisor.sh; \
    fi

# =============================================================================
# OPTIONAL DEVELOPMENT TOOLS INSTALLATION
# =============================================================================

# --------------------------------------------------------------------------
# Ansible - Infrastructure automation and configuration management
# Radically simple IT automation platform for configuration management
# Repo: https://github.com/ansible/ansible
# --------------------------------------------------------------------------
ARG ANSIBLE_VERSION=11.9.0
COPY resources/prebuildfs/opt/laragis/tools/ansible.sh /opt/laragis/tools/ansible.sh
RUN if [ "${INSTALL_ANSIBLE}" = "true" ]; then \
        ANSIBLE_VERSION="${ANSIBLE_VERSION}" /opt/laragis/tools/ansible.sh; \
    fi

# --------------------------------------------------------------------------
# Terraform - Infrastructure as Code tool
# Build, change, and version infrastructure safely and efficiently
# Repo: https://github.com/hashicorp/terraform
# --------------------------------------------------------------------------
ARG TERRAFORM_VERSION=1.13.0
COPY resources/prebuildfs/opt/laragis/tools/terraform.sh /opt/laragis/tools/terraform.sh
RUN if [ "${INSTALL_TERRAFORM}" = "true" ]; then \
        TERRAFORM_VERSION="${TERRAFORM_VERSION}" /opt/laragis/tools/terraform.sh; \
    fi

# --------------------------------------------------------------------------
# Teleport - Secure access to infrastructure
# The easiest, and most secure way to access and protect all infrastructure
# Repo: https://github.com/gravitational/teleport
# --------------------------------------------------------------------------
ARG TELEPORT_VERSION=18.1.6
COPY resources/prebuildfs/opt/laragis/tools/teleport.sh /opt/laragis/tools/teleport.sh
RUN if [ "${INSTALL_TELEPORT}" = "true" ]; then \
        TELEPORT_VERSION="${TELEPORT_VERSION}" /opt/laragis/tools/teleport.sh; \
    fi

# --------------------------------------------------------------------------
# kubectl - Kubernetes command-line interface
# Official command-line tool for interacting with Kubernetes clusters
# Repo: https://github.com/kubernetes/kubernetes
# --------------------------------------------------------------------------
ARG KUBECTL_VERSION=1.31.12
COPY resources/prebuildfs/opt/laragis/tools/kubectl.sh /opt/laragis/tools/kubectl.sh
RUN if [ "${INSTALL_KUBECTL}" = "true" ]; then \
        KUBECTL_VERSION="${KUBECTL_VERSION}" /opt/laragis/tools/kubectl.sh; \
    fi

# --------------------------------------------------------------------------
# Helm - Kubernetes package manager
# The package manager for Kubernetes applications
# Repo: https://github.com/helm/helm
# --------------------------------------------------------------------------
ARG HELM_VERSION=3.18.6
COPY resources/prebuildfs/opt/laragis/tools/helm.sh /opt/laragis/tools/helm.sh
RUN if [ "${INSTALL_HELM}" = "true" ]; then \
        HELM_VERSION="${HELM_VERSION}" /opt/laragis/tools/helm.sh; \
    fi

# --------------------------------------------------------------------------
# k9s - Kubernetes cluster management UI
# Terminal-based UI for managing Kubernetes clusters in style
# Repo: https://github.com/derailed/k9s
# --------------------------------------------------------------------------
ARG K9S_VERSION=0.50.9
COPY resources/prebuildfs/opt/laragis/tools/k9s.sh /opt/laragis/tools/k9s.sh
RUN if [ "${INSTALL_K9S}" = "true" ]; then \
        K9S_VERSION="${K9S_VERSION}" /opt/laragis/tools/k9s.sh; \
    fi

# --------------------------------------------------------------------------
# Docker CLI - Container platform command-line interface
# Official command-line interface for Docker container platform
# Repo: https://github.com/docker/cli
# --------------------------------------------------------------------------
ARG DOCKER_VERSION=28.3.2
COPY resources/prebuildfs/opt/laragis/tools/docker.sh /opt/laragis/tools/docker.sh
RUN DOCKER_VERSION="${DOCKER_VERSION}" /opt/laragis/tools/docker.sh

# --------------------------------------------------------------------------
# dry - Docker terminal manager
# Interactive terminal-based Docker container and image manager
# Repo: https://github.com/moncho/dry
# --------------------------------------------------------------------------
ARG DRY_VERSION=0.11.2
COPY resources/prebuildfs/opt/laragis/tools/dry.sh /opt/laragis/tools/dry.sh
RUN if [ "${INSTALL_DRY}" = "true" ]; then \
        DRY_VERSION="${DRY_VERSION}" /opt/laragis/tools/dry.sh; \
    fi

# --------------------------------------------------------------------------
# lazydocker - Lazy Docker management
# The lazier way to manage everything Docker from the terminal
# Repo: https://github.com/jesseduffield/lazydocker
# --------------------------------------------------------------------------
ARG LAZYDOCKER_VERSION=0.24.1
COPY resources/prebuildfs/opt/laragis/tools/lazydocker.sh /opt/laragis/tools/lazydocker.sh
RUN if [ "${INSTALL_LAZYDOCKER}" = "true" ]; then \
        LAZYDOCKER_VERSION="${LAZYDOCKER_VERSION}" /opt/laragis/tools/lazydocker.sh; \
    fi

# --------------------------------------------------------------------------
# AWS CLI - Amazon Web Services command-line interface
# Universal command-line interface for Amazon Web Services
# Repo: https://github.com/aws/aws-cli
# --------------------------------------------------------------------------
ARG AWS_CLI_VERSION=2.28.16
COPY resources/prebuildfs/opt/laragis/tools/aws-cli.sh /opt/laragis/tools/aws-cli.sh
RUN if [ "${INSTALL_AWS_CLI}" = "true" ]; then \
        AWS_CLI_VERSION="${AWS_CLI_VERSION}" /opt/laragis/tools/aws-cli.sh; \
    fi

# --------------------------------------------------------------------------
# Cloudflared - Cloudflare Tunnel client
# Secure tunneling solution (formerly Argo Tunnel)
# Repo: https://github.com/cloudflare/cloudflared
# --------------------------------------------------------------------------
ARG CLOUDFLARED_VERSION=2025.8.1
COPY resources/prebuildfs/opt/laragis/tools/cloudflared.sh /opt/laragis/tools/cloudflared.sh
RUN if [ "${INSTALL_CLOUDFLARED}" = "true" ]; then \
        CLOUDFLARED_VERSION="${CLOUDFLARED_VERSION}" /opt/laragis/tools/cloudflared.sh; \
    fi

# --------------------------------------------------------------------------
# Tailscale - Zero-config VPN solution
# The easiest, most secure way to use WireGuard and 2FA
# Repo: https://github.com/tailscale/tailscale
# --------------------------------------------------------------------------
ARG TAILSCALE_VERSION=1.86.2
COPY resources/prebuildfs/opt/laragis/tools/tailscale.sh /opt/laragis/tools/tailscale.sh
RUN if [ "${INSTALL_TAILSCALE}" = "true" ]; then \
        TAILSCALE_VERSION="${TAILSCALE_VERSION}" /opt/laragis/tools/tailscale.sh; \
    fi

# --------------------------------------------------------------------------
# ngrok - Secure tunneling service
# Secure introspectable tunnels to localhost
# Repo: https://ngrok.com
# --------------------------------------------------------------------------
ARG NGROK_VERSION=3.26.0
ARG NGROK_AUTHTOKEN
ENV NGROK_AUTHTOKEN=${NGROK_AUTHTOKEN}
COPY resources/prebuildfs/opt/laragis/tools/ngrok.sh /opt/laragis/tools/ngrok.sh
RUN if [ "${INSTALL_NGROK}" = "true" ]; then \
        NGROK_VERSION="${NGROK_VERSION}" /opt/laragis/tools/ngrok.sh; \
    fi

# --------------------------------------------------------------------------
# GitHub CLI - GitHub's official command-line tool
# Official command-line interface for GitHub
# Repo: https://github.com/cli/cli
# --------------------------------------------------------------------------
ARG GITHUB_CLI_VERSION=2.78.0
ARG GH_TOKEN
ENV GH_TOKEN=${GH_TOKEN}
COPY resources/prebuildfs/opt/laragis/tools/github-cli.sh /opt/laragis/tools/github-cli.sh
RUN if [ "${INSTALL_GITHUB_CLI}" = "true" ]; then \
        GITHUB_CLI_VERSION="${GITHUB_CLI_VERSION}" /opt/laragis/tools/github-cli.sh; \
    fi

# --------------------------------------------------------------------------
# lazygit - Terminal Git UI
# Simple terminal UI for git commands with intuitive interface
# Repo: https://github.com/jesseduffield/lazygit
# --------------------------------------------------------------------------
ARG LAZYGIT_VERSION=0.54.2
COPY resources/prebuildfs/opt/laragis/tools/lazygit.sh /opt/laragis/tools/lazygit.sh
RUN if [ "${INSTALL_LAZYGIT}" = "true" ]; then \
        LAZYGIT_VERSION="${LAZYGIT_VERSION}" /opt/laragis/tools/lazygit.sh; \
    fi

# --------------------------------------------------------------------------
# k6 - Modern load testing tool
# Performance testing tool using Go and JavaScript
# Repo: https://github.com/grafana/k6
# --------------------------------------------------------------------------
ARG K6_VERSION=1.2.2
COPY resources/prebuildfs/opt/laragis/tools/k6.sh /opt/laragis/tools/k6.sh
RUN if [ "${INSTALL_K6}" = "true" ]; then \
        K6_VERSION="${K6_VERSION}" /opt/laragis/tools/k6.sh; \
    fi

# --------------------------------------------------------------------------
# Zellij - Terminal workspace multiplexer
# Modern terminal workspace with batteries included
# Repo: https://github.com/zellij-org/zellij
# --------------------------------------------------------------------------
ARG ZELLIJ_VERSION=0.43.1
COPY resources/prebuildfs/opt/laragis/tools/zellij.sh /opt/laragis/tools/zellij.sh
RUN if [ "${INSTALL_ZELLIJ}" = "true" ]; then \
        ZELLIJ_VERSION="${ZELLIJ_VERSION}" /opt/laragis/tools/zellij.sh; \
    fi

# --------------------------------------------------------------------------
# Starship - Cross-shell prompt
# Minimal, blazing-fast, and infinitely customizable prompt for any shell
# Repo: https://github.com/starship/starship
# --------------------------------------------------------------------------
ARG STARSHIP_VERSION=1.23.0
COPY resources/prebuildfs/opt/laragis/tools/starship.sh /opt/laragis/tools/starship.sh
RUN if [ "${INSTALL_STARSHIP}" = "true" ]; then \
        STARSHIP_VERSION="${STARSHIP_VERSION}" /opt/laragis/tools/starship.sh; \
    fi

# --------------------------------------------------------------------------
# Gum - Glamorous shell scripts
# Tool for creating beautiful and interactive shell scripts
# Repo: https://github.com/charmbracelet/gum
# --------------------------------------------------------------------------
ARG GUM_VERSION=0.16.2
COPY resources/prebuildfs/opt/laragis/tools/gum.sh /opt/laragis/tools/gum.sh
RUN if [ "${INSTALL_GUM}" = "true" ]; then \
        GUM_VERSION="${GUM_VERSION}" /opt/laragis/tools/gum.sh; \
    fi

# --------------------------------------------------------------------------
# Task - Modern task runner
# Simple Make alternative and task runner written in Go
# Repo: https://github.com/go-task/task
# --------------------------------------------------------------------------
ARG TASK_VERSION=3.44.1
COPY resources/prebuildfs/opt/laragis/tools/task.sh /opt/laragis/tools/task.sh
RUN if [ "${INSTALL_TASK}" = "true" ]; then \
        TASK_VERSION="${TASK_VERSION}" /opt/laragis/tools/task.sh; \
    fi

# --------------------------------------------------------------------------
# Gomplate - Template rendering tool
# Flexible command-line tool for template rendering
# Repo: https://github.com/hairyhenderson/gomplate
# --------------------------------------------------------------------------
ARG GOMPLATE_VERSION=4.3.3
COPY resources/prebuildfs/opt/laragis/tools/gomplate.sh /opt/laragis/tools/gomplate.sh
RUN if [ "${INSTALL_GOMPLATE}" = "true" ]; then \
        GOMPLATE_VERSION="${GOMPLATE_VERSION}" /opt/laragis/tools/gomplate.sh; \
    fi

# --------------------------------------------------------------------------
# mise - Development environment manager
# Universal tool version manager (dev tools, env vars, task runner)
# Repo: https://github.com/jdx/mise
# --------------------------------------------------------------------------
ARG MISE_VERSION=2025.8.20
COPY resources/prebuildfs/opt/laragis/tools/mise.sh /opt/laragis/tools/mise.sh
RUN if [ "${INSTALL_MISE}" = "true" ]; then \
        MISE_VERSION="${MISE_VERSION}" /opt/laragis/tools/mise.sh; \
    fi

# --------------------------------------------------------------------------
# Volta - JavaScript tool manager
# Hassle-free JavaScript tool manager for Node.js projects
# Repo: https://github.com/volta-cli/volta
# --------------------------------------------------------------------------
ARG VOLTA_VERSION=2.0.2
COPY resources/prebuildfs/opt/laragis/tools/volta.sh /opt/laragis/tools/volta.sh
RUN if [ "${INSTALL_VOLTA}" = "true" ]; then \
        VOLTA_VERSION="${VOLTA_VERSION}" /opt/laragis/tools/volta.sh; \
    fi

# --------------------------------------------------------------------------
# uv - Python package manager
# Extremely fast Python package and project manager, written in Rust
# Repo: https://github.com/astral-sh/uv
# --------------------------------------------------------------------------
ARG UV_VERSION=0.8.13
COPY resources/prebuildfs/opt/laragis/tools/uv.sh /opt/laragis/tools/uv.sh
RUN if [ "${INSTALL_UV}" = "true" ]; then \
        UV_VERSION="${UV_VERSION}" /opt/laragis/tools/uv.sh; \
    fi

# --------------------------------------------------------------------------
# getoptions - Shell script option parser
# Elegant option/argument parser for shell scripts
# Repo: https://github.com/ko1nksm/getoptions
# --------------------------------------------------------------------------
ARG GETOPTIONS_VERSION=3.3.2
COPY resources/prebuildfs/opt/laragis/tools/getoptions.sh /opt/laragis/tools/getoptions.sh
RUN if [ "${INSTALL_GETOPTIONS}" = "true" ]; then \
        GETOPTIONS_VERSION="${GETOPTIONS_VERSION}" /opt/laragis/tools/getoptions.sh; \
    fi

# --------------------------------------------------------------------------
# DBeaver - Universal database tool
# Free multi-platform database tool for developers and database administrators
# Repo: https://github.com/dbeaver/dbeaver
# --------------------------------------------------------------------------
ARG DBEAVER_VERSION=25.1.5
COPY resources/prebuildfs/opt/laragis/tools/dbeaver.sh /opt/laragis/tools/dbeaver.sh
RUN if [ "${INSTALL_DBEAVER}" = "true" ]; then \
        DBEAVER_VERSION="${DBEAVER_VERSION}" /opt/laragis/tools/dbeaver.sh; \
    fi

# --------------------------------------------------------------------------
# WP-CLI - WordPress command-line interface
# Official command-line interface for WordPress management
# Repo: https://github.com/wp-cli/wp-cli
# --------------------------------------------------------------------------
ARG WP_CLI_VERSION=2.12.0
COPY resources/prebuildfs/opt/laragis/tools/wp-cli.sh /opt/laragis/tools/wp-cli.sh
RUN if [ "${INSTALL_WP_CLI}" = "true" ]; then \
        WP_CLI_VERSION="${WP_CLI_VERSION}" /opt/laragis/tools/wp-cli.sh; \
    fi

# -----------------------------------------------------------------------------
# Language Runtimes and Final System Configuration
# -----------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Certificate Management
# --------------------------------------------------------------------------

COPY resources/ca-certificates/* /usr/local/share/ca-certificates/
RUN update-ca-trust

# --------------------------------------------------------------------------
# SSH Configuration
# --------------------------------------------------------------------------

COPY resources/.ssh ${HOME_DIR}/.ssh

# --------------------------------------------------------------------------
# Final System Configuration
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
