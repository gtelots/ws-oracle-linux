# -----------------------------------------------------------------------------
# Dev Container: Oracle Linux 9 (rolling minor)
# -----------------------------------------------------------------------------
ARG ORACLE_LINUX_VERSION=9
FROM oraclelinux:${ORACLE_LINUX_VERSION} as base

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

# Single-binary tools
ARG TASK_VERSION=3.39.2
ARG LAZYDOCKER_VERSION=0.23.3
ARG YQ_VERSION=4.44.3
ARG LAZYGIT_VERSION=0.43.1

# Optional: install kubectl/helm (1=yes, 0=no)
ARG INSTALL_K8S=0
ARG KUBECTL_VERSION=1.30.4
ARG HELM_VERSION=3.15.3

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
  chmod 0440 /etc/sudoers.d/99-${USERNAME}

# # -----------------------------------------------------------------------------
# # Base OS setup: repos, timezone, upgrade to latest minor
# # -----------------------------------------------------------------------------
# RUN set -eux; \
#     dnf -y upgrade; \
#     dnf -y install oracle-epel-release-el9 dnf-plugins-core; \
#     dnf -y config-manager --enable ol9_developer_EPEL || true; \
#     dnf -y install --setopt=install_weak_deps=False --nodocs \
#       glibc-langpack-en glibc-langpack-vi tzdata; \
#     ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime; echo "${TZ}" > /etc/timezone; \
#     update-ca-trust; \
#     dnf clean all; rm -rf /var/cache/dnf/*

# # -----------------------------------------------------------------------------
# # Essentials: shells, editors, net tools, toolchains, TUI utilities
# # -----------------------------------------------------------------------------
# RUN set -eux; \
#     dnf -y install --setopt=install_weak_deps=False --nodocs \
#       sudo ca-certificates gnupg2 \
#       git git-lfs openssh-clients \
#       curl wget unzip zip tar xz bzip2 gzip \
#       jq which tree rsync coreutils findutils \
#       iputils traceroute bind-utils net-tools telnet iproute \
#       procps-ng psmisc lsof util-linux ncurses \
#       vim nano less zsh bash-completion \
#       htop ncdu tmux \
#       gcc gcc-c++ make automake autoconf libtool pkgconf-pkg-config \
#       python3 python3-pip python3-virtualenv python3-devel \
#       golang java-17-openjdk java-17-openjdk-devel \
#       neovim fzf ripgrep fd-find bat eza; \
#     # Helpful symlinks (names differ across distros)
#     { command -v fdfind >/dev/null 2>&1 && ln -sf "$(command -v fdfind)" /usr/local/bin/fd || true; }; \
#     { command -v batcat >/dev/null 2>&1 && ln -sf "$(command -v batcat)" /usr/local/bin/bat || true; }; \
#     dnf clean all; rm -rf /var/cache/dnf/*

# # -----------------------------------------------------------------------------
# # Node.js 20 via modules + Corepack (pnpm/yarn)
# # -----------------------------------------------------------------------------
# RUN set -eux; \
#     dnf -y module reset nodejs || true; \
#     dnf -y module enable nodejs:20; \
#     dnf -y install --setopt=install_weak_deps=False --nodocs nodejs; \
#     corepack enable; corepack prepare pnpm@latest --activate || true; \
#     dnf clean all; rm -rf /var/cache/dnf/*



# # -----------------------------------------------------------------------------
# # Install standalone CLIs (task, lazydocker, yq, lazygit)
# # -----------------------------------------------------------------------------
# RUN set -eux; \
#     ARCH="$(uname -m)"; \
#     case "$ARCH" in \
#       x86_64)  TASK_ARCH=amd64; LD_ARCH=x86_64; YQ_ARCH=amd64; LG_ARCH=Linux_x86_64 ;; \
#       aarch64) TASK_ARCH=arm64; LD_ARCH=arm64;  YQ_ARCH=arm64; LG_ARCH=Linux_arm64 ;; \
#       *) echo "Unsupported arch: $ARCH" >&2; exit 1 ;; \
#     esac; \
#     # go-task
#     curl -fsSL -o /tmp/task.tgz "https://github.com/go-task/task/releases/download/v${TASK_VERSION}/task_linux_${TASK_ARCH}.tar.gz"; \
#     tar -xzf /tmp/task.tgz -C /usr/local/bin task; rm -f /tmp/task.tgz; \
#     # lazydocker
#     curl -fsSL -o /tmp/lazydocker.tgz "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_${LD_ARCH}.tar.gz"; \
#     tar -xzf /tmp/lazydocker.tgz -C /usr/local/bin lazydocker; rm -f /tmp/lazydocker.tgz; \
#     # yq
#     curl -fsSL -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${YQ_ARCH}"; \
#     chmod +x /usr/local/bin/yq; \
#     # lazygit
#     curl -fsSL -o /tmp/lazygit.tgz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_${LG_ARCH}.tar.gz"; \
#     tar -xzf /tmp/lazygit.tgz -C /usr/local/bin lazygit; rm -f /tmp/lazygit.tgz

# # -----------------------------------------------------------------------------
# # Optional: kubectl + helm (controlled by INSTALL_K8S)
# # -----------------------------------------------------------------------------
# RUN set -eux; \
#     if [ "${INSTALL_K8S}" = "1" ]; then \
#       curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')/kubectl"; \
#       chmod +x /usr/local/bin/kubectl; \
#       curl -fsSL -o /tmp/helm.tgz "https://get.helm.sh/helm-v${HELM_VERSION}-linux-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/').tar.gz"; \
#       tar -xzf /tmp/helm.tgz -C /tmp; \
#       mv /tmp/linux-*/helm /usr/local/bin/helm; chmod +x /usr/local/bin/helm; rm -rf /tmp/helm.tgz /tmp/linux-*; \
#     fi

# # -----------------------------------------------------------------------------
# # LazyVim setup (for the non-root user)
# # -----------------------------------------------------------------------------
# USER ${USERNAME}
# WORKDIR /home/${USERNAME}

# RUN set -eux; \
#     python3 -m pip install --no-cache-dir --user pynvim; \
#     git clone --depth=1 https://github.com/LazyVim/starter ~/.config/nvim; \
#     rm -rf ~/.config/nvim/.git; \
#     nvim --headless "+Lazy! sync" +qa || true

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

WORKDIR /workspace
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

# # ---- Non-root user ---------------------------------------------------
# ARG USERNAME=dev
# ARG UID=1000
# ARG GID=1000
# RUN groupadd -g ${GID} ${USERNAME} && \
#     useradd -m -s /bin/bash -u ${UID} -g ${GID} ${USERNAME} && \
#     echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-${USERNAME} && \
#     chmod 0440 /etc/sudoers.d/90-${USERNAME}

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