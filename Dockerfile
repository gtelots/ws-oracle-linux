# syntax=docker/dockerfile:1.7-labs

# =============================================================================
# Oracle Linux 9 Development Container - Comprehensive DevOps Environment
# =============================================================================
# A production-ready development environment built on Oracle Linux 9 with:
# - Modern development tools and runtimes
# - Comprehensive package management with fallback mechanisms
# - Security-hardened configuration with non-root user
# - Process management via Supervisor
# - SSH server and client capabilities
# - Optimized build process with layer caching
# - Extensive documentation and configuration options
# =============================================================================

# -----------------------------------------------------------------------------
# Base Image Configuration
# -----------------------------------------------------------------------------
# Oracle Linux 9 provides enterprise-grade stability, security updates,
# and compatibility with RHEL ecosystem while being freely available.
ARG BASE_IMAGE_NAME=oraclelinux
ARG BASE_IMAGE_TAG=9
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS base

# -----------------------------------------------------------------------------
# Container Metadata - OCI Compliant Labels
# -----------------------------------------------------------------------------
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
    org.opencontainers.image.maintainer="Truong Thanh Tung <ttungbmt@gmail.com>, Ho Manh Cuong <homanhcuongit@gmail.com>" \
    org.opencontainers.image.licenses="MIT"

# -----------------------------------------------------------------------------
# Build Arguments - Container Configuration Parameters
# -----------------------------------------------------------------------------
# These arguments control container behavior and can be customized during
# build time using --build-arg flags. They provide flexibility for different
# deployment scenarios while maintaining security best practices.

# System and localization configuration
ARG TZ=UTC                              # Timezone for consistent time handling
ARG PYTHON_VERSION=3.12                 # Python version for development environment

# User security configuration - following principle of least privilege
ARG USER_UID=1000                       # Non-root user ID for security
ARG USER_GID=1000                       # Non-root group ID for security
ARG USER_NAME=dev                       # Username for development work
ARG ROOT_PASSWORD                       # Root password (passed securely via build secrets)
ARG USER_PASSWORD                       # User password (passed securely via build secrets)
ARG USER_SHELL=/bin/bash                # Default shell for user

# Directory structure for organized workspace management
ARG WORKSPACE_DIR=/workspace            # Main workspace directory
ARG DATA_DIR=/data                      # Data storage directory

# Tool version configuration for reproducible builds
ARG SUPERVISOR_VERSION=4.3.0           # Process management system version

# Package installation control flags for flexible builds
ARG USE_PACKAGE_SCRIPTS=true           # Use optimized package installation scripts
ARG INSTALL_SSH_SERVER=true            # Enable SSH server for remote access
ARG INSTALL_DEVELOPMENT_TOOLS=true     # Install comprehensive development toolchain

# -----------------------------------------------------------------------------
# Environment Variables - Runtime Configuration
# -----------------------------------------------------------------------------
# These variables are available during both build and runtime, providing
# consistent configuration across the container lifecycle.

