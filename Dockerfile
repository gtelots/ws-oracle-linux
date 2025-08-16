# -----------------------------------------------------------------------------
# Dev Container: Oracle Linux 9 (rolling minor)
# -----------------------------------------------------------------------------
ARG ORACLE_LINUX_VERSION=9
FROM oraclelinux:${ORACLE_LINUX_VERSION} AS base

LABEL io.workspace.image.authors="Truong Thanh Tung <ttungbmt@gmail.com"
LABEL maintainer="Truong Thanh Tung <ttungbmt@gmail.com>, Ho Manh Cuong <homanhcuongit@gmail.com>"

# -----------------------------------------------------------------------------
# Shell configuration for safer builds
# -----------------------------------------------------------------------------
# Use bash with pipefail option to catch errors in piped commands
# This ensures that if any command in a pipeline fails, the entire RUN instruction fails
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# -----------------------------------------------------------------------------
# Build-time args (centralize versions & toggles)
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Set locales & timezone
# -----------------------------------------------------------------------------
# Set UTF-8 locale for proper character encoding
ENV LANG=en_US.UTF-8 \
  LC_ALL=en_US.UTF-8
  
# Default timezone (can be overridden at build time)
ARG TZ=Asia/Ho_Chi_Minh
ENV TZ=${TZ}

# Configure system timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# -----------------------------------------------------------------------------
# Create a non-root user with passwordless sudo
# -----------------------------------------------------------------------------
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

USER root

RUN set -eux; \
  # Create group if not exists
  groupadd --gid ${USER_GID} ${USERNAME}; \
  # Create user with home directory and bash shell
  useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME}; \
  # Set default passwords (change after build for security)
  echo "root:root" | chpasswd; \
  echo "${USERNAME}:${USERNAME}" | chpasswd; \
  # Configure passwordless sudo for the user
  mkdir -p /etc/sudoers.d; \
  echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-${USERNAME}; \
  chmod 0440 /etc/sudoers.d/99-${USERNAME}; \
  # Prepare per-user directories (ensure writable by user)
  mkdir -p /home/${USERNAME}/.local/bin; \
  chown -R ${USER_UID}:${USER_GID} /home/${USERNAME}/.local; \
  chmod -R u+rwX /home/${USERNAME}/.local

# Add user local bin to PATH (simple fix for all future layers)
ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# -----------------------------------------------------------------------------
# Base OS setup: package repositories, system updates, and essential packages
# -----------------------------------------------------------------------------
RUN set -eux; \
  # Update all existing packages to latest versions
  dnf -y upgrade; \
  # Install Oracle EPEL repository for additional packages
  dnf -y install oracle-epel-release-el9 dnf-plugins-core; \
  # Enable Oracle Developer EPEL repository (ignore if already enabled)
  dnf -y config-manager --enable ol9_developer_EPEL || true; \
  # Install essential system packages with minimal dependencies
  dnf -y install --setopt=install_weak_deps=False --nodocs \
    # English language pack for proper locale support
    glibc-langpack-en \    
    # Vietnamese language pack for locale support
    glibc-langpack-vi \    
    # Timezone data for accurate time handling
    tzdata; \
  # Update system certificate authority trust store
  update-ca-trust;

# -----------------------------------------------------------------------------
# Core system & dev tools (optimized). Toggle optional stacks via ARGs below.
# -----------------------------------------------------------------------------
      

RUN set -eux; \
  echo "==> Installing minimal system packages for development"; \
  EXTRA_PKGS=""; \
  dnf -y install --setopt=install_weak_deps=False --nodocs \
    # Privilege & certificates / crypto
    sudo ca-certificates gnupg2 \
    # VCS + SSH
    git git-lfs openssh-clients \
    # File transfer & archives
    curl wget unzip zip tar xz bzip2 gzip \
    # Core utilities
    coreutils findutils which rsync jq tree \
    # Networking & diagnostics
    iputils traceroute bind-utils net-tools iproute \
    # Process & system
    procps-ng psmisc lsof util-linux ncurses \
    # Editors & shells
    vim neovim bash-completion zsh \
    # TUI helpers
    htop ncdu tmux \
    # C/C++ build toolchain
    gcc gcc-c++ make automake autoconf libtool pkgconf-pkg-config \
    # Modern CLI utilities
    fzf ripgrep fd-find bat eza \
    ${EXTRA_PKGS}; \
  \
  # Normalize command names across distros
  command -v fdfind  >/dev/null 2>&1 && ln -sf "$(command -v fdfind)"  /usr/local/bin/fd  || true; \
  command -v batcat  >/dev/null 2>&1 && ln -sf "$(command -v batcat)"  /usr/local/bin/bat || true

# -----------------------------------------------------------------------------
# Install Python
# -----------------------------------------------------------------------------
ARG INSTALL_PYTHON=1

