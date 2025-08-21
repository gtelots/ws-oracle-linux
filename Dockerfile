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
    org.opencontainers.image.authors="Truong Thanh Tung <ttungbmt@gmail.com>, Ho Manh Cuong <homanhcuongit@gmail.com>" \
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

# Add user's local bin to PATH
ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

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
    || dnf -y config-manager --enable ol9_developer_EPEL; \
  \
  ##############################################################################
  # Stage 2: Essential system packages (container-safe core utilities)
  ##############################################################################
  dnf -y install --setopt=install_weak_deps=False --nodocs \
      # User management & security
      shadow-utils sudo \
      # Core file & system utilities
      coreutils findutils which procps-ng util-linux util-linux-user \
      # Archive & compression tools
      tar xz gzip bzip2 unzip zip \
      # Network utilities (essential for containers)
      curl wget rsync iproute iputils \
      # Locale support (English + Vietnamese)
      glibc-langpack-en glibc-langpack-vi; \
  \
  ##############################################################################
  # Stage 3: Development essentials (install after EPEL is enabled)
  ##############################################################################
  dnf -y install --setopt=install_weak_deps=False --nodocs \
      # Security & cryptography
      gnupg2 openssl ca-certificates \
      # Version control & SSH
      git git-lfs openssh-clients \
      # Text processing & search tools
      grep sed gawk diffutils patch file less tree jq \
      # Network diagnostics & tools
      bind-utils net-tools traceroute nmap-ncat socat \
      # Process management & monitoring
      psmisc lsof htop \
      # Shell & editor environment
      vim nano bash-completion zsh man-pages \
      # C/C++ development toolchain
      gcc gcc-c++ make automake autoconf libtool pkgconf-pkg-config \
      # Modern build systems
      cmake ninja-build \
      # Debugging tools (essential for development)
      gdb strace; \
  \
  ##############################################################################
  # Final cleanup to minimize image size
  ##############################################################################
  dnf clean all; \
  rm -rf /var/cache/dnf/* /var/tmp/* /tmp/*; \
  # Create essential directories
  mkdir -p /usr/local/scripts/tools /usr/local/scripts/setup;

# -----------------------------------------------------------------------------
# Core development packages using enhanced pkg-install tool
# Organized package installation with groups for better maintainability
# -----------------------------------------------------------------------------

# Core Security & Networking (essential for all operations)
RUN pkg-install --group "Security & Networking" \
    ca-certificates gnupg2 openssl \
    curl wget rsync openssh-clients

# Version Control & Development
RUN pkg-install --group "Version Control" \
    git git-lfs

# File Operations & Archives  
RUN pkg-install --group "File Operations" \
    zip unzip tar gzip bzip2 xz

# System Utilities
RUN pkg-install --group "System Utilities" \
    tree which findutils \
    procps-ng psmisc lsof htop

# Text Editors & Shell
RUN pkg-install --group "Text & Shell" \
    vim nano bash-completion zsh \
    less man-pages

# Build Tools & Compilers
RUN pkg-install --group "Build Tools" \
    gcc gcc-c++ make cmake autoconf automake \
    libtool pkgconfig ninja-build

# Network & Debugging Tools
RUN pkg-install --group "Network & Debug" \
    bind-utils net-tools traceroute nmap-ncat socat \
    gdb strace

# User Management Tools
RUN pkg-install util-linux-user

# Python Development (if enabled)
RUN if [ "${INSTALL_PYTHON:-1}" = "1" ]; then \
        pkg-install --group "Python Development" \
            python3 python3-pip python3-setuptools \
            python3-devel; \
    fi

# # -----------------------------------------------------------------------------
# # Development Tools Installation
# # -----------------------------------------------------------------------------

# # DBeaver Database Tool (if enabled)
# COPY scripts/tools/install-dbeaver.sh /usr/local/scripts/tools/
# RUN if [ "${INSTALL_DBEAVER:-1}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-dbeaver.sh && \
#         DBEAVER_VERSION=${DBEAVER_VERSION} \
#         /usr/local/scripts/tools/install-dbeaver.sh; \
#     fi
# #     echo "==> Installing core development packages for containerized environment"; \
# #     dnf -y install --setopt=install_weak_deps=False --nodocs \
# #         # Security, certificates & privilege management
# #         sudo ca-certificates gnupg2 \
# #         # Version control & SSH connectivity
# #         git git-lfs openssh-clients \
# #         # File transfer & archive utilities
# #         curl wget unzip zip tar xz bzip2 gzip \
# #         # Core system utilities & search tools
# #         coreutils findutils which rsync jq tree \
# #         # Network diagnostics & connectivity tools
# #         iputils traceroute bind-utils net-tools iproute telnet \
# #         # Process management & system monitoring
# #         procps-ng psmisc lsof util-linux util-linux-user ncurses \
# #         # Text editors & shell environment
# #         vim bash-completion zsh \
# #         # C/C++ development toolchain
# #         gcc gcc-c++ make automake autoconf libtool pkgconf-pkg-config \
# #         # System log management
# #         logrotate; \
# #     # Create user directories and set proper ownership
# #     chmod 0440 /etc/sudoers.d/99-${USERNAME}; \
# #     mkdir -p /home/${USERNAME}/.local/bin; \
# #     chown -R ${USER_UID}:${USER_GID} /home/${USERNAME}/.local; \
# #     chmod -R u+rwX /home/${USERNAME}/.local

# # ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"



# # -----------------------------------------------------------------------------
# # Python tools installation (cached layer)
# # -----------------------------------------------------------------------------
# COPY scripts/tools/python-tools.sh /usr/local/scripts/
# RUN chmod +x /usr/local/scripts/python-tools.sh && \
#     /usr/local/scripts/python-tools.sh

# # -----------------------------------------------------------------------------
# # Additional packages installation (cached layer)
# # -----------------------------------------------------------------------------  
# COPY scripts/tools/additional-packages.sh /usr/local/scripts/
# RUN chmod +x /usr/local/scripts/additional-packages.sh && \
#     /usr/local/scripts/additional-packages.sh

# # -----------------------------------------------------------------------------
# # UV (Python package manager)
# # -----------------------------------------------------------------------------
# COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
# ENV UV_COMPILE_BYTECODE=1 \
#     UV_LINK_MODE=copy

# # -----------------------------------------------------------------------------
# # Individual CLI Tools installation (cached layers)
# # -----------------------------------------------------------------------------
# # Create tools directory
# RUN mkdir -p /usr/local/scripts/tools/

# # Task runner
# COPY scripts/tools/install-task.sh /usr/local/scripts/tools/
# RUN chmod +x /usr/local/scripts/tools/install-task.sh && \
#     /usr/local/scripts/tools/install-task.sh

# # LazyDocker
# COPY scripts/tools/install-lazydocker.sh /usr/local/scripts/tools/
# RUN chmod +x /usr/local/scripts/tools/install-lazydocker.sh && \
#     /usr/local/scripts/tools/install-lazydocker.sh

# # LazyGit  
# COPY scripts/tools/install-lazygit.sh /usr/local/scripts/tools/
# RUN chmod +x /usr/local/scripts/tools/install-lazygit.sh && \
#     /usr/local/scripts/tools/install-lazygit.sh

# # YQ YAML processor
# COPY scripts/tools/install-yq.sh /usr/local/scripts/tools/
# RUN chmod +x /usr/local/scripts/tools/install-yq.sh && \
#     /usr/local/scripts/tools/install-yq.sh

# # -----------------------------------------------------------------------------
# # Kubernetes tools (cached layer)
# # -----------------------------------------------------------------------------
# COPY scripts/tools/k8s-tools.sh /usr/local/scripts/
# RUN chmod +x /usr/local/scripts/k8s-tools.sh && \
#     /usr/local/scripts/k8s-tools.sh

# # -----------------------------------------------------------------------------
# # Shell prompt & dotfiles setup
# # -----------------------------------------------------------------------------
# # Switch back to root for directory creation
# USER root

# # Create directories and set permissions first
# RUN mkdir -p /usr/local/scripts/setup/ && \
#     chmod 755 /usr/local/scripts/setup/

# # Copy files
# COPY dotfiles/ /tmp/dotfiles/
# COPY scripts/setup/setup-shell.sh /usr/local/scripts/setup/
# COPY scripts/setup/setup-dotfiles.sh /usr/local/scripts/setup/

# # Set permissions as root
# RUN chmod +x /usr/local/scripts/setup/setup-shell.sh && \
#     chmod +x /usr/local/scripts/setup/setup-dotfiles.sh

# # Switch to dev user for shell setup
# USER ${USERNAME}
# RUN /usr/local/scripts/setup/setup-shell.sh

# USER root

# # Run dotfiles setup
# RUN chmod +x /usr/local/scripts/setup/setup-dotfiles.sh && \
#     /usr/local/scripts/setup/setup-dotfiles.sh
# USER root

# # -----------------------------------------------------------------------------
# # Modern tools installation (optimized for Docker cache)
# # -----------------------------------------------------------------------------
# # Copy common functions first (changes least frequently)
# COPY scripts/common/ /usr/local/scripts/common/
# RUN chmod +x /usr/local/scripts/common/*.sh

# # Copy all modern tool installation scripts at once
# COPY scripts/tools/install-gum.sh \
#      scripts/tools/install-aws-cli.sh \
#      scripts/tools/install-starship.sh \
#      scripts/tools/install-zellij.sh \
#      scripts/tools/install-gomplate.sh \
#      scripts/tools/install-modern-cli.sh \
#      /usr/local/scripts/tools/

# # Install tools in dependency order (gum first as others use it)
# RUN chmod +x /usr/local/scripts/tools/*.sh && \
#     /usr/local/scripts/tools/install-gum.sh && \
#     if [ "${INSTALL_GOMPLATE}" = "1" ]; then /usr/local/scripts/tools/install-gomplate.sh; fi && \
#     /usr/local/scripts/tools/install-aws-cli.sh && \
#     /usr/local/scripts/tools/install-starship.sh && \
#     /usr/local/scripts/tools/install-zellij.sh && \
#     /usr/local/scripts/tools/install-modern-cli.sh

# # R Language Support (separated for maintainability)
# COPY scripts/tools/install-r-language.sh /usr/local/scripts/tools/
# RUN if [ "${INSTALL_R_LANGUAGE}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-r-language.sh && \
#         /usr/local/scripts/tools/install-r-language.sh; \
#     fi

# # -----------------------------------------------------------------------------
# # Additional tools installation - optimized for Docker cache
# # Each tool is installed in a separate layer to maximize cache efficiency
# # Tools are ordered by stability (stable tools first, frequently updated last)
# # -----------------------------------------------------------------------------

# # Copy base additional tools script (for reference)
# COPY scripts/tools/install-additional-tools.sh /usr/local/scripts/

# # Stage 1: Infrastructure tools (most stable, rarely change)
# COPY scripts/tools/install-crontab.sh /usr/local/scripts/tools/
# RUN if [ "${INSTALL_CRONTAB}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-crontab.sh && \
#         /usr/local/scripts/tools/install-crontab.sh; \
#     else \
#         echo "==> Skipping Crontab installation"; \
#     fi

# COPY scripts/tools/install-supervisor.sh /usr/local/scripts/tools/
# RUN if [ "${INSTALL_SUPERVISOR}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-supervisor.sh && \
#         /usr/local/scripts/tools/install-supervisor.sh; \
#     else \
#         echo "==> Skipping Supervisor installation"; \
#     fi

# # Stage 2: DevOps & Infrastructure tools (moderately stable)
# COPY scripts/tools/install-ansible.sh /usr/local/scripts/tools/
# RUN if [ "${INSTALL_ANSIBLE}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-ansible.sh && \
#         /usr/local/scripts/tools/install-ansible.sh; \
#     else \
#         echo "==> Skipping Ansible installation"; \
#     fi

# COPY scripts/tools/install-terraform.sh /usr/local/scripts/tools/
# RUN if [ "${INSTALL_TERRAFORM}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-terraform.sh && \
#         /usr/local/scripts/tools/install-terraform.sh; \
#     else \
#         echo "==> Skipping Terraform installation"; \
#     fi

# COPY scripts/tools/install-cloudflare.sh /usr/local/scripts/tools/
# RUN if [ "${INSTALL_CLOUDFLARE}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-cloudflare.sh && \
#         /usr/local/scripts/tools/install-cloudflare.sh; \
#     else \
#         echo "==> Skipping Cloudflare CLI installation"; \
#     fi

# # Stage 3: Container & system tools (stable versions)
# COPY scripts/tools/install-docker.sh /usr/local/scripts/tools/
# RUN if [ "${INSTALL_DOCKER}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-docker.sh && \
#         /usr/local/scripts/tools/install-docker.sh; \
#     else \
#         echo "==> Skipping Docker installation"; \
#     fi

# COPY scripts/tools/install-dry.sh /usr/local/scripts/tools/
# RUN if [ "${INSTALL_DRY}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-dry.sh && \
#         /usr/local/scripts/tools/install-dry.sh; \
#     else \
#         echo "==> Skipping Dry installation"; \
#     fi

# # Stage 4: Web development tools (moderate update frequency)
# COPY scripts/tools/install-wp-cli.sh /usr/local/scripts/tools/
# RUN if [ "${INSTALL_WP_CLI}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-wp-cli.sh && \
#         /usr/local/scripts/tools/install-wp-cli.sh; \
#     else \
#         echo "==> Skipping WP-CLI installation"; \
#     fi

# # Stage 5: Network & remote access tools (may update more frequently)
# COPY scripts/tools/install-ngrok.sh /usr/local/scripts/tools/
# RUN if [ "${INSTALL_NGROK}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-ngrok.sh && \
#         /usr/local/scripts/tools/install-ngrok.sh; \
#     else \
#         echo "==> Skipping Ngrok installation"; \
#     fi

# COPY scripts/tools/install-tailscale.sh /usr/local/scripts/tools/
# RUN if [ "${INSTALL_TAILSCALE}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-tailscale.sh && \
#         /usr/local/scripts/tools/install-tailscale.sh; \
#     else \
#         echo "==> Skipping Tailscale installation"; \
#     fi

# COPY scripts/tools/install-teleport.sh /usr/local/scripts/tools/
# RUN if [ "${INSTALL_TELEPORT}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-teleport.sh && \
#         /usr/local/scripts/tools/install-teleport.sh; \
#     else \
#         echo "==> Skipping Teleport installation"; \
#     fi

# # Copy any remaining tool scripts for completeness
# COPY scripts/tools/ /usr/local/scripts/tools/

# # -----------------------------------------------------------------------------
# # Volta (Node.js) and Neovim installation via scripts (after common functions)
# # -----------------------------------------------------------------------------
# RUN if [ "${INSTALL_VOLTA}" = "1" ]; then \
#         chmod +x /usr/local/scripts/tools/install-volta.sh && \
#         /usr/local/scripts/tools/install-volta.sh; \
#     else \
#         echo "==> Skipping Volta (Node.js)"; \
#     fi

# RUN chmod +x /usr/local/scripts/tools/install-neovim.sh && \
#     /usr/local/scripts/tools/install-neovim.sh

# # -----------------------------------------------------------------------------
# # SSH Server setup & additional utilities
# # -----------------------------------------------------------------------------
# COPY scripts/setup/ /usr/local/scripts/setup/
# RUN chmod +x /usr/local/scripts/setup/*.sh && \
#     /usr/local/scripts/setup/setup-ssh.sh && \
#     # Install hosts manager utility
#     cp /usr/local/scripts/setup/hosts-manager.sh /usr/local/bin/ && \
#     chmod +x /usr/local/bin/hosts-manager.sh

# # -----------------------------------------------------------------------------
# # Docker context setup
# # -----------------------------------------------------------------------------
# RUN /usr/local/scripts/setup/docker-context.sh

# # -----------------------------------------------------------------------------
# # Supervisor setup (required for production container management)
# # -----------------------------------------------------------------------------
# RUN /usr/local/scripts/setup/setup-supervisor.sh

# # -----------------------------------------------------------------------------
# # Copy initialization and startup scripts
# # -----------------------------------------------------------------------------
# COPY scripts/init/ /usr/local/scripts/init/
# COPY scripts/startup/start-container.sh /usr/local/bin/
# RUN chmod +x /usr/local/scripts/init/*.sh /usr/local/bin/start-container.sh

# # -----------------------------------------------------------------------------
# # Final setup and cleanup
# # -----------------------------------------------------------------------------
# EXPOSE ${SSH_PORT}

# RUN mkdir -p /workspace && chown ${USER_UID}:${USER_GID} /workspace

# # Clean up package caches and temporary files
# RUN dnf clean all && rm -rf /var/cache/dnf/* /root/.cache/* /tmp/*

# # -----------------------------------------------------------------------------
# # Container startup configuration
# # -----------------------------------------------------------------------------
# # Set default working directory
# WORKDIR /workspace

# # Switch to non-root user for security
# USER ${USERNAME}

# # Container entry point - runs initialization scripts then starts services
# CMD ["/usr/local/bin/start-container.sh"]
CMD [ "bash", "-lc", "sleep infinity" ]