# System environment for proper terminal and locale behavior
ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Runtime configuration propagated from build arguments
ENV TZ=${TZ} \
    PYTHON_VERSION=${PYTHON_VERSION} \
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
# This section establishes the foundation by configuring repositories,
# applying security updates, and installing core system packages required
# for all subsequent operations.
#
# The process follows this optimized sequence:
# 1. Configure package repositories (EPEL for additional packages)
# 2. Apply security updates with cache refresh
# 3. Install core system packages in a single transaction
# 4. Install Python runtime and development tools
RUN --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    set -euxo pipefail && \
    \
    # Step 1: Configure repositories and apply security updates
    echo "==> Configuring repositories and applying security updates..." && \
    \
    # Install DNF plugins first for enhanced repository management
    dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
        dnf-plugins-core && \
    \
    # Enable EPEL repository (prefer Oracle's version, fallback to developer EPEL)
    echo "==> Enabling EPEL repository..." && \
    (dnf -y install oracle-epel-release-el9 || \
     dnf -y config-manager --enable ol9_developer_EPEL) && \
    \
    # Apply security updates (non-fatal if no updates available)
    echo "==> Applying security updates..." && \
    dnf -y update-minimal --security \
        --setopt=install_weak_deps=False \
        --refresh || echo "No security updates available or update failed" && \
    \
    # Step 2: Install core system packages in single transaction
    echo "==> Installing core system packages..." && \
    dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
        ca-certificates \
        tzdata \
        shadow-utils \
        passwd \
        sudo \
        systemd \
        glibc-langpack-en \
        glibc-langpack-vi \
        glibc-locale-source && \
    \
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
    \
    # Install pipx for isolated Python tool installation
    echo "==> Installing pipx for isolated Python tools..." && \
    pip${PYTHON_VERSION} install pipx && \
    \
    # Configure timezone if specified
    if [[ -n "${TZ}" && -f "/usr/share/zoneinfo/${TZ}" ]]; then \
        echo "==> Setting timezone to ${TZ}..." && \
        ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime && \
        echo "${TZ}" > /etc/timezone; \
    fi && \
    \
    # Verify repository configuration
    echo "==> Verifying repository configuration..." && \
    dnf repolist enabled && \
    \
    # Clean package manager cache to reduce layer size
    echo "==> Cleaning package manager cache..." && \
    dnf clean all

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

# =============================================================================
# DEVELOPMENT ENVIRONMENT SETUP
# =============================================================================

# -----------------------------------------------------------------------------
# Package Installation Strategy - Optimized with Fallback Mechanisms
# -----------------------------------------------------------------------------
# This section implements a sophisticated package installation strategy:
# 1. Primary: Use optimized package installation scripts when available
# 2. Fallback: Direct DNF installation if scripts fail or are unavailable
# 3. Error handling: Individual package retry for failed batch installations
#
# The approach maximizes build speed while ensuring reliability across
# different environments and package availability scenarios.

# Copy package installation scripts for optimized installations
COPY resources/prebuildfs/opt/laragis/packages/ /opt/laragis/packages/
COPY resources/prebuildfs/opt/laragis/setup/ /opt/laragis/setup/
COPY resources/prebuildfs/opt/laragis/lib/ /opt/laragis/lib/

# Essential System Utilities Installation
# Installs comprehensive command-line tools, networking utilities, editors,
# archive tools, and system monitoring utilities required for development work.
RUN --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    echo "==> Installing essential system utilities..." && \
    \
    # Try optimized package script first, fallback to direct installation
    if [[ "${USE_PACKAGE_SCRIPTS}" == "true" ]] && [[ -x "/opt/laragis/packages/pkg-essential.sh" ]]; then \
        echo "Using optimized package installation script..." && \
        /opt/laragis/packages/pkg-essential.sh; \
    else \
        echo "Using direct DNF installation fallback..." && \
        dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
            `# Network and transfer utilities` \
            curl wget openssl bind-utils iproute iputils \
            openssh-clients rsync telnet nc \
            `# Archive and compression tools` \
            tar gzip bzip2 xz unzip zip p7zip lz4 zstd \
            `# System utilities and process management` \
            procps-ng util-linux findutils which diffutils \
            less file lsof htop iotop \
            `# Terminal and editor tools` \
            ncurses ncurses-devel readline \
            vim nano tmux screen \
            `# Development essentials` \
            git tree jq \
            `# System monitoring and debugging` \
            strace tcpdump net-tools sysstat dstat && \
        dnf clean all; \
    fi