RUN set -eux; \
  if [ "${INSTALL_PYTHON}" = "1" ]; then \
    dnf -y install --setopt=install_weak_deps=False --nodocs \
      python3.11 python3.11-pip python3.11-devel; \
    ln -sf /usr/bin/python3.11 /usr/local/bin/python3; \
    ln -sf /usr/bin/python3.11 /usr/local/bin/python; \
    ln -sf /usr/bin/pip3.11 /usr/local/bin/pip3; \
    # Upgrade pip, setuptools, and wheel
    python3.11 -m pip install --no-cache-dir -U pip setuptools wheel; \
  else \
    echo "==> Skipping Python"; \
  fi

# -----------------------------------------------------------------------------
# Install essential Python packages for non-root user
# -----------------------------------------------------------------------------
USER ${USERNAME}

RUN set -eux; \
  if [ "${INSTALL_PYTHON}" = "1" ]; then \
    python3.11 -m pip install --no-cache-dir --user \
      # Project templating
      cookiecutter \
      # Enhanced interactive Python shell
      ipython \
      # Python dependency management and packaging
      poetry \
      # Git hooks framework for code quality
      pre-commit \
      # Virtual environment management
      virtualenv \
      pipenv \
      # Modern CLI framework built on Click
      typer; \
  fi

USER root

# -----------------------------------------------------------------------------
# Install Ansible
# -----------------------------------------------------------------------------
ARG INSTALL_ANSIBLE=1

USER ${USERNAME}

RUN set -eux; \
  if [ "${INSTALL_ANSIBLE}" = "1" ] && [ "${INSTALL_PYTHON}" = "1" ]; then \
    python3.11 -m pip install --no-cache-dir --user \
      # Infrastructure automation and configuration management
      ansible \
      ansible-lint; \
  else \
    echo "==> Skipping Ansible"; \
  fi

USER root

# -----------------------------------------------------------------------------
# Install uv (Python package manager)
# -----------------------------------------------------------------------------
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Configure uv (Python package manager) optimization settings
# Enable bytecode compilation for faster Python module loading
ENV UV_COMPILE_BYTECODE=1
# Use copy mode instead of hard links for package installation
ENV UV_LINK_MODE=copy

# -----------------------------------------------------------------------------
# Install Volta (Node.js version manager)
# -----------------------------------------------------------------------------
ARG INSTALL_VOLTA=1

USER ${USERNAME}

RUN set -eux; \
  if [ "${INSTALL_VOLTA}" = "1" ]; then \
    # Install Volta - modern Node.js version manager
    curl -fsSL https://get.volta.sh | bash; \
    # Activate Volta in current session and install latest LTS Node.js
    export VOLTA_HOME="$HOME/.volta"; \
    export PATH="$VOLTA_HOME/bin:$PATH"; \
    volta install node@lts; \
    volta install npm@latest; \
    # Install global package managers
    npm install -g yarn@latest pnpm@latest; \
  else \
    echo "==> Skipping Volta (Node.js)"; \
  fi

# # Verify Volta installation (using login shell to load user environment)
# RUN bash -l -c 'node -v'

USER root

# -----------------------------------------------------------------------------
# Install standalone CLIs (task, lazydocker, yq, lazygit)
# -----------------------------------------------------------------------------
ARG TASK_VERSION=3.44.1
ARG LAZYDOCKER_VERSION=0.24.1
ARG YQ_VERSION=4.47.1
ARG LAZYGIT_VERSION=0.54.2

RUN set -eux; \
  # go-task
  curl -fsSL -o /tmp/task.tgz "https://github.com/go-task/task/releases/download/v${TASK_VERSION}/task_linux_amd64.tar.gz"; \
  tar -xzf /tmp/task.tgz -C /usr/local/bin task; rm -f /tmp/task.tgz; \
  # lazydocker
  curl -fsSL -o /tmp/lazydocker.tgz "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"; \
  tar -xzf /tmp/lazydocker.tgz -C /usr/local/bin lazydocker; rm -f /tmp/lazydocker.tgz; \
  # yq
  curl -fsSL -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"; \
  chmod +x /usr/local/bin/yq; \
  # lazygit
  curl -fsSL -o /tmp/lazygit.tgz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"; \
  tar -xzf /tmp/lazygit.tgz -C /usr/local/bin lazygit; rm -f /tmp/lazygit.tgz

# -----------------------------------------------------------------------------
# Optional: kubectl + helm + k9s (controlled by INSTALL_K8S)
# -----------------------------------------------------------------------------
ARG INSTALL_K8S=1

ARG KUBECTL_VERSION=1.31.12
ARG HELM_VERSION=3.18.0
ARG K9S_VERSION=0.50.9

RUN set -eux; \
  if [ "${INSTALL_K8S}" = "1" ]; then \
    # kubectl
    curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl"; \
    chmod +x /usr/local/bin/kubectl; \
    # helm
    curl -fsSL -o /tmp/helm.tgz "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz"; \
    tar -xzf /tmp/helm.tgz -C /tmp; \
    mv /tmp/linux-amd64/helm /usr/local/bin/helm; chmod +x /usr/local/bin/helm; rm -rf /tmp/helm.tgz /tmp/linux-*; \
    # k9s (ARM64)
    curl -fsSL -o /tmp/k9s.tgz "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_arm64.tar.gz"; \
    tar -xzf /tmp/k9s.tgz -C /usr/local/bin k9s; rm -f /tmp/k9s.tgz; \
  else \
    echo "==> Skipping Kubernetes tools"; \
  fi

