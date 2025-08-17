# -----------------------------------------------------------------------------
# Dev Container: Oracle Linux 9 Development Environment
# -----------------------------------------------------------------------------
ARG ORACLE_LINUX_VERSION=9
FROM oraclelinux:${ORACLE_LINUX_VERSION} AS base

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
ARG HELM_VERSION=3.18.0
ARG K9S_VERSION=0.50.9

# SSH configuration
ARG INSTALL_OPENSSH_SERVER=1
ARG SSH_PORT=22

# Additional tools
ARG INSTALL_CRONTAB=1
ARG INSTALL_NGROK=0
ARG NGROK_VERSION=3.18.4
ARG INSTALL_TAILSCALE=0
ARG TAILSCALE_VERSION=1.84.1
ARG INSTALL_TERRAFORM=1
ARG TERRAFORM_VERSION=1.10.3
ARG INSTALL_CLOUDFLARE=1
ARG CLOUDFLARE_VERSION=2024.12.2
ARG INSTALL_TELEPORT=0
ARG TELEPORT_VERSION=17.1.5
ARG INSTALL_DRY=1
ARG DRY_VERSION=0.11.2
ARG INSTALL_WP_CLI=1
ARG WP_CLI_VERSION=2.12.0
ARG INSTALL_DOCKER=1
ARG DOCKER_VERSION=27.4.1
ARG INSTALL_SUPERVISOR=1
ARG INSTALL_DBEAVER=1
ARG DBEAVER_VERSION=24.3.1

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
# -----------------------------------------------------------------------------
RUN set -eux; \
    dnf -y install --setopt=install_weak_deps=False --nodocs \
        sudo ca-certificates gnupg2 \
        git git-lfs openssh-clients \
        curl wget unzip zip tar xz bzip2 gzip \
        coreutils findutils which rsync jq tree \
        iputils traceroute bind-utils net-tools iproute telnet \
        procps-ng psmisc lsof util-linux util-linux-user ncurses \
        vim bash-completion zsh \
        tmux \
        gcc gcc-c++ make automake autoconf libtool pkgconf-pkg-config; \
    chmod 0440 /etc/sudoers.d/99-${USERNAME}; \
    mkdir -p /home/${USERNAME}/.local/bin; \
    chown -R ${USER_UID}:${USER_GID} /home/${USERNAME}/.local; \
    chmod -R u+rwX /home/${USERNAME}/.local

ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# -----------------------------------------------------------------------------
# Base OS setup & essential packages
# -----------------------------------------------------------------------------
RUN set -eux; \
    dnf -y upgrade; \
    dnf -y install oracle-epel-release-el9 dnf-plugins-core; \
    dnf -y config-manager --enable ol9_developer_EPEL || true; \
    dnf -y install --setopt=install_weak_deps=False --nodocs \
        glibc-langpack-en glibc-langpack-vi tzdata; \
    update-ca-trust

# -----------------------------------------------------------------------------
# Python tools installation (cached layer)
# -----------------------------------------------------------------------------
COPY scripts/install/python-tools.sh /usr/local/scripts/
RUN chmod +x /usr/local/scripts/python-tools.sh && \
    /usr/local/scripts/python-tools.sh

# -----------------------------------------------------------------------------
# Additional packages installation (cached layer)
# -----------------------------------------------------------------------------  
COPY scripts/install/additional-packages.sh /usr/local/scripts/
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
COPY scripts/install/tools/install-task.sh /usr/local/scripts/tools/
RUN chmod +x /usr/local/scripts/tools/install-task.sh && \
    /usr/local/scripts/tools/install-task.sh

# LazyDocker
COPY scripts/install/tools/install-lazydocker.sh /usr/local/scripts/tools/
RUN chmod +x /usr/local/scripts/tools/install-lazydocker.sh && \
    /usr/local/scripts/tools/install-lazydocker.sh

# LazyGit  
COPY scripts/install/tools/install-lazygit.sh /usr/local/scripts/tools/
RUN chmod +x /usr/local/scripts/tools/install-lazygit.sh && \
    /usr/local/scripts/tools/install-lazygit.sh