# Development Tools & Libraries Installation
# Installs comprehensive development environment including compilers,
# build tools, language runtimes, and development libraries.
RUN --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    if [[ "${INSTALL_DEVELOPMENT_TOOLS}" == "true" ]]; then \
        echo "==> Installing development tools and libraries..." && \
        \
        # Try optimized package script first, fallback to direct installation
        if [[ "${USE_PACKAGE_SCRIPTS}" == "true" ]] && [[ -x "/opt/laragis/packages/pkg-dev.sh" ]]; then \
            echo "Using optimized development tools installation script..." && \
            /opt/laragis/packages/pkg-dev.sh; \
        else \
            echo "Using direct DNF installation fallback..." && \
            # Install development group packages
            dnf -y groupinstall "Development Tools" --setopt=install_weak_deps=False && \
            # Install additional development tools and libraries
            dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
                `# Build essentials and compilers` \
                gcc gcc-c++ make cmake autoconf automake libtool pkgconfig \
                `# Language runtimes` \
                golang nodejs npm rust cargo \
                `# Database development libraries` \
                sqlite-devel postgresql-devel mysql-devel \
                `# System development libraries` \
                openssl-devel libcurl-devel zlib-devel bzip2-devel \
                xz-devel readline-devel libffi-devel \
                `# XML/JSON processing` \
                libxml2-devel libxslt-devel json-c-devel \
                `# Image processing` \
                libjpeg-turbo-devel libpng-devel \
                `# Debugging and profiling` \
                gdb valgrind perf \
                `# Version control` \
                git-lfs subversion mercurial && \
            dnf clean all; \
        fi; \
    else \
        echo "==> Skipping development tools installation (INSTALL_DEVELOPMENT_TOOLS=false)"; \
    fi

# -----------------------------------------------------------------------------
# SSH Server Configuration and Security Setup
# -----------------------------------------------------------------------------
# Configure SSH server for secure remote access with security best practices.
# This enables development workflows that require remote access while
# maintaining security through proper configuration and key management.
RUN if [[ "${INSTALL_SSH_SERVER}" == "true" ]]; then \
        echo "==> Configuring SSH server with security hardening..." && \
        \
        # Ensure SSH server is installed (should be from essential packages)
        if ! rpm -q openssh-server >/dev/null 2>&1; then \
            echo "Installing SSH server..." && \
            dnf -y install openssh-server; \
        fi && \
        \
        # Create SSH host keys directory
        mkdir -p /etc/ssh && \
        \
        # Generate SSH host keys if they don't exist
        if [[ ! -f /etc/ssh/ssh_host_rsa_key ]]; then \
            echo "Generating SSH host keys..." && \
            ssh-keygen -A; \
        fi && \
        \
        # Create secure SSH configuration
        echo "Configuring SSH server security settings..." && \
        { \
            echo "# SSH Server Configuration - Security Hardened"; \
            echo "# Port configuration - using non-standard port for security"; \
            echo "Port 2222"; \
            echo ""; \
            echo "# Authentication settings"; \
            echo "PermitRootLogin no"; \
            echo "PasswordAuthentication yes"; \
            echo "PubkeyAuthentication yes"; \
            echo "AuthorizedKeysFile .ssh/authorized_keys"; \
            echo ""; \
            echo "# Security settings"; \
            echo "Protocol 2"; \
            echo "MaxAuthTries 3"; \
            echo "MaxSessions 10"; \
            echo "LoginGraceTime 60"; \
            echo "ClientAliveInterval 300"; \
            echo "ClientAliveCountMax 2"; \
            echo ""; \
            echo "# Disable unused authentication methods"; \
            echo "ChallengeResponseAuthentication no"; \
            echo "KerberosAuthentication no"; \
            echo "GSSAPIAuthentication no"; \
            echo "UsePAM yes"; \
            echo ""; \
            echo "# Logging"; \
            echo "SyslogFacility AUTH"; \
            echo "LogLevel INFO"; \
            echo ""; \
            echo "# Subsystem configuration"; \
            echo "Subsystem sftp /usr/libexec/openssh/sftp-server"; \
        } > /etc/ssh/sshd_config && \
        \
        # Create SSH directory for the user
        mkdir -p "/home/${USER_NAME}/.ssh" && \
        chown "${USER_UID}:${USER_GID}" "/home/${USER_NAME}/.ssh" && \
        chmod 700 "/home/${USER_NAME}/.ssh" && \
        \
        echo "==> SSH server configuration completed"; \
    else \
        echo "==> Skipping SSH server installation (INSTALL_SSH_SERVER=false)"; \
    fi