# # -----------------------------------------------------------------------------
# LazyVim setup (for the non-root user)
# -----------------------------------------------------------------------------
USER ${USERNAME}
WORKDIR /home/${USERNAME}

RUN set -eux; \
    python3 -m pip install --no-cache-dir --user pynvim; \
    git clone --depth=1 https://github.com/LazyVim/starter ~/.config/nvim; \
    rm -rf ~/.config/nvim/.git
    # nvim --headless "+Lazy! sync" +qa || true

USER root

# # -----------------------------------------------------------------------------
# # Shell prompt & dotfiles (minimal, fast)
# # -----------------------------------------------------------------------------
# RUN set -eux; \
#     curl -fsSL https://starship.rs/install.sh | sh -s -- -y; \
#     { \
#       echo 'export PATH="$HOME/.local/bin:$PATH"'; \
#       echo 'eval "$(starship init zsh)"'; \
#       echo 'alias ll="eza -lha --group-directories-first"'; \
#       echo 'alias cat="bat --paging=never"'; \
#       echo 'alias vi="nvim"'; \
#       echo 'alias vim="nvim"'; \
#       echo '[[ -f /usr/share/fzf/shell/key-bindings.zsh ]] && source /usr/share/fzf/shell/key-bindings.zsh'; \
#     } >> ~/.zshrc

# # -----------------------------------------------------------------------------
# # Workspace and cleanup
# # -----------------------------------------------------------------------------
# USER root
# RUN mkdir -p /workspace && chown ${USER_UID}:${USER_GID} /workspace; \
#     dnf clean all; rm -rf /var/cache/dnf/* /root/.cache/*

USER ${USERNAME}
CMD ["/bin/bash"]


# ---- System packages -------------------------------------------------

# RUN dnf -y update && \
#     dnf -y install \
#       sudo ca-certificates gnupg2 \
#       git git-lfs openssh-clients \
#       curl wget unzip zip tar xz bzip2 gzip \
#       jq which tree rsync \
#       iputils telnet traceroute bind-utils net-tools \
#       procps-ng psmisc lsof util-linux \
#       ncurses \
#       vim nano less \
#       zsh bash-completion \
#       make gcc gcc-c++ automake autoconf libtool pkgconf-pkg-config \
#       python3 python3-pip python3-virtualenv python3-devel \
#       golang \
#       java-17-openjdk java-17-openjdk-devel \
#       tmux && \
#     dnf -y module enable nodejs:20 && \
#     dnf -y install nodejs && \
#     dnf clean all && rm -rf /var/cache/dnf

# # ---- Global npm CLIs -------------------------------------------------
# RUN npm -g install yarn pnpm

# # ---- Python toolchain via pipx --------------------------------------
# ARG PIPX_HOME=/opt/pipx
# ENV PIPX_HOME=${PIPX_HOME} PIPX_BIN_DIR=/usr/local/bin PATH=${PIPX_BIN_DIR}:$PATH
# RUN python3 -m pip install --no-cache-dir -U pip setuptools wheel pipx && \
#     pipx ensurepath && \
#     pipx install "ansible" && \
#     pipx install "ansible-lint" && \
#     pipx install "pre-commit" && \
#     pipx install "poetry" && \
#     pipx install "pipenv"

# # ---- Taskfile (go-task) ---------------------------------------------
# ARG TASK_VERSION=3.40.0
# RUN curl -fsSL "https://github.com/go-task/task/releases/download/v${TASK_VERSION}/task_linux_amd64.tar.gz" \
#   | tar -xz -C /usr/local/bin task && chmod +x /usr/local/bin/task

# # ---- yq (YAML processor) --------------------------------------------
# ARG YQ_VERSION=4.44.3
# RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" \
#   -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# # ---- kubectl & Helm (optional but handy) ----------------------------
# ARG KUBECTL_VERSION=1.30.4
# ARG HELM_VERSION=3.15.3
# RUN curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
#     chmod +x /usr/local/bin/kubectl && \
#     curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
#     | tar -zx --strip-components=1 -C /usr/local/bin linux-amd64/helm


# # ---- Git defaults ----------------------------------------------------
# RUN git config --system init.defaultBranch main && git lfs install --system

# # ---- Workspace defaults ---------------------------------------------
# WORKDIR /workspace
# USER ${USERNAME}

# # Useful defaults for fresh containers
# RUN mkdir -p ~/.cache ~/.ssh && \
#     printf "Host *\n  StrictHostKeyChecking no\n" > ~/.ssh/config

# # Keep container alive for dev sessions
# CMD ["sleep", "infinity"]