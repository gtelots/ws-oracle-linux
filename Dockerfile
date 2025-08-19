# -----------------------------------------------------------------------------
# Dev Container: Oracle Linux 9 Development Environment
# -----------------------------------------------------------------------------
ARG ORACLE_LINUX_IMAGE=oraclelinux
ARG ORACLE_LINUX_VERSION=9
FROM ${ORACLE_LINUX_IMAGE}:${ORACLE_LINUX_VERSION} AS base

LABEL maintainer="Truong Thanh Tung <ttungbmt@gmail.com>, Ho Manh Cuong <homanhcuongit@gmail.com>"

# -----------------------------------------------------------------------------
# Shell configuration for safer builds
# -----------------------------------------------------------------------------
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# -----------------------------------------------------------------------------
# Build-time args (centralize versions & toggles)
# -----------------------------------------------------------------------------
# Core system configuration
ARG TZ=UTC
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# Modern UI and Development Tools
ARG INSTALL_GUM=1
ARG GUM_VERSION=0.16.2
ARG INSTALL_ZELLIJ=1
ARG ZELLIJ_VERSION=0.43.1
ARG INSTALL_GOMPLATE=0
ARG GOMPLATE_VERSION=v4.3.3
ARG INSTALL_R_LANGUAGE=0
ARG R_VERSION=latest
ARG STARSHIP_VERSION=1.17.1
ARG ZINIT_VERSION=latest

# Core development tools
ARG INSTALL_PYTHON=1
ARG INSTALL_ANSIBLE=1
ARG INSTALL_VOLTA=1
ARG INSTALL_K8S=1

# CLI development tools
ARG INSTALL_TASK=1
ARG INSTALL_LAZYDOCKER=1
ARG INSTALL_LAZYGIT=1
ARG INSTALL_YQ=1

# CLI tools versions
ARG TASK_VERSION=3.44.1
ARG LAZYDOCKER_VERSION=0.24.1
ARG YQ_VERSION=4.47.1
ARG LAZYGIT_VERSION=0.54.2

# Kubernetes tools versions
ARG KUBECTL_VERSION=1.31.12
ARG HELM_VERSION=3.18.5
ARG K9S_VERSION=0.50.9

# SSH configuration
ARG INSTALL_OPENSSH_SERVER=1
ARG SSH_PORT=22

# Additional tools
ARG INSTALL_CRONTAB=1
ARG INSTALL_NGROK=0
ARG NGROK_VERSION=3.26.0
ARG INSTALL_TAILSCALE=0
ARG TAILSCALE_VERSION=1.86.4
ARG INSTALL_TERRAFORM=1
ARG TERRAFORM_VERSION=1.12.2
ARG INSTALL_CLOUDFLARE=1
ARG CLOUDFLARE_VERSION=2025.8.0
ARG INSTALL_TELEPORT=0
ARG TELEPORT_VERSION=18.1.5
ARG INSTALL_DRY=1
ARG DRY_VERSION=0.11.2
ARG INSTALL_WP_CLI=1
ARG WP_CLI_VERSION=2.12.0
ARG INSTALL_DOCKER=1
ARG DOCKER_VERSION=28.3.2
ARG INSTALL_SUPERVISOR=1
ARG INSTALL_DBEAVER=1
ARG DBEAVER_VERSION=25.1.5

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

RUN set -eux; \
    groupadd --gid ${USER_GID} ${USERNAME}; \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME}; \
    echo "root:root" | chpasswd; \
    echo "${USERNAME}:${USERNAME}" | chpasswd; \
    mkdir -p /etc/sudoers.d; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-${USERNAME}; \
    chmod 0440 /etc/sudoers.d/99-${USERNAME}