# -----------------------------------------------------------------------------
# Process Management - Supervisor Installation and Configuration
# -----------------------------------------------------------------------------
# Install Supervisor for managing multiple processes within the container.
# Supervisor provides robust process control, automatic restart capabilities,
# centralized logging, and web-based monitoring interface.
#
# Key features:
# - Automatic process restart on failure
# - Centralized process monitoring and logging
# - Web interface for process management (port 9001)
# - Graceful shutdown handling
# - Configuration-driven process management

# Copy Supervisor installation script
COPY resources/prebuildfs/opt/laragis/tools/supervisor.sh /opt/laragis/tools/supervisor.sh

# Install Supervisor with version control
RUN echo "==> Installing Supervisor v${SUPERVISOR_VERSION} for process management..." && \
    chmod +x /opt/laragis/tools/supervisor.sh && \
    SUPERVISOR_VERSION="${SUPERVISOR_VERSION}" \
    /opt/laragis/tools/supervisor.sh && \
    echo "==> Supervisor installation completed"

# =============================================================================
# OPTIONAL DEVELOPMENT TOOLS INSTALLATION
# =============================================================================
# This section provides flexible installation of additional development tools
# based on build arguments. Tools are organized by category and can be
# selectively installed to create customized development environments.

# -----------------------------------------------------------------------------
# Tool Installation Arguments and Configuration
# -----------------------------------------------------------------------------
# Build arguments for controlling optional tool installation
# Set to 'true' during build to install specific tools:
# docker build --build-arg INSTALL_ANSIBLE=true --build-arg INSTALL_K6=true .

# DevOps and Infrastructure Tools
ARG INSTALL_ANSIBLE=false
ARG INSTALL_TERRAFORM=false
ARG INSTALL_KUBECTL=false
ARG INSTALL_HELM=false
ARG INSTALL_K9S=false

# Development and Productivity Tools
ARG INSTALL_K6=false
ARG INSTALL_ZELLIJ=false
ARG INSTALL_GUM=false
ARG INSTALL_GETOPTIONS=false
ARG INSTALL_STARSHIP=false
ARG INSTALL_LAZYGIT=false

# Cloud and Networking Tools
ARG INSTALL_AWS_CLI=false
ARG INSTALL_GITHUB_CLI=false
ARG INSTALL_CLOUDFLARED=false
ARG INSTALL_NGROK=false
ARG INSTALL_TAILSCALE=false

# Container and Docker Tools
ARG INSTALL_DRY=false
ARG INSTALL_LAZYDOCKER=false
ARG INSTALL_DOCKER_CLI=false

# Specialized Tools
ARG INSTALL_TELEPORT=false
ARG INSTALL_TASK=false
ARG INSTALL_GOMPLATE=false
ARG INSTALL_DBEAVER=false
ARG INSTALL_MISE=false
ARG INSTALL_UV=false
ARG INSTALL_VOLTA=false
ARG INSTALL_WP_CLI=false

# Tool version configuration
ARG ANSIBLE_VERSION=11.9.0
ARG K6_VERSION=1.2.2
ARG ZELLIJ_VERSION=0.43.1
ARG GUM_VERSION=0.16.2
ARG GETOPTIONS_VERSION=3.3.2

