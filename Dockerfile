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
ARG TZ=UTC
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
    procps-ng psmisc lsof util-linux util-linux-user ncurses \
    # Editors & shells
    vim neovim bash-completion zsh \
    # TUI helpers
    htop ncdu tmux \
    # C/C++ build toolchain
    gcc gcc-c++ make automake autoconf libtool pkgconf-pkg-config \
    # Modern CLI utilities
    fzf ripgrep fd-find bat eza fastfetch thefuck tldr zoxide \
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

# Upgrade Neovim to the latest release (official prebuilt binary)
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

USER root

# -----------------------------------------------------------------------------
# Shell prompt & dotfiles (Zinit + plugins)
# -----------------------------------------------------------------------------
USER ${USERNAME}

RUN set -eux; \
  # Download and install Starship prompt (modern cross-shell prompt)
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y; \
  # Download and install Zinit (fast and feature-rich Zsh plugin manager)
  curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh | bash -s -- -y; \
  \
  # Configure Zsh with essential plugins and user-friendly defaults
  { \
    echo ''; \
    # Conditionally add Volta (Node.js) environment if enabled
    if [ "${INSTALL_VOLTA}" = "1" ]; then \
    echo '# ==> Volta (Node.js version manager) initialization'; \
    echo 'export VOLTA_HOME="$HOME/.volta"'; \
    echo 'export PATH="$VOLTA_HOME/bin:$PATH"'; \
    echo ''; \
    echo '# ==> Essential Zsh plugins for enhanced shell experience'; \
    echo 'zinit load "zsh-users/zsh-syntax-highlighting"  # Syntax highlighting for commands'; \
    echo 'zinit load "zsh-users/zsh-completions"          # Additional completion definitions'; \
    echo 'zinit load "zsh-users/zsh-autosuggestions"      # Fish-like autosuggestions'; \
    echo 'zinit load "zsh-users/zsh-history-substring-search"  # History search with arrows'; \
    echo 'zinit load "Aloxaf/fzf-tab"                     # Replace tab completion with fzf'; \
    echo 'zinit load "hlissner/zsh-autopair"              # Auto-close quotes and brackets'; \
    echo 'zinit load "MichaelAquilina/zsh-you-should-use" # Remind about existing aliases'; \
    echo ''; \
    echo '# ==> Modern shell integrations'; \
    echo 'command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"  # Beautiful prompt'; \
    echo 'command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"      # Smart cd replacement'; \
    echo 'command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"     # Fix command typos'; \
    echo ''; \
    echo '# ==> Useful aliases for development workflow'; \
    echo 'alias ll="eza -lha --group-directories-first"   # Better ls with details'; \
    echo 'alias ls="eza"                                  # Modern ls replacement'; \
    echo 'alias cat="bat --paging=never"                 # Syntax-highlighted cat'; \
    echo 'alias vi="nvim"                                # Use Neovim instead of vi'; \
    echo 'alias vim="nvim"                               # Use Neovim instead of vim'; \
    echo 'alias lg="lazygit"                             # Git TUI shortcut'; \
    echo 'alias ld="lazydocker"                          # Docker TUI shortcut'; \
    echo ''; \
    fi; \
  } >> ~/.zshrc; \
  # Set up Starship with a beautiful preset theme
  mkdir -p ~/.config; \
  starship preset gruvbox-rainbow -o ~/.config/starship.toml;

RUN set -eux; \
  # Set terminal type to fix tput issues (local to this RUN command)
  export TERM=xterm-256color; \
  # Ensure Zinit is initialized and plugins are loaded
  zsh -c "source ~/.zshrc"

USER root

# -----------------------------------------------------------------------------
# SSH Server Configuration
# -----------------------------------------------------------------------------
ARG INSTALL_OPENSSH_SERVER=1
ARG SSH_PORT=2222

COPY .ssh/id_ed25519_all_ws_ol /tmp/id_ed25519
COPY .ssh/id_ed25519_all_ws_ol.pub /tmp/id_ed25519.pub

RUN set -eux; \
  if [ "${INSTALL_OPENSSH_SERVER}" = "1" ]; then \
    echo "==> Installing and configuring SSH server"; \
    # Install OpenSSH server
    dnf -y install --setopt=install_weak_deps=False --nodocs openssh-server; \
    # Generate host keys
    ssh-keygen -A; \
    # Create SSH directory for dev user
    mkdir -p /home/${USERNAME}/.ssh; \
    chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.ssh; \
    chmod 700 /home/${USERNAME}/.ssh; \

    cat /tmp/id_ed25519.pub >> /root/.ssh/authorized_keys \
        && cat /tmp/id_ed25519.pub >> /root/.ssh/id_ed25519.pub \
        && cat /tmp/id_ed25519 >> /root/.ssh/id_ed25519 \
        && rm -f /tmp/id_ed25519* \
        && chmod 644 /root/.ssh/authorized_keys /root/.ssh/id_ed25519.pub \
    && chmod 400 /root/.ssh/id_ed25519 \
    && cp -rf /root/.ssh /home/${USERNAME} \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh \
    
    # # Configure SSH daemon
    # sed -i 's/#Port 22/Port '"${SSH_PORT}"'/' /etc/ssh/sshd_config; \
    # sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config; \
    # sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config; \
    # sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config; \
    # sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config; \
    # # Allow SSH login for dev user
    # echo "AllowUsers ${USERNAME} root" >> /etc/ssh/sshd_config; \
    # # Create systemd service override to use custom port
    # mkdir -p /etc/systemd/system/sshd.service.d; \
    # echo -e '[Service]\nExecStart=\nExecStart=/usr/sbin/sshd -D -p '"${SSH_PORT}" > /etc/systemd/system/sshd.service.d/custom-port.conf; \
    # # Create startup script for SSH
    # echo '#!/bin/bash' > /usr/local/bin/start-ssh; \
    # echo '/usr/sbin/sshd -D -p '"${SSH_PORT}"' &' >> /usr/local/bin/start-ssh; \
    # echo 'exec "$@"' >> /usr/local/bin/start-ssh; \
    # chmod +x /usr/local/bin/start-ssh; \
  else \
    echo "==> Skipping SSH server installation"; \
  fi

# Expose SSH port
EXPOSE ${SSH_PORT}

# -----------------------------------------------------------------------------
# Workspace setup and final cleanup
# -----------------------------------------------------------------------------

# Create shared workspace directory with proper ownership
RUN mkdir -p /workspace && chown ${USER_UID}:${USER_GID} /workspace

# # Clean up package cache and temporary files to reduce image size
# RUN dnf clean all; rm -rf /var/cache/dnf/* /root/.cache/*

USER ${USERNAME}

# # Keep container alive for dev sessions
CMD ["sleep", "infinity"]

# # Start SSH server and keep container alive
# CMD ["/usr/local/bin/start-ssh", "sleep", "infinity"]