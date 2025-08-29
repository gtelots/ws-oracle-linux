# syntax=docker/dockerfile:1.7-labs

# =============================================================================
# BASE IMAGE CONFIGURATION
# =============================================================================
# Oracle Linux 9 provides enterprise-grade stability, security updates,
# and compatibility with RHEL ecosystem while being freely available.
# Official repository: https://github.com/oracle/container-images

ARG BASE_IMAGE_NAME=oraclelinux
ARG BASE_IMAGE_TAG=9
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS base

# =============================================================================
# CONTAINER METADATA AND LABELS
# =============================================================================
# OCI-compliant labels for container registry management and documentation

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

# =============================================================================
# BUILD ARGUMENTS - CONTAINER CONFIGURATION
# =============================================================================
# These arguments control container behavior and can be customized during
# build time using --build-arg flags for different deployment scenarios

# Timezone configuration
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

# =============================================================================
# ENVIRONMENT VARIABLES - RUNTIME CONFIGURATION
# =============================================================================
# These variables are available during both build and runtime, providing
# consistent configuration across the container lifecycle

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=${TZ} \
    USER_UID=${USER_UID} \
    USER_GID=${USER_GID} \
    USER_NAME=${USER_NAME} \
    USER_SHELL=${USER_SHELL} \
    WORKSPACE_DIR=${WORKSPACE_DIR} \
    HOME_DIR=/home/${USER_NAME} \
    DATA_DIR=${DATA_DIR}

# =============================================================================
# SYSTEM FOUNDATION SETUP
# =============================================================================
# This section establishes the core system foundation including repositories,
# security updates, essential packages, and Python runtime environment

# Switch to root for system-level operations
USER root