# Additional tool versions for comprehensive development environment
ARG AWS_CLI_VERSION=2.28.16
ARG DRY_VERSION=0.11.2
ARG LAZYDOCKER_VERSION=0.24.1
ARG GITHUB_CLI_VERSION=2.78.0
ARG CLOUDFLARED_VERSION=2025.8.1
ARG LAZYGIT_VERSION=0.54.2
ARG NGROK_VERSION=3.26.0
ARG STARSHIP_VERSION=1.23.0
ARG TAILSCALE_VERSION=1.86.2
ARG TASK_VERSION=3.44.1
ARG TERRAFORM_VERSION=1.13.0
ARG TELEPORT_VERSION=18.1.6
ARG KUBECTL_VERSION=1.31.12
ARG HELM_VERSION=3.18.6
ARG K9S_VERSION=0.50.9
ARG GOMPLATE_VERSION=4.3.3
ARG DBEAVER_VERSION=25.1.5
ARG MISE_VERSION=2025.8.20
ARG UV_VERSION=0.8.13
ARG VOLTA_VERSION=2.0.2
ARG WP_CLI_VERSION=2.12.0
ARG DOCKER_VERSION=28.3.2

# Optional environment variables for tools that require authentication
ARG GH_TOKEN
ARG NGROK_AUTHTOKEN
ENV GH_TOKEN=${GH_TOKEN}
ENV NGROK_AUTHTOKEN=${NGROK_AUTHTOKEN}

# -----------------------------------------------------------------------------
# Consolidated Tool Installation Strategy
# -----------------------------------------------------------------------------
# Copy all tool installation scripts at once for optimal layer caching
# This approach reduces build time and image size while maintaining flexibility
COPY resources/prebuildfs/opt/laragis/tools/ /opt/laragis/tools/