# -----------------------------------------------------------------------------
# Core development packages (cached layer)
# Install essential development tools and utilities in optimized order:
# - Security & Auth: sudo, ca-certificates, gnupg2
# - Version Control: git, git-lfs, openssh-clients  
# - File Operations: curl, wget, archives (zip, tar, etc.)
# - System Utilities: core GNU tools, process management, networking
# - Text Editors: vim, bash-completion, zsh shell
# - Build Tools: C/C++ compiler toolchain (gcc, make, autotools)
# - User Management: util-linux-user (chsh, chfn commands)
# Note: Modern CLI tools (fzf, ripgrep, etc.) are installed via separate scripts
# -----------------------------------------------------------------------------
RUN set -eux; \
    echo "==> Installing core development packages for containerized environment"; \
    dnf -y install --setopt=install_weak_deps=False --nodocs \
        # Security, certificates & privilege management
        sudo ca-certificates gnupg2 \
        # Version control & SSH connectivity
        git git-lfs openssh-clients \
        # File transfer & archive utilities
        curl wget unzip zip tar xz bzip2 gzip \
        # Core system utilities & search tools
        coreutils findutils which rsync jq tree \
        # Network diagnostics & connectivity tools
        iputils traceroute bind-utils net-tools iproute telnet \
        # Process management & system monitoring
        procps-ng psmisc lsof util-linux util-linux-user ncurses \
        # Text editors & shell environment
        vim bash-completion zsh \
        # C/C++ development toolchain
        gcc gcc-c++ make automake autoconf libtool pkgconf-pkg-config \
        # System log management
        logrotate; \
    # Create user directories and set proper ownership
    chmod 0440 /etc/sudoers.d/99-${USERNAME}; \
    mkdir -p /home/${USERNAME}/.local/bin; \
    chown -R ${USER_UID}:${USER_GID} /home/${USERNAME}/.local; \
    chmod -R u+rwX /home/${USERNAME}/.local

ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# -----------------------------------------------------------------------------
# Base OS setup & essential packages
# Enable EPEL repository for additional packages (fzf, ripgrep, etc.)
# -----------------------------------------------------------------------------
RUN set -eux; \
    echo "==> Upgrading base system and enabling additional repositories"; \
    dnf -y upgrade; \
    dnf -y install oracle-epel-release-el9 dnf-plugins-core; \
    dnf -y config-manager --enable ol9_developer_EPEL || true; \
    echo "==> Installing additional packages from EPEL"; \
    dnf -y install --setopt=install_weak_deps=False --nodocs \
        glibc-langpack-en glibc-langpack-vi tzdata \
        # Modern CLI utilities from EPEL when available
        htop ncdu; \
    update-ca-trust

# -----------------------------------------------------------------------------
# Python tools installation (cached layer)
# -----------------------------------------------------------------------------
COPY scripts/tools/python-tools.sh /usr/local/scripts/
RUN chmod +x /usr/local/scripts/python-tools.sh && \
    /usr/local/scripts/python-tools.sh

# -----------------------------------------------------------------------------
# Additional packages installation (cached layer)
# -----------------------------------------------------------------------------  
COPY scripts/tools/additional-packages.sh /usr/local/scripts/
RUN chmod +x /usr/local/scripts/additional-packages.sh && \
    /usr/local/scripts/additional-packages.sh

# -----------------------------------------------------------------------------
# UV (Python package manager)
# -----------------------------------------------------------------------------
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

# -----------------------------------------------------------------------------
# Individual CLI Tools installation (cached layers)
# -----------------------------------------------------------------------------
# Create tools directory
RUN mkdir -p /usr/local/scripts/tools/

# Task runner
COPY scripts/tools/install-task.sh /usr/local/scripts/tools/
RUN chmod +x /usr/local/scripts/tools/install-task.sh && \
    /usr/local/scripts/tools/install-task.sh

# LazyDocker
COPY scripts/tools/install-lazydocker.sh /usr/local/scripts/tools/
RUN chmod +x /usr/local/scripts/tools/install-lazydocker.sh && \
    /usr/local/scripts/tools/install-lazydocker.sh

# LazyGit  
COPY scripts/tools/install-lazygit.sh /usr/local/scripts/tools/
RUN chmod +x /usr/local/scripts/tools/install-lazygit.sh && \
    /usr/local/scripts/tools/install-lazygit.sh

# YQ YAML processor
COPY scripts/tools/install-yq.sh /usr/local/scripts/tools/
RUN chmod +x /usr/local/scripts/tools/install-yq.sh && \
    /usr/local/scripts/tools/install-yq.sh

# -----------------------------------------------------------------------------
# Kubernetes tools (cached layer)
# -----------------------------------------------------------------------------
COPY scripts/tools/k8s-tools.sh /usr/local/scripts/
RUN chmod +x /usr/local/scripts/k8s-tools.sh && \
    /usr/local/scripts/k8s-tools.sh

# -----------------------------------------------------------------------------
# Shell prompt & dotfiles setup
# -----------------------------------------------------------------------------
# Switch back to root for directory creation
USER root

# Create directories and set permissions first
RUN mkdir -p /usr/local/scripts/setup/ && \
    chmod 755 /usr/local/scripts/setup/

# Copy files
COPY dotfiles/ /tmp/dotfiles/
COPY scripts/setup/setup-shell.sh /usr/local/scripts/setup/
COPY scripts/setup/setup-dotfiles.sh /usr/local/scripts/setup/

# Set permissions as root
RUN chmod +x /usr/local/scripts/setup/setup-shell.sh && \
    chmod +x /usr/local/scripts/setup/setup-dotfiles.sh