# YQ YAML processor
COPY scripts/install/tools/install-yq.sh /usr/local/scripts/tools/
RUN chmod +x /usr/local/scripts/tools/install-yq.sh && \
    /usr/local/scripts/tools/install-yq.sh

# -----------------------------------------------------------------------------
# Kubernetes tools (cached layer)
# -----------------------------------------------------------------------------
COPY scripts/install/k8s-tools.sh /usr/local/scripts/
RUN chmod +x /usr/local/scripts/k8s-tools.sh && \
    /usr/local/scripts/k8s-tools.sh

# -----------------------------------------------------------------------------
# Volta (Node.js) installation
# -----------------------------------------------------------------------------
USER ${USERNAME}
RUN set -eux; \
    if [ "${INSTALL_VOLTA}" = "1" ]; then \
        curl -fsSL https://get.volta.sh | bash; \
        export VOLTA_HOME="$HOME/.volta"; \
        export PATH="$VOLTA_HOME/bin:$PATH"; \
        volta install node@lts; \
        volta install npm@latest; \
        npm install -g yarn@latest pnpm@latest; \
    else \
        echo "==> Skipping Volta (Node.js)"; \
    fi
USER root

# -----------------------------------------------------------------------------
# Neovim & LazyVim setup
# -----------------------------------------------------------------------------
RUN set -eux; \
    dnf remove -y neovim && rm -rf /opt/nvim /opt/nvim-linux-x86_64; \
    curl -fL -o "/tmp/nvim-linux-x86_64.tar.gz" \
        https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz; \
    tar -C /opt -xzf "/tmp/nvim-linux-x86_64.tar.gz"; \
    ln -sfn /opt/nvim-linux-x86_64 /opt/nvim; \
    ln -sfn /opt/nvim/bin/nvim /usr/local/bin/nvim; \
    rm -f "/tmp/nvim-linux-x86_64.tar.gz"

USER ${USERNAME}
WORKDIR /home/${USERNAME}

RUN set -eux; \
    python3 -m pip install --no-cache-dir --user pynvim; \
    git clone --depth=1 https://github.com/LazyVim/starter ~/.config/nvim; \
    rm -rf ~/.config/nvim/.git; \
    nvim --headless "+Lazy! sync" +qa || true

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
# Additional tools installation (optimized for cache)
# -----------------------------------------------------------------------------
COPY scripts/install/tools/ /usr/local/scripts/tools/
COPY scripts/install/install-additional-tools.sh /usr/local/scripts/
RUN chmod +x /usr/local/scripts/tools/*.sh /usr/local/scripts/install-additional-tools.sh && \
    /usr/local/scripts/install-additional-tools.sh

# -----------------------------------------------------------------------------
# SSH Server setup
# -----------------------------------------------------------------------------
COPY .ssh/ /tmp/.ssh/
COPY scripts/setup/ /usr/local/scripts/setup/
RUN chmod +x /usr/local/scripts/setup/*.sh && \
    /usr/local/scripts/setup/setup-ssh.sh /tmp/.ssh

# -----------------------------------------------------------------------------
# Docker context setup
# -----------------------------------------------------------------------------
RUN /usr/local/scripts/setup/docker-context.sh

# -----------------------------------------------------------------------------
# Supervisor setup
# -----------------------------------------------------------------------------
RUN if [ "${INSTALL_SUPERVISOR}" = "1" ]; then \
        /usr/local/scripts/setup/setup-supervisor.sh; \
    fi

# -----------------------------------------------------------------------------
# Final setup
# -----------------------------------------------------------------------------
EXPOSE ${SSH_PORT}

RUN mkdir -p /workspace && chown ${USER_UID}:${USER_GID} /workspace

# Clean up
RUN dnf clean all && rm -rf /var/cache/dnf/* /root/.cache/* /tmp/*

# Start command
CMD if [ "${INSTALL_SUPERVISOR:-1}" = "1" ]; then \
        exec /usr/local/bin/start-supervisor; \
    else \
        exec /usr/local/bin/start-sshd; \
    fi