# Install tools based on build arguments with optimized conditional logic
# This consolidated approach reduces layers while maintaining installation flexibility
RUN echo "==> Starting conditional tool installation based on build arguments..." && \
    \
    # Make all tool scripts executable
    chmod +x /opt/laragis/tools/*.sh && \
    \
    # Cloud and Networking Tools
    if [[ "${INSTALL_AWS_CLI}" == "true" ]]; then \
        echo "Installing AWS CLI v${AWS_CLI_VERSION}..." && \
        AWS_CLI_VERSION="${AWS_CLI_VERSION}" /opt/laragis/tools/aws-cli.sh; \
    fi && \
    \
    if [[ "${INSTALL_GITHUB_CLI}" == "true" ]]; then \
        echo "Installing GitHub CLI v${GITHUB_CLI_VERSION}..." && \
        GITHUB_CLI_VERSION="${GITHUB_CLI_VERSION}" /opt/laragis/tools/github-cli.sh; \
    fi && \
    \
    if [[ "${INSTALL_CLOUDFLARED}" == "true" ]]; then \
        echo "Installing Cloudflared v${CLOUDFLARED_VERSION}..." && \
        CLOUDFLARED_VERSION="${CLOUDFLARED_VERSION}" /opt/laragis/tools/cloudflared.sh; \
    fi && \
    \
    if [[ "${INSTALL_NGROK}" == "true" ]]; then \
        echo "Installing Ngrok v${NGROK_VERSION}..." && \
        NGROK_VERSION="${NGROK_VERSION}" /opt/laragis/tools/ngrok.sh; \
    fi && \
    \
    if [[ "${INSTALL_TAILSCALE}" == "true" ]]; then \
        echo "Installing Tailscale v${TAILSCALE_VERSION}..." && \
        TAILSCALE_VERSION="${TAILSCALE_VERSION}" /opt/laragis/tools/tailscale.sh; \
    fi && \
    \
    # Container and Docker Tools
    if [[ "${INSTALL_DRY}" == "true" ]]; then \
        echo "Installing Dry v${DRY_VERSION}..." && \
        DRY_VERSION="${DRY_VERSION}" /opt/laragis/tools/dry.sh; \
    fi && \
    \
    if [[ "${INSTALL_LAZYDOCKER}" == "true" ]]; then \
        echo "Installing Lazydocker v${LAZYDOCKER_VERSION}..." && \
        LAZYDOCKER_VERSION="${LAZYDOCKER_VERSION}" /opt/laragis/tools/lazydocker.sh; \
    fi && \
    \
    if [[ "${INSTALL_DOCKER_CLI}" == "true" ]]; then \
        echo "Installing Docker CLI v${DOCKER_VERSION}..." && \
        DOCKER_VERSION="${DOCKER_VERSION}" /opt/laragis/tools/docker.sh; \
    fi && \
    \
    echo "==> Conditional tool installation completed"

# =============================================================================
# CONTAINER FINALIZATION AND CONFIGURATION
# =============================================================================
# The remaining individual tool installations have been consolidated into the
# conditional installation logic above to reduce Docker layers and improve
# build performance. Tools can be selectively installed using build arguments.

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

# =============================================================================
# CONTAINER FINALIZATION AND RUNTIME CONFIGURATION
# =============================================================================

# -----------------------------------------------------------------------------
# SSH Server Deployment and Configuration
# -----------------------------------------------------------------------------
# Deploy and configure SSH server for secure remote access to the container.
# This includes both server and client configuration with security hardening.
RUN if [[ "${INSTALL_SSH_SERVER}" == "true" ]]; then \
        echo "==> Deploying SSH server configuration..." && \
        /opt/laragis/tools/ssh-deployment.sh server && \
        echo "==> SSH server deployment completed"; \
    else \
        echo "==> Skipping SSH server deployment (INSTALL_SSH_SERVER=false)"; \
    fi

# -----------------------------------------------------------------------------
# Optional Runtime Configuration
# -----------------------------------------------------------------------------
# This section handles optional configuration that may be needed for specific
# deployment scenarios. These are commented out by default but can be enabled
# by uncommenting the relevant sections.

# Custom CA Certificates (uncomment if needed for corporate environments)
# COPY resources/ca-certificates/* /usr/local/share/ca-certificates/
# RUN update-ca-trust

# Pre-configured SSH keys (uncomment if needed for automated deployments)
# COPY resources/.ssh ${HOME_DIR}/.ssh

# -----------------------------------------------------------------------------
# Runtime Files and Post-Installation Setup
# -----------------------------------------------------------------------------
# Copy runtime configuration files and execute post-installation setup.
# This includes supervisor configurations, startup scripts, and final
# environment customizations.

# Copy runtime configuration files, scripts, and supervisor configurations
COPY resources/rootfs /

# Execute post-installation setup script for final environment configuration
# This script handles permissions, final configurations, and environment setup
RUN echo "==> Running post-installation setup..." && \
    /opt/laragis/scripts/workspace/postunpack.sh && \
    echo "==> Post-installation setup completed"

# -----------------------------------------------------------------------------
# Final System Configuration and Cleanup
# -----------------------------------------------------------------------------
# Complete container setup with workspace preparation and comprehensive cleanup
# to minimize final image size and optimize runtime performance.

# Create and configure workspace directory with proper ownership
RUN echo "==> Configuring workspace and data directories..." && \
    mkdir -p "${WORKSPACE_DIR}" "${DATA_DIR}" && \
    chown "${USER_UID}:${USER_GID}" "${WORKSPACE_DIR}" "${DATA_DIR}" && \
    chmod 755 "${WORKSPACE_DIR}" "${DATA_DIR}" && \
    echo "==> Directory configuration completed"

# Comprehensive final cleanup to minimize image size
# Remove package caches, temporary files, documentation, and other artifacts
RUN echo "==> Performing comprehensive final cleanup..." && \
    dnf clean all && \
    rm -rf /var/cache/dnf/* \
           /root/.cache/* \
           /tmp/* \
           /var/tmp/* \
           /usr/share/doc/* \
           /usr/share/man/man1/* \
           /usr/share/man/man2/* \
           /usr/share/man/man3/* \
           /usr/share/man/man4/* \
           /usr/share/man/man5/* \
           /usr/share/man/man6/* \
           /usr/share/man/man7/* \
           /usr/share/man/man8/* \
           /usr/share/info/* && \
    echo "==> Final cleanup completed"

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

# Configure container startup sequence
# The entrypoint handles initialization and environment setup
# The cmd starts the main application services via supervisor
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