# Switch to dev user for shell setup
USER ${USERNAME}
RUN /usr/local/scripts/setup/setup-shell.sh

USER root

# Run dotfiles setup
RUN chmod +x /usr/local/scripts/setup/setup-dotfiles.sh && \
    /usr/local/scripts/setup/setup-dotfiles.sh
USER root

# -----------------------------------------------------------------------------
# Modern tools installation (optimized for Docker cache)
# -----------------------------------------------------------------------------
# Copy common functions first (changes least frequently)
COPY scripts/common/ /usr/local/scripts/common/
RUN chmod +x /usr/local/scripts/common/*.sh

# Copy all modern tool installation scripts at once
COPY scripts/tools/install-gum.sh \
     scripts/tools/install-aws-cli.sh \
     scripts/tools/install-starship.sh \
     scripts/tools/install-zellij.sh \
     scripts/tools/install-gomplate.sh \
     scripts/tools/install-modern-cli.sh \
     /usr/local/scripts/tools/

# Install tools in dependency order (gum first as others use it)
RUN chmod +x /usr/local/scripts/tools/*.sh && \
    /usr/local/scripts/tools/install-gum.sh && \
    if [ "${INSTALL_GOMPLATE}" = "1" ]; then /usr/local/scripts/tools/install-gomplate.sh; fi && \
    /usr/local/scripts/tools/install-aws-cli.sh && \
    /usr/local/scripts/tools/install-starship.sh && \
    /usr/local/scripts/tools/install-zellij.sh && \
    /usr/local/scripts/tools/install-modern-cli.sh

# R Language Support (separated for maintainability)
COPY scripts/tools/install-r-language.sh /usr/local/scripts/tools/
RUN if [ "${INSTALL_R_LANGUAGE}" = "1" ]; then \
        chmod +x /usr/local/scripts/tools/install-r-language.sh && \
        /usr/local/scripts/tools/install-r-language.sh; \
    fi

# -----------------------------------------------------------------------------
# Additional tools installation - optimized for Docker cache
# Each tool is installed in a separate layer to maximize cache efficiency
# Tools are ordered by stability (stable tools first, frequently updated last)
# -----------------------------------------------------------------------------

# Copy base additional tools script (for reference)
COPY scripts/tools/install-additional-tools.sh /usr/local/scripts/

# Stage 1: Infrastructure tools (most stable, rarely change)
COPY scripts/tools/install-crontab.sh /usr/local/scripts/tools/
RUN if [ "${INSTALL_CRONTAB}" = "1" ]; then \
        chmod +x /usr/local/scripts/tools/install-crontab.sh && \
        /usr/local/scripts/tools/install-crontab.sh; \
    else \
        echo "==> Skipping Crontab installation"; \
    fi

COPY scripts/tools/install-supervisor.sh /usr/local/scripts/tools/
RUN if [ "${INSTALL_SUPERVISOR}" = "1" ]; then \
        chmod +x /usr/local/scripts/tools/install-supervisor.sh && \
        /usr/local/scripts/tools/install-supervisor.sh; \
    else \
        echo "==> Skipping Supervisor installation"; \
    fi

# Stage 2: DevOps & Infrastructure tools (moderately stable)
COPY scripts/tools/install-ansible.sh /usr/local/scripts/tools/
RUN if [ "${INSTALL_ANSIBLE}" = "1" ]; then \
        chmod +x /usr/local/scripts/tools/install-ansible.sh && \
        /usr/local/scripts/tools/install-ansible.sh; \
    else \
        echo "==> Skipping Ansible installation"; \
    fi

COPY scripts/tools/install-terraform.sh /usr/local/scripts/tools/
RUN if [ "${INSTALL_TERRAFORM}" = "1" ]; then \
        chmod +x /usr/local/scripts/tools/install-terraform.sh && \
        /usr/local/scripts/tools/install-terraform.sh; \
    else \
        echo "==> Skipping Terraform installation"; \
    fi

COPY scripts/tools/install-cloudflare.sh /usr/local/scripts/tools/
RUN if [ "${INSTALL_CLOUDFLARE}" = "1" ]; then \
        chmod +x /usr/local/scripts/tools/install-cloudflare.sh && \
        /usr/local/scripts/tools/install-cloudflare.sh; \
    else \
        echo "==> Skipping Cloudflare CLI installation"; \
    fi

# Stage 3: Container & system tools (stable versions)
COPY scripts/tools/install-docker.sh /usr/local/scripts/tools/
RUN if [ "${INSTALL_DOCKER}" = "1" ]; then \
        chmod +x /usr/local/scripts/tools/install-docker.sh && \
        /usr/local/scripts/tools/install-docker.sh; \
    else \
        echo "==> Skipping Docker installation"; \
    fi

COPY scripts/tools/install-dry.sh /usr/local/scripts/tools/
RUN if [ "${INSTALL_DRY}" = "1" ]; then \
        chmod +x /usr/local/scripts/tools/install-dry.sh && \
        /usr/local/scripts/tools/install-dry.sh; \
    else \
        echo "==> Skipping Dry installation"; \
    fi

# Stage 4: Web development tools (moderate update frequency)
COPY scripts/tools/install-wp-cli.sh /usr/local/scripts/tools/
RUN if [ "${INSTALL_WP_CLI}" = "1" ]; then \
        chmod +x /usr/local/scripts/tools/install-wp-cli.sh && \
        /usr/local/scripts/tools/install-wp-cli.sh; \
    else \
        echo "==> Skipping WP-CLI installation"; \
    fi

# Stage 5: Network & remote access tools (may update more frequently)
COPY scripts/tools/install-ngrok.sh /usr/local/scripts/tools/
RUN if [ "${INSTALL_NGROK}" = "1" ]; then \
        chmod +x /usr/local/scripts/tools/install-ngrok.sh && \
        /usr/local/scripts/tools/install-ngrok.sh; \
    else \
        echo "==> Skipping Ngrok installation"; \
    fi

COPY scripts/tools/install-tailscale.sh /usr/local/scripts/tools/
RUN if [ "${INSTALL_TAILSCALE}" = "1" ]; then \
        chmod +x /usr/local/scripts/tools/install-tailscale.sh && \
        /usr/local/scripts/tools/install-tailscale.sh; \
    else \
        echo "==> Skipping Tailscale installation"; \
    fi

COPY scripts/tools/install-teleport.sh /usr/local/scripts/tools/
RUN if [ "${INSTALL_TELEPORT}" = "1" ]; then \
        chmod +x /usr/local/scripts/tools/install-teleport.sh && \
        /usr/local/scripts/tools/install-teleport.sh; \
    else \
        echo "==> Skipping Teleport installation"; \
    fi

# Copy any remaining tool scripts for completeness
COPY scripts/tools/ /usr/local/scripts/tools/

# -----------------------------------------------------------------------------
# Volta (Node.js) and Neovim installation via scripts (after common functions)
# -----------------------------------------------------------------------------
RUN if [ "${INSTALL_VOLTA}" = "1" ]; then \
        chmod +x /usr/local/scripts/tools/install-volta.sh && \
        /usr/local/scripts/tools/install-volta.sh; \
    else \
        echo "==> Skipping Volta (Node.js)"; \
    fi

RUN chmod +x /usr/local/scripts/tools/install-neovim.sh && \
    /usr/local/scripts/tools/install-neovim.sh

# -----------------------------------------------------------------------------
# SSH Server setup & additional utilities
# -----------------------------------------------------------------------------
COPY scripts/setup/ /usr/local/scripts/setup/
RUN chmod +x /usr/local/scripts/setup/*.sh && \
    /usr/local/scripts/setup/setup-ssh.sh && \
    # Install hosts manager utility
    cp /usr/local/scripts/setup/hosts-manager.sh /usr/local/bin/ && \
    chmod +x /usr/local/bin/hosts-manager.sh

# -----------------------------------------------------------------------------
# Docker context setup
# -----------------------------------------------------------------------------
RUN /usr/local/scripts/setup/docker-context.sh

# -----------------------------------------------------------------------------
# Supervisor setup (required for production container management)
# -----------------------------------------------------------------------------
RUN /usr/local/scripts/setup/setup-supervisor.sh

# -----------------------------------------------------------------------------
# Copy initialization and startup scripts
# -----------------------------------------------------------------------------
COPY scripts/init/ /usr/local/scripts/init/
COPY scripts/startup/start-container.sh /usr/local/bin/
RUN chmod +x /usr/local/scripts/init/*.sh /usr/local/bin/start-container.sh

# -----------------------------------------------------------------------------
# Final setup and cleanup
# -----------------------------------------------------------------------------
EXPOSE ${SSH_PORT}

RUN mkdir -p /workspace && chown ${USER_UID}:${USER_GID} /workspace

# Clean up package caches and temporary files
RUN dnf clean all && rm -rf /var/cache/dnf/* /root/.cache/* /tmp/*

# -----------------------------------------------------------------------------
# Container startup configuration
# -----------------------------------------------------------------------------
# Set default working directory
WORKDIR /workspace

# Switch to non-root user for security
USER ${USERNAME}

# Container entry point - runs initialization scripts then starts services
CMD ["/usr/local/bin/start-container.sh"]