# Copy essential configuration files and libraries
# Excluding installation scripts to optimize build cache layers by separating
# stable configuration from frequently changing installation scripts
COPY --exclude=setup/** --exclude=tools/** --exclude=packages/** \
     resources/prebuildfs/ /

# =============================================================================
# CORE SYSTEM PACKAGES AND PYTHON RUNTIME
# =============================================================================

# Python version configuration for consistent runtime environment
ARG PYTHON_VERSION=3.12
ENV PYTHON_VERSION="${PYTHON_VERSION}"

# Install core system foundation with optimized caching and error handling
RUN --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    set -euxo pipefail && \
    \
    # Step 1: Configure repositories and package management
    echo "==> Configuring repositories and package management..." && \
    dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
        dnf-plugins-core && \
    \
    # Step 2: Enable EPEL repository for additional packages
    # Try Oracle's EPEL first, fallback to developer EPEL if unavailable
    echo "==> Enabling EPEL repository..." && \
    (dnf -y install oracle-epel-release-el9 || \
     dnf -y config-manager --enable ol9_developer_EPEL) && \
    \
    # Step 3: Apply security updates (non-fatal if no updates available)
    echo "==> Applying security updates..." && \
    dnf -y update-minimal --security \
        --setopt=install_weak_deps=False \
        --refresh || echo "No security updates available or update failed" && \
    \
    # Step 4: Install core system packages in single transaction for efficiency
    echo "==> Installing core system packages..." && \
    dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
        ca-certificates tzdata shadow-utils passwd sudo systemd \
        glibc-langpack-en glibc-langpack-vi glibc-locale-source && \
    \
    # Step 5: Install Python runtime and development tools
    echo "==> Installing Python ${PYTHON_VERSION} runtime and development tools..." && \
    dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
        python3 python3-pip python3-setuptools python3-devel \
        python${PYTHON_VERSION} python${PYTHON_VERSION}-pip \
        python${PYTHON_VERSION}-setuptools python${PYTHON_VERSION}-wheel \
        python${PYTHON_VERSION}-devel && \
    \
    # Step 6: Install pipx for isolated Python tool installation
    echo "==> Installing pipx for isolated Python tools..." && \
    pip${PYTHON_VERSION} install pipx && \
    \
    # Step 7: Configure timezone settings
    echo "==> Configuring timezone settings..." && \
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime && \
    echo "${TZ}" > /etc/timezone && \
    \
    # Step 8: Verify repository configuration
    echo "==> Verifying repository configuration..." && \
    dnf repolist enabled && \
    \
    # Step 9: Clean package manager cache to reduce layer size
    echo "==> Cleaning package manager cache..." && \
    dnf clean all

# =============================================================================
# USER MANAGEMENT AND SECURITY CONFIGURATION
# =============================================================================
# Create a non-root user with sudo privileges following security best practices.
# This prevents running applications as root and provides proper access control.

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

# =============================================================================
# MODULAR PACKAGE INSTALLATION
# =============================================================================
# Install packages using modular scripts for better maintainability

# Copy package installation scripts
COPY resources/prebuildfs/opt/laragis/packages/ /opt/laragis/packages/

# Install core system packages and Python runtime
RUN echo "==> Installing core system packages and Python runtime..." && \
    PYTHON_VERSION="${PYTHON_VERSION}" /opt/laragis/packages/core-system-packages.sh

# Install essential development tools
RUN echo "==> Installing essential development tools..." && \
    PYTHON_VERSION="${PYTHON_VERSION}" /opt/laragis/packages/development-tools.sh

# Install additional system utilities
RUN echo "==> Installing additional system utilities..." && \
    /opt/laragis/packages/system-utilities.sh

# =============================================================================
# OPTIONAL DEVELOPMENT TOOLS INSTALLATION
# =============================================================================
# This section provides conditional installation of modern development tools.
# Each tool can be selectively installed using build arguments and flags.
# Tools are organized into logical categories for better maintainability.

# -----------------------------------------------------------------------------
# DEVELOPMENT TOOLS INSTALLATION FLAGS
# -----------------------------------------------------------------------------
# Use INSTALL_<TOOL>=true/false flags to selectively include tools in your build
# Default: all tools are enabled for comprehensive development environment

# Note: Supervisor is mandatory for container process management
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

# Modern CLI Tools Installation Flags
ARG INSTALL_NEOVIM=true
ARG INSTALL_FD=true
ARG INSTALL_RIPGREP=true
ARG INSTALL_BAT=true
ARG INSTALL_EZA=true
ARG INSTALL_HTTPIE=true
ARG INSTALL_BTOP=true
ARG INSTALL_TRIVY=true

# Additional Modern CLI Tools
ARG INSTALL_FZF=true
ARG INSTALL_ZOXIDE=true
ARG INSTALL_DUF=true

# Modern CLI Tools Installation Flags (Individual Control)
ARG INSTALL_JQ=true
ARG INSTALL_YQ=true
ARG INSTALL_TLDR=true
ARG INSTALL_NCDU=true
ARG INSTALL_SPEEDTEST_CLI=true
ARG INSTALL_PROCS=true
ARG INSTALL_SD=true
ARG INSTALL_BROOT=true
ARG INSTALL_GPING=true
ARG INSTALL_FASTFETCH=true
ARG INSTALL_THEFUCK=true
ARG INSTALL_CHOOSE=true
ARG INSTALL_HYPERFINE=true
ARG INSTALL_JUST=true
ARG INSTALL_YAZI=true

ARG INSTALL_MODERN_CLI_GROUP=true
ARG INSTALL_ADVANCED_CLI_GROUP=true

# System Setup Configuration
# Note: SSH Server and ZSH are installed by default as essential components

# Language Runtime Installation Flags
ARG INSTALL_JAVA=true
ARG INSTALL_RUST=true
ARG INSTALL_GO=true
ARG INSTALL_NODEJS=true
ARG INSTALL_PHP=true
ARG INSTALL_RUBY=true
ARG INSTALL_PYTHON_EXTRAS=true

# Language Runtime Versions
ARG JAVA_VERSION=21
ARG RUST_VERSION=1.84.0
ARG GO_VERSION=1.23.4
ARG NODEJS_VERSION=22.12.0
ARG PHP_VERSION=8.3
ARG RUBY_VERSION=3.3.6
ARG PYTHON_VERSION=3.12

# =============================================================================
# PROCESS MANAGEMENT - SUPERVISOR
# =============================================================================
# Supervisor provides robust process control, automatic restart capabilities,
# centralized logging, and web-based monitoring interface for container services
# Repository: https://github.com/Supervisor/supervisor

ARG SUPERVISOR_VERSION=4.3.0
COPY resources/prebuildfs/opt/laragis/tools/supervisor.sh /opt/laragis/tools/supervisor.sh

# Install Supervisor (mandatory for container process management)
RUN echo "==> Installing Supervisor v${SUPERVISOR_VERSION}..." && \
    SUPERVISOR_VERSION="${SUPERVISOR_VERSION}" /opt/laragis/tools/supervisor.sh

# =============================================================================
# INFRASTRUCTURE AND DEVOPS TOOLS
# =============================================================================
# Essential tools for infrastructure automation, configuration management,
# and secure access to distributed systems

# Ansible - Infrastructure automation and configuration management
# Repository: https://github.com/ansible/ansible
ARG ANSIBLE_VERSION=11.9.0

# Terraform - Infrastructure as Code tool for building, changing, and versioning infrastructure
# Repository: https://github.com/hashicorp/terraform
ARG TERRAFORM_VERSION=1.13.0

# Teleport - Secure access to infrastructure with identity-based access
# Repository: https://github.com/gravitational/teleport
ARG TELEPORT_VERSION=18.1.6

# Copy installation scripts for infrastructure tools
COPY resources/prebuildfs/opt/laragis/tools/ansible.sh /opt/laragis/tools/ansible.sh
COPY resources/prebuildfs/opt/laragis/tools/terraform.sh /opt/laragis/tools/terraform.sh
COPY resources/prebuildfs/opt/laragis/tools/teleport.sh /opt/laragis/tools/teleport.sh

# Install infrastructure and DevOps tools
RUN if [ "${INSTALL_ANSIBLE}" = "true" ]; then \
        echo "==> Installing Ansible v${ANSIBLE_VERSION}..." && \
        ANSIBLE_VERSION="${ANSIBLE_VERSION}" /opt/laragis/tools/ansible.sh; \
    fi && \
    if [ "${INSTALL_TERRAFORM}" = "true" ]; then \
        echo "==> Installing Terraform v${TERRAFORM_VERSION}..." && \
        TERRAFORM_VERSION="${TERRAFORM_VERSION}" /opt/laragis/tools/terraform.sh; \
    fi && \
    if [ "${INSTALL_TELEPORT}" = "true" ]; then \
        echo "==> Installing Teleport v${TELEPORT_VERSION}..." && \
        TELEPORT_VERSION="${TELEPORT_VERSION}" /opt/laragis/tools/teleport.sh; \
    fi

# =============================================================================
# KUBERNETES ECOSYSTEM TOOLS
# =============================================================================
# Essential tools for Kubernetes cluster management and application deployment

# kubectl - Official Kubernetes command-line interface
# Repository: https://github.com/kubernetes/kubernetes
ARG KUBECTL_VERSION=1.31.12

# Helm - The package manager for Kubernetes applications
# Repository: https://github.com/helm/helm
ARG HELM_VERSION=3.18.6

# k9s - Terminal-based UI for managing Kubernetes clusters
# Repository: https://github.com/derailed/k9s
ARG K9S_VERSION=0.50.9

# Copy installation scripts for Kubernetes tools
COPY resources/prebuildfs/opt/laragis/tools/kubectl.sh /opt/laragis/tools/kubectl.sh
COPY resources/prebuildfs/opt/laragis/tools/helm.sh /opt/laragis/tools/helm.sh
COPY resources/prebuildfs/opt/laragis/tools/k9s.sh /opt/laragis/tools/k9s.sh

# Install Kubernetes ecosystem tools
RUN if [ "${INSTALL_KUBECTL}" = "true" ]; then \
        echo "==> Installing kubectl v${KUBECTL_VERSION}..." && \
        KUBECTL_VERSION="${KUBECTL_VERSION}" /opt/laragis/tools/kubectl.sh; \
    fi && \
    if [ "${INSTALL_HELM}" = "true" ]; then \
        echo "==> Installing Helm v${HELM_VERSION}..." && \
        HELM_VERSION="${HELM_VERSION}" /opt/laragis/tools/helm.sh; \
    fi && \
    if [ "${INSTALL_K9S}" = "true" ]; then \
        echo "==> Installing k9s v${K9S_VERSION}..." && \
        K9S_VERSION="${K9S_VERSION}" /opt/laragis/tools/k9s.sh; \
    fi

# =============================================================================
# DOCKER AND CONTAINER TOOLS
# =============================================================================
# Tools for Docker container management and monitoring

# Docker CLI - Official command-line interface for Docker
# Repository: https://github.com/docker/cli
ARG DOCKER_VERSION=28.3.2

# dry - Interactive terminal-based Docker container and image manager
# Repository: https://github.com/moncho/dry
ARG DRY_VERSION=0.11.2

# lazydocker - The lazier way to manage everything Docker
# Repository: https://github.com/jesseduffield/lazydocker
ARG LAZYDOCKER_VERSION=0.24.1

# Copy installation scripts for Docker tools
COPY resources/prebuildfs/opt/laragis/tools/docker.sh /opt/laragis/tools/docker.sh
COPY resources/prebuildfs/opt/laragis/tools/dry.sh /opt/laragis/tools/dry.sh
COPY resources/prebuildfs/opt/laragis/tools/lazydocker.sh /opt/laragis/tools/lazydocker.sh

# Install Docker and container management tools
# Note: Docker CLI is always installed as it's essential for container operations
RUN echo "==> Installing Docker CLI v${DOCKER_VERSION}..." && \
    DOCKER_VERSION="${DOCKER_VERSION}" /opt/laragis/tools/docker.sh && \
    if [ "${INSTALL_DRY}" = "true" ]; then \
        echo "==> Installing dry v${DRY_VERSION}..." && \
        DRY_VERSION="${DRY_VERSION}" /opt/laragis/tools/dry.sh; \
    fi && \
    if [ "${INSTALL_LAZYDOCKER}" = "true" ]; then \
        echo "==> Installing lazydocker v${LAZYDOCKER_VERSION}..." && \
        LAZYDOCKER_VERSION="${LAZYDOCKER_VERSION}" /opt/laragis/tools/lazydocker.sh; \
    fi

# =============================================================================
# CLOUD AND NETWORKING TOOLS
# =============================================================================
# Tools for cloud services, secure tunneling, and network management

# AWS CLI - Universal command-line interface for Amazon Web Services
# Repository: https://github.com/aws/aws-cli
ARG AWS_CLI_VERSION=2.28.16

# Cloudflared - Cloudflare Tunnel client for secure connections
# Repository: https://github.com/cloudflare/cloudflared
ARG CLOUDFLARED_VERSION=2025.8.1

# Tailscale - Zero-config VPN solution using WireGuard
# Repository: https://github.com/tailscale/tailscale
ARG TAILSCALE_VERSION=1.86.2

# ngrok - Secure tunneling service for localhost exposure
# Website: https://ngrok.com
ARG NGROK_VERSION=3.26.0
ARG NGROK_AUTHTOKEN
ENV NGROK_AUTHTOKEN=${NGROK_AUTHTOKEN}

# Copy installation scripts for cloud and networking tools
COPY resources/prebuildfs/opt/laragis/tools/aws-cli.sh /opt/laragis/tools/aws-cli.sh
COPY resources/prebuildfs/opt/laragis/tools/cloudflared.sh /opt/laragis/tools/cloudflared.sh
COPY resources/prebuildfs/opt/laragis/tools/tailscale.sh /opt/laragis/tools/tailscale.sh
COPY resources/prebuildfs/opt/laragis/tools/ngrok.sh /opt/laragis/tools/ngrok.sh

# Install cloud and networking tools
RUN if [ "${INSTALL_AWS_CLI}" = "true" ]; then \
        echo "==> Installing AWS CLI v${AWS_CLI_VERSION}..." && \
        AWS_CLI_VERSION="${AWS_CLI_VERSION}" /opt/laragis/tools/aws-cli.sh; \
    fi && \
    if [ "${INSTALL_CLOUDFLARED}" = "true" ]; then \
        echo "==> Installing Cloudflared v${CLOUDFLARED_VERSION}..." && \
        CLOUDFLARED_VERSION="${CLOUDFLARED_VERSION}" /opt/laragis/tools/cloudflared.sh; \
    fi && \
    if [ "${INSTALL_TAILSCALE}" = "true" ]; then \
        echo "==> Installing Tailscale v${TAILSCALE_VERSION}..." && \
        TAILSCALE_VERSION="${TAILSCALE_VERSION}" /opt/laragis/tools/tailscale.sh; \
    fi && \
    if [ "${INSTALL_NGROK}" = "true" ]; then \
        echo "==> Installing ngrok v${NGROK_VERSION}..." && \
        NGROK_VERSION="${NGROK_VERSION}" /opt/laragis/tools/ngrok.sh; \
    fi

# =============================================================================
# GIT AND VERSION CONTROL TOOLS
# =============================================================================
# Enhanced Git workflow tools and GitHub integration

# GitHub CLI - Official command-line interface for GitHub
# Repository: https://github.com/cli/cli
ARG GITHUB_CLI_VERSION=2.78.0
ARG GH_TOKEN
ENV GH_TOKEN=${GH_TOKEN}

# lazygit - Simple terminal UI for git commands with intuitive interface
# Repository: https://github.com/jesseduffield/lazygit
ARG LAZYGIT_VERSION=0.54.2

# Copy installation scripts for Git tools
COPY resources/prebuildfs/opt/laragis/tools/github-cli.sh /opt/laragis/tools/github-cli.sh
COPY resources/prebuildfs/opt/laragis/tools/lazygit.sh /opt/laragis/tools/lazygit.sh

# Install Git and version control tools
RUN if [ "${INSTALL_GITHUB_CLI}" = "true" ]; then \
        echo "==> Installing GitHub CLI v${GITHUB_CLI_VERSION}..." && \
        GITHUB_CLI_VERSION="${GITHUB_CLI_VERSION}" /opt/laragis/tools/github-cli.sh; \
    fi && \
    if [ "${INSTALL_LAZYGIT}" = "true" ]; then \
        echo "==> Installing lazygit v${LAZYGIT_VERSION}..." && \
        LAZYGIT_VERSION="${LAZYGIT_VERSION}" /opt/laragis/tools/lazygit.sh; \
    fi

# =============================================================================
# TERMINAL AND PRODUCTIVITY TOOLS
# =============================================================================
# Modern terminal tools for enhanced productivity and beautiful interfaces

# k6 - Modern load testing tool using Go and JavaScript
# Repository: https://github.com/grafana/k6
ARG K6_VERSION=1.2.2

# Zellij - Terminal workspace multiplexer with batteries included
# Repository: https://github.com/zellij-org/zellij
ARG ZELLIJ_VERSION=0.43.1

# Starship - Minimal, blazing-fast, and infinitely customizable prompt
# Repository: https://github.com/starship/starship
ARG STARSHIP_VERSION=1.23.0

# Gum - Tool for creating beautiful and interactive shell scripts
# Repository: https://github.com/charmbracelet/gum
ARG GUM_VERSION=0.16.2

# Task - Simple Make alternative and task runner written in Go
# Repository: https://github.com/go-task/task
ARG TASK_VERSION=3.44.1

# Gomplate - Flexible command-line tool for template rendering
# Repository: https://github.com/hairyhenderson/gomplate
ARG GOMPLATE_VERSION=4.3.3

# Copy installation scripts for terminal and productivity tools
COPY resources/prebuildfs/opt/laragis/tools/k6.sh /opt/laragis/tools/k6.sh
COPY resources/prebuildfs/opt/laragis/tools/zellij.sh /opt/laragis/tools/zellij.sh
COPY resources/prebuildfs/opt/laragis/tools/starship.sh /opt/laragis/tools/starship.sh
COPY resources/prebuildfs/opt/laragis/tools/gum.sh /opt/laragis/tools/gum.sh
COPY resources/prebuildfs/opt/laragis/tools/task.sh /opt/laragis/tools/task.sh
COPY resources/prebuildfs/opt/laragis/tools/gomplate.sh /opt/laragis/tools/gomplate.sh

# Install terminal and productivity tools
RUN if [ "${INSTALL_K6}" = "true" ]; then \
        echo "==> Installing k6 v${K6_VERSION}..." && \
        K6_VERSION="${K6_VERSION}" /opt/laragis/tools/k6.sh; \
    fi && \
    if [ "${INSTALL_ZELLIJ}" = "true" ]; then \
        echo "==> Installing Zellij v${ZELLIJ_VERSION}..." && \
        ZELLIJ_VERSION="${ZELLIJ_VERSION}" /opt/laragis/tools/zellij.sh; \
    fi && \
    if [ "${INSTALL_STARSHIP}" = "true" ]; then \
        echo "==> Installing Starship v${STARSHIP_VERSION}..." && \
        STARSHIP_VERSION="${STARSHIP_VERSION}" /opt/laragis/tools/starship.sh; \
    fi && \
    if [ "${INSTALL_GUM}" = "true" ]; then \
        echo "==> Installing Gum v${GUM_VERSION}..." && \
        GUM_VERSION="${GUM_VERSION}" /opt/laragis/tools/gum.sh; \
    fi && \
    if [ "${INSTALL_TASK}" = "true" ]; then \
        echo "==> Installing Task v${TASK_VERSION}..." && \
        TASK_VERSION="${TASK_VERSION}" /opt/laragis/tools/task.sh; \
    fi && \
    if [ "${INSTALL_GOMPLATE}" = "true" ]; then \
        echo "==> Installing Gomplate v${GOMPLATE_VERSION}..." && \
        GOMPLATE_VERSION="${GOMPLATE_VERSION}" /opt/laragis/tools/gomplate.sh; \
    fi

# =============================================================================
# LANGUAGE RUNTIME MANAGERS AND SPECIALIZED TOOLS
# =============================================================================
# Tools for managing multiple language versions, package management,
# database administration, and specialized development workflows

# mise - Universal tool version manager (dev tools, env vars, task runner)
# Repository: https://github.com/jdx/mise
ARG MISE_VERSION=2025.8.20

# Volta - Hassle-free JavaScript tool manager for Node.js projects
# Repository: https://github.com/volta-cli/volta
ARG VOLTA_VERSION=2.0.2

# uv - Extremely fast Python package and project manager, written in Rust
# Repository: https://github.com/astral-sh/uv
ARG UV_VERSION=0.8.13

# getoptions - Elegant option/argument parser for shell scripts
# Repository: https://github.com/ko1nksm/getoptions
ARG GETOPTIONS_VERSION=3.3.2

# DBeaver - Free multi-platform database tool for developers and DBAs
# Repository: https://github.com/dbeaver/dbeaver
ARG DBEAVER_VERSION=25.1.5

# WP-CLI - Official command-line interface for WordPress management
# Repository: https://github.com/wp-cli/wp-cli
ARG WP_CLI_VERSION=2.12.0

# Copy installation scripts for language managers and specialized tools
COPY resources/prebuildfs/opt/laragis/tools/mise.sh /opt/laragis/tools/mise.sh
COPY resources/prebuildfs/opt/laragis/tools/volta.sh /opt/laragis/tools/volta.sh
COPY resources/prebuildfs/opt/laragis/tools/uv.sh /opt/laragis/tools/uv.sh
COPY resources/prebuildfs/opt/laragis/tools/getoptions.sh /opt/laragis/tools/getoptions.sh
COPY resources/prebuildfs/opt/laragis/tools/dbeaver.sh /opt/laragis/tools/dbeaver.sh
COPY resources/prebuildfs/opt/laragis/tools/wp-cli.sh /opt/laragis/tools/wp-cli.sh

# Install language runtime managers and specialized development tools
RUN if [ "${INSTALL_MISE}" = "true" ]; then \
        echo "==> Installing mise v${MISE_VERSION}..." && \
        MISE_VERSION="${MISE_VERSION}" /opt/laragis/tools/mise.sh; \
    fi && \
    if [ "${INSTALL_VOLTA}" = "true" ]; then \
        echo "==> Installing Volta v${VOLTA_VERSION}..." && \
        VOLTA_VERSION="${VOLTA_VERSION}" /opt/laragis/tools/volta.sh; \
    fi && \
    if [ "${INSTALL_UV}" = "true" ]; then \
        echo "==> Installing uv v${UV_VERSION}..." && \
        UV_VERSION="${UV_VERSION}" /opt/laragis/tools/uv.sh; \
    fi && \
    if [ "${INSTALL_GETOPTIONS}" = "true" ]; then \
        echo "==> Installing getoptions v${GETOPTIONS_VERSION}..." && \
        GETOPTIONS_VERSION="${GETOPTIONS_VERSION}" /opt/laragis/tools/getoptions.sh; \
    fi && \
    if [ "${INSTALL_DBEAVER}" = "true" ]; then \
        echo "==> Installing DBeaver v${DBEAVER_VERSION}..." && \
        DBEAVER_VERSION="${DBEAVER_VERSION}" /opt/laragis/tools/dbeaver.sh; \
    fi && \
    if [ "${INSTALL_WP_CLI}" = "true" ]; then \
        echo "==> Installing WP-CLI v${WP_CLI_VERSION}..." && \
        WP_CLI_VERSION="${WP_CLI_VERSION}" /opt/laragis/tools/wp-cli.sh; \
    fi

# =============================================================================
# MODERN CLI TOOLS AND UTILITIES
# =============================================================================
# Essential modern command-line tools that enhance developer productivity
# with better performance, user experience, and additional features

# Neovim - Hyperextensible Vim-based text editor
# Repository: https://github.com/neovim/neovim
ARG NEOVIM_VERSION=0.11.3

# fd - Simple, fast and user-friendly alternative to 'find'
# Repository: https://github.com/sharkdp/fd
ARG FD_VERSION=10.3.0

# ripgrep - Line-oriented search tool that recursively searches directories
# Repository: https://github.com/BurntSushi/ripgrep
ARG RIPGREP_VERSION=14.1.1

# bat - Cat clone with wings (syntax highlighting and Git integration)
# Repository: https://github.com/sharkdp/bat
ARG BAT_VERSION=0.24.0

# eza - Modern, maintained replacement for 'ls' with colors and Git integration
# Repository: https://github.com/eza-community/eza
ARG EZA_VERSION=0.23.0

# HTTPie - Modern, user-friendly command-line HTTP client
# Repository: https://github.com/httpie/httpie
ARG HTTPIE_VERSION=3.2.4

# btop - Feature-rich system monitor with beautiful interface
# Repository: https://github.com/aristocratos/btop
ARG BTOP_VERSION=1.4.4

# Trivy - Comprehensive security scanner for vulnerabilities
# Repository: https://github.com/aquasecurity/trivy
ARG TRIVY_VERSION=0.58.1

# fzf - Command-line fuzzy finder
# Repository: https://github.com/junegunn/fzf
ARG FZF_VERSION=0.58.0

# zoxide - Smart directory jumper
# Repository: https://github.com/ajeetdsouza/zoxide
ARG ZOXIDE_VERSION=0.9.6

# duf - Modern disk usage utility
# Repository: https://github.com/muesli/duf
ARG DUF_VERSION=0.8.1

# Modern CLI Tools Versions
# jq - Command-line JSON processor
# Repository: https://github.com/jqlang/jq
ARG JQ_VERSION=1.7.1

# yq - Command-line YAML processor
# Repository: https://github.com/mikefarah/yq
ARG YQ_VERSION=4.44.6

# tldr - Simplified man pages
# Repository: https://github.com/tldr-pages/tldr
ARG TLDR_VERSION=3.4.0

# ncdu - NCurses Disk Usage
# Repository: https://dev.yorhel.nl/ncdu
ARG NCDU_VERSION=1.19

# speedtest-cli - Command line speedtest
# Repository: https://github.com/sivel/speedtest-cli
ARG SPEEDTEST_CLI_VERSION=2.1.3

# procs - Modern replacement for ps
# Repository: https://github.com/dalance/procs
ARG PROCS_VERSION=0.14.8

# sd - Intuitive find & replace CLI
# Repository: https://github.com/chmln/sd
ARG SD_VERSION=1.0.0

# broot - Tree view and navigation
# Repository: https://github.com/Canop/broot
ARG BROOT_VERSION=1.44.2

# gping - Ping with graph
# Repository: https://github.com/orf/gping
ARG GPING_VERSION=1.18.0

# fastfetch - System information tool
# Repository: https://github.com/fastfetch-cli/fastfetch
ARG FASTFETCH_VERSION=2.32.0

# thefuck - Command correction tool
# Repository: https://github.com/nvbn/thefuck
ARG THEFUCK_VERSION=3.32

# choose - Human-friendly alternative to cut/awk
# Repository: https://github.com/theryangeary/choose
ARG CHOOSE_VERSION=1.3.6

# hyperfine - Command-line benchmarking tool
# Repository: https://github.com/sharkdp/hyperfine
ARG HYPERFINE_VERSION=1.19.0

# just - Command runner
# Repository: https://github.com/casey/just
ARG JUST_VERSION=1.37.0

# yazi - Terminal file manager
# Repository: https://github.com/sxyazi/yazi
ARG YAZI_VERSION=0.4.2

# Copy installation scripts for core tools
COPY resources/prebuildfs/opt/laragis/tools/neovim.sh /opt/laragis/tools/neovim.sh
COPY resources/prebuildfs/opt/laragis/tools/trivy.sh /opt/laragis/tools/trivy.sh

# Copy modern CLI tools from organized directory
COPY resources/prebuildfs/opt/laragis/tools/modern-cli/ /opt/laragis/tools/modern-cli/

# Install core modern CLI tools from modern-cli directory
RUN if [ "${INSTALL_NEOVIM}" = "true" ]; then \
        echo "==> Installing Neovim v${NEOVIM_VERSION}..." && \
        NEOVIM_VERSION="${NEOVIM_VERSION}" /opt/laragis/tools/neovim.sh; \
    fi && \
    if [ "${INSTALL_FD}" = "true" ]; then \
        echo "==> Installing fd v${FD_VERSION}..." && \
        FD_VERSION="${FD_VERSION}" /opt/laragis/tools/modern-cli/fd.sh; \
    fi && \
    if [ "${INSTALL_RIPGREP}" = "true" ]; then \
        echo "==> Installing ripgrep v${RIPGREP_VERSION}..." && \
        RIPGREP_VERSION="${RIPGREP_VERSION}" /opt/laragis/tools/modern-cli/ripgrep.sh; \
    fi && \
    if [ "${INSTALL_BAT}" = "true" ]; then \
        echo "==> Installing bat v${BAT_VERSION}..." && \
        BAT_VERSION="${BAT_VERSION}" /opt/laragis/tools/modern-cli/bat.sh; \
    fi && \
    if [ "${INSTALL_EZA}" = "true" ]; then \
        echo "==> Installing eza v${EZA_VERSION}..." && \
        EZA_VERSION="${EZA_VERSION}" /opt/laragis/tools/modern-cli/eza.sh; \
    fi && \
    if [ "${INSTALL_HTTPIE}" = "true" ]; then \
        echo "==> Installing HTTPie v${HTTPIE_VERSION}..." && \
        HTTPIE_VERSION="${HTTPIE_VERSION}" /opt/laragis/tools/modern-cli/httpie.sh; \
    fi && \
    if [ "${INSTALL_BTOP}" = "true" ]; then \
        echo "==> Installing btop v${BTOP_VERSION}..." && \
        BTOP_VERSION="${BTOP_VERSION}" /opt/laragis/tools/modern-cli/btop.sh; \
    fi && \
    if [ "${INSTALL_TRIVY}" = "true" ]; then \
        echo "==> Installing Trivy v${TRIVY_VERSION}..." && \
        TRIVY_VERSION="${TRIVY_VERSION}" /opt/laragis/tools/trivy.sh; \
    fi

# Install additional modern CLI tools individually
RUN if [ "${INSTALL_FZF}" = "true" ]; then \
        echo "==> Installing fzf v${FZF_VERSION}..." && \
        FZF_VERSION="${FZF_VERSION}" /opt/laragis/tools/modern-cli/fzf.sh; \
    fi && \
    if [ "${INSTALL_ZOXIDE}" = "true" ]; then \
        echo "==> Installing zoxide v${ZOXIDE_VERSION}..." && \
        ZOXIDE_VERSION="${ZOXIDE_VERSION}" /opt/laragis/tools/modern-cli/zoxide.sh; \
    fi && \
    if [ "${INSTALL_DUF}" = "true" ]; then \
        echo "==> Installing duf v${DUF_VERSION}..." && \
        DUF_VERSION="${DUF_VERSION}" /opt/laragis/tools/modern-cli/duf.sh; \
    fi

# Install modern CLI tools with conditional installation
RUN if [ "${INSTALL_JQ}" = "true" ]; then \
        echo "==> Installing jq v${JQ_VERSION}..." && \
        JQ_VERSION="${JQ_VERSION}" /opt/laragis/tools/modern-cli/jq.sh; \
    fi && \
    if [ "${INSTALL_YQ}" = "true" ]; then \
        echo "==> Installing yq v${YQ_VERSION}..." && \
        YQ_VERSION="${YQ_VERSION}" /opt/laragis/tools/modern-cli/yq.sh; \
    fi && \
    if [ "${INSTALL_TLDR}" = "true" ]; then \
        echo "==> Installing tldr v${TLDR_VERSION}..." && \
        TLDR_VERSION="${TLDR_VERSION}" /opt/laragis/tools/modern-cli/tldr.sh; \
    fi && \
    if [ "${INSTALL_NCDU}" = "true" ]; then \
        echo "==> Installing ncdu v${NCDU_VERSION}..." && \
        NCDU_VERSION="${NCDU_VERSION}" /opt/laragis/tools/modern-cli/ncdu.sh; \
    fi && \
    if [ "${INSTALL_SPEEDTEST_CLI}" = "true" ]; then \
        echo "==> Installing speedtest-cli v${SPEEDTEST_CLI_VERSION}..." && \
        SPEEDTEST_CLI_VERSION="${SPEEDTEST_CLI_VERSION}" /opt/laragis/tools/modern-cli/speedtest-cli.sh; \
    fi && \
    if [ "${INSTALL_PROCS}" = "true" ]; then \
        echo "==> Installing procs v${PROCS_VERSION}..." && \
        PROCS_VERSION="${PROCS_VERSION}" /opt/laragis/tools/modern-cli/procs.sh; \
    fi && \
    if [ "${INSTALL_SD}" = "true" ]; then \
        echo "==> Installing sd v${SD_VERSION}..." && \
        SD_VERSION="${SD_VERSION}" /opt/laragis/tools/modern-cli/sd.sh; \
    fi && \
    if [ "${INSTALL_BROOT}" = "true" ]; then \
        echo "==> Installing broot v${BROOT_VERSION}..." && \
        BROOT_VERSION="${BROOT_VERSION}" /opt/laragis/tools/modern-cli/broot.sh; \
    fi && \
    if [ "${INSTALL_GPING}" = "true" ]; then \
        echo "==> Installing gping v${GPING_VERSION}..." && \
        GPING_VERSION="${GPING_VERSION}" /opt/laragis/tools/modern-cli/gping.sh; \
    fi && \
    if [ "${INSTALL_FASTFETCH}" = "true" ]; then \
        echo "==> Installing fastfetch v${FASTFETCH_VERSION}..." && \
        FASTFETCH_VERSION="${FASTFETCH_VERSION}" /opt/laragis/tools/modern-cli/fastfetch.sh; \
    fi && \
    if [ "${INSTALL_THEFUCK}" = "true" ]; then \
        echo "==> Installing thefuck v${THEFUCK_VERSION}..." && \
        THEFUCK_VERSION="${THEFUCK_VERSION}" /opt/laragis/tools/modern-cli/thefuck.sh; \
    fi && \
    if [ "${INSTALL_CHOOSE}" = "true" ]; then \
        echo "==> Installing choose v${CHOOSE_VERSION}..." && \
        CHOOSE_VERSION="${CHOOSE_VERSION}" /opt/laragis/tools/modern-cli/choose.sh; \
    fi && \
    if [ "${INSTALL_HYPERFINE}" = "true" ]; then \
        echo "==> Installing hyperfine v${HYPERFINE_VERSION}..." && \
        HYPERFINE_VERSION="${HYPERFINE_VERSION}" /opt/laragis/tools/modern-cli/hyperfine.sh; \
    fi && \
    if [ "${INSTALL_JUST}" = "true" ]; then \
        echo "==> Installing just v${JUST_VERSION}..." && \
        JUST_VERSION="${JUST_VERSION}" /opt/laragis/tools/modern-cli/just.sh; \
    fi && \
    if [ "${INSTALL_YAZI}" = "true" ]; then \
        echo "==> Installing yazi v${YAZI_VERSION}..." && \
        YAZI_VERSION="${YAZI_VERSION}" /opt/laragis/tools/modern-cli/yazi.sh; \
    fi

# =============================================================================
# LANGUAGE RUNTIMES
# =============================================================================
# Install programming language runtimes and package managers

# Copy language runtime installation scripts
COPY resources/prebuildfs/opt/laragis/languages/ /opt/laragis/languages/

# Install Java (OpenJDK)
RUN if [ "${INSTALL_JAVA}" = "true" ]; then \
        echo "==> Installing Java OpenJDK v${JAVA_VERSION}..." && \
        JAVA_VERSION="${JAVA_VERSION}" /opt/laragis/languages/java.sh; \
    fi

# Install Rust with Cargo
RUN if [ "${INSTALL_RUST}" = "true" ]; then \
        echo "==> Installing Rust v${RUST_VERSION}..." && \
        RUST_VERSION="${RUST_VERSION}" /opt/laragis/languages/rust.sh; \
    fi

# Install Go
RUN if [ "${INSTALL_GO}" = "true" ]; then \
        echo "==> Installing Go v${GO_VERSION}..." && \
        GO_VERSION="${GO_VERSION}" /opt/laragis/languages/go.sh; \
    fi

# Install Node.js with npm/yarn
RUN if [ "${INSTALL_NODEJS}" = "true" ]; then \
        echo "==> Installing Node.js v${NODEJS_VERSION}..." && \
        NODEJS_VERSION="${NODEJS_VERSION}" /opt/laragis/languages/nodejs.sh; \
    fi

# Install PHP with Composer
RUN if [ "${INSTALL_PHP}" = "true" ]; then \
        echo "==> Installing PHP v${PHP_VERSION}..." && \
        PHP_VERSION="${PHP_VERSION}" /opt/laragis/languages/php.sh; \
    fi

# Install Ruby with rbenv and Bundler
RUN if [ "${INSTALL_RUBY}" = "true" ]; then \
        echo "==> Installing Ruby v${RUBY_VERSION}..." && \
        RUBY_VERSION="${RUBY_VERSION}" /opt/laragis/languages/ruby.sh; \
    fi

# Install Python extras (additional packages and tools)
RUN if [ "${INSTALL_PYTHON_EXTRAS}" = "true" ]; then \
        echo "==> Installing Python extras..." && \
        PYTHON_VERSION="${PYTHON_VERSION}" /opt/laragis/languages/python-extras.sh; \
    fi

# =============================================================================
# SYSTEM SERVICES AND SHELL CONFIGURATION
# =============================================================================
# Configure SSH server and modern shell environments

# Copy system setup scripts and dotfiles
COPY resources/prebuildfs/opt/laragis/setup/setup-ssh.sh /opt/laragis/setup/setup-ssh.sh
COPY resources/prebuildfs/opt/laragis/setup/setup-zsh.sh /opt/laragis/setup/setup-zsh.sh
COPY resources/prebuildfs/opt/laragis/setup/setup-bash.sh /opt/laragis/setup/setup-bash.sh
COPY resources/dotfiles/ /opt/laragis/dotfiles/

# Setup SSH server and shell environments (essential components)
RUN echo "==> Setting up SSH server..." && \
    /opt/laragis/setup/setup-ssh.sh && \
    echo "==> Setting up Bash shell..." && \
    /opt/laragis/setup/setup-bash.sh && \
    echo "==> Setting up Zsh shell..." && \
    /opt/laragis/setup/setup-zsh.sh

# =============================================================================
# FINAL SYSTEM CONFIGURATION AND CLEANUP
# =============================================================================
# This section handles final system configuration, security certificates,
# SSH setup, workspace preparation, and image optimization

# -----------------------------------------------------------------------------
# CERTIFICATE MANAGEMENT AND SSH CONFIGURATION
# -----------------------------------------------------------------------------
# Copy custom CA certificates and SSH configuration for secure communications

# Copy custom CA certificates for enterprise environments
COPY resources/ca-certificates/* /usr/local/share/ca-certificates/

# Copy SSH configuration and keys for secure remote access
COPY resources/.ssh ${HOME_DIR}/.ssh

# Copy additional system configuration files and scripts
COPY resources/rootfs /

# Copy development workflow and health check scripts
COPY resources/prebuildfs/opt/laragis/scripts/health-check.sh /opt/laragis/scripts/health-check.sh
COPY resources/prebuildfs/opt/laragis/scripts/dev-workflow.sh /opt/laragis/scripts/dev-workflow.sh

# Create symbolic links for development workflow tools
RUN ln -sf /opt/laragis/scripts/dev-workflow.sh /usr/local/bin/dev-workflow && \
    ln -sf /opt/laragis/scripts/health-check.sh /usr/local/bin/health-check

# -----------------------------------------------------------------------------
# FINAL SYSTEM SETUP AND OPTIMIZATION
# -----------------------------------------------------------------------------
# Execute final configuration steps and optimize image size

RUN echo "==> Executing final system configuration..." && \
    # Update certificate trust store with custom certificates
    update-ca-trust && \
    \
    # Execute post-installation configuration scripts
    echo "==> Running post-installation configuration..." && \
    /opt/laragis/scripts/workspace/postunpack.sh && \
    \
    # Create and configure workspace directories with proper ownership
    echo "==> Setting up workspace directories..." && \
    mkdir -p "${WORKSPACE_DIR}" "${DATA_DIR}" && \
    chown "${USER_UID}:${USER_GID}" "${WORKSPACE_DIR}" "${DATA_DIR}" && \
    chmod 755 "${WORKSPACE_DIR}" "${DATA_DIR}" && \
    \
    # Final cleanup to minimize image size
    echo "==> Performing final cleanup to minimize image size..." && \
    dnf clean all && \
    rm -rf /var/cache/dnf/* /root/.cache/* /tmp/* && \
    echo "==> Final system configuration completed successfully"

# =============================================================================
# CONTAINER RUNTIME CONFIGURATION
# =============================================================================
# Configure network ports, working directory, user context, and startup commands

# -----------------------------------------------------------------------------
# NETWORK PORT CONFIGURATION
# -----------------------------------------------------------------------------
# Expose ports for services that may run within the container
# Port 2222: SSH service (non-standard port for security)
# Port 9001: Supervisor web interface for process management
# Port 80:   HTTP service for web applications
# Port 443:  HTTPS service for secure web applications

EXPOSE 2222 9001 80 443

# -----------------------------------------------------------------------------
# RUNTIME ENVIRONMENT SETUP
# -----------------------------------------------------------------------------
# Set working directory and switch to non-root user for security

# Set working directory for container operations
WORKDIR ${WORKSPACE_DIR}

# Switch to non-root user for security best practices
# All application processes will run under this unprivileged user account
USER ${USER_NAME}

# -----------------------------------------------------------------------------
# CONTAINER STARTUP CONFIGURATION
# -----------------------------------------------------------------------------
# Define entry point and default command for container execution

ENTRYPOINT [ "/opt/laragis/scripts/workspace/entrypoint.sh" ]
CMD [ "/opt/laragis/scripts/workspace/run.sh" ]

# Container health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /opt/laragis/scripts/health-check.sh

# =============================================================================
# BUILD COMPLETE - Oracle Linux 9 Development Container
# =============================================================================
#
# This comprehensive development container provides:
# ✓ Security-hardened configuration with non-root user
# ✓ Comprehensive development tools and language runtimes
# ✓ SSH server with security best practices (port 2222)
# ✓ Process management via Supervisor (web UI on port 9001)
# ✓ Flexible tool installation via build arguments
# ✓ Optimized build process with Docker layer caching
# ✓ Enterprise-ready with custom CA certificate support
#
# Usage Examples:
#   # Interactive development session
#   docker run -it --rm -p 2222:2222 -p 9001:9001 ws-oracle-linux
#
#   # Background development container
#   docker run -d -p 2222:2222 --name dev-container ws-oracle-linux
#
#   # SSH access (after configuring SSH keys)
#   ssh -p 2222 dev@localhost
#
# Build with custom tools:
#   docker build --build-arg INSTALL_TERRAFORM=false .
#
# =============================================================================
