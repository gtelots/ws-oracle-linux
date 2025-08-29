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
# ESSENTIAL SYSTEM UTILITIES AND DEVELOPMENT TOOLS
# =============================================================================
# Install comprehensive development environment with system utilities,
# development tools, compilers, and runtime libraries

RUN --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    echo "==> Installing essential system utilities and development tools..." && \
    \
    # Install essential system utilities organized by category
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
    \
    # Install development group packages for comprehensive build environment
    echo "==> Installing Development Tools group..." && \
    dnf -y groupinstall "Development Tools" --setopt=install_weak_deps=False && \
    \
    # Install additional development tools and libraries organized by purpose
    echo "==> Installing additional development libraries and runtimes..." && \
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
        # XML/JSON processing libraries
        libxml2-devel libxslt-devel json-c-devel \
        # Image processing libraries
        libjpeg-turbo-devel libpng-devel \
        # Debugging and profiling tools
        gdb valgrind perf \
        # Version control systems
        git-lfs subversion mercurial && \
    \
    # Clean package manager cache to reduce layer size
    echo "==> Cleaning package manager cache..." && \
    dnf clean all

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

# =============================================================================
# PROCESS MANAGEMENT - SUPERVISOR
# =============================================================================
# Supervisor provides robust process control, automatic restart capabilities,
# centralized logging, and web-based monitoring interface for container services
# Repository: https://github.com/Supervisor/supervisor

ARG SUPERVISOR_VERSION=4.3.0
COPY resources/prebuildfs/opt/laragis/tools/supervisor.sh /opt/laragis/tools/supervisor.sh

RUN if [ "${INSTALL_SUPERVISOR}" = "true" ]; then \
        echo "==> Installing Supervisor v${SUPERVISOR_VERSION}..." && \
        SUPERVISOR_VERSION="${SUPERVISOR_VERSION}" /opt/laragis/tools/supervisor.sh; \
    fi

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
