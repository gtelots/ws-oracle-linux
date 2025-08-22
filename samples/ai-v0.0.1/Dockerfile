# Multi-stage Oracle Linux 9 Development Container
# Following Bitnami security patterns and Laradock modular architecture
# Production-ready with security hardening and performance optimization

# =============================================================================
# Stage 1: Base System Setup and Security Hardening
# =============================================================================
FROM oraclelinux:9-slim AS base

# Metadata and labels for container identification
LABEL maintainer="Oracle Linux Development Team"
LABEL version="1.0.0"
LABEL description="Production-ready Oracle Linux 9 development container"
LABEL org.opencontainers.image.source="https://github.com/oracle/ws-oracle-linux"

# Environment variables for consistent builds
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TERM=xterm-256color \
    DEBIAN_FRONTEND=noninteractive \
    CONTAINER_USER=developer \
    CONTAINER_UID=1000 \
    CONTAINER_GID=1000 \
    WORKSPACE_DIR=/workspace \
    HOME_DIR=/home/developer

# Install essential system packages and security tools
RUN microdnf update -y && \
    microdnf install -y \
        # Core system utilities
        bash bash-completion \
        curl wget ca-certificates \
        git git-lfs \
        openssh-clients openssh-server \
        sudo \
        # Development essentials
        gcc gcc-c++ make cmake \
        python3 python3-pip python3-devel \
        nodejs npm \
        # Security and monitoring tools
        htop procps-ng \
        net-tools iputils \
        # Text processing and utilities
        vim nano \
        zip unzip tar gzip \
        jq yq \
        # Locale support
        glibc-langpack-en \
    && microdnf clean all \
    && rm -rf /var/cache/dnf

# =============================================================================
# Stage 2: Development Tools and Language Runtimes
# =============================================================================
FROM base AS development

# Install additional development tools and runtimes
RUN microdnf install -y \
        # Additional development tools
        autoconf automake libtool \
        pkgconfig \
        # Database clients
        mysql postgresql \
        # Container and orchestration tools
        podman buildah skopeo \
        # Performance and debugging tools
        strace ltrace \
        valgrind gdb \
        # Network tools
        telnet nc nmap-ncat \
    && microdnf clean all

# Install modern CLI tools and productivity utilities
RUN curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    # Install bat (better cat)
    curl -fsSL https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-x86_64-unknown-linux-musl.tar.gz | \
    tar -xzC /tmp && \
    mv /tmp/bat-*/bat /usr/local/bin/ && \
    # Install exa (better ls)
    curl -fsSL https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip -o /tmp/exa.zip && \
    unzip /tmp/exa.zip -d /tmp && \
    mv /tmp/bin/exa /usr/local/bin/ && \
    # Install fd (better find)
    curl -fsSL https://github.com/sharkdp/fd/releases/download/v8.7.0/fd-v8.7.0-x86_64-unknown-linux-musl.tar.gz | \
    tar -xzC /tmp && \
    mv /tmp/fd-*/fd /usr/local/bin/ && \
    # Install ripgrep (better grep)
    curl -fsSL https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep-13.0.0-x86_64-unknown-linux-musl.tar.gz | \
    tar -xzC /tmp && \
    mv /tmp/ripgrep-*/rg /usr/local/bin/ && \
    # Cleanup
    rm -rf /tmp/*

# =============================================================================
# Stage 3: User Setup and Security Configuration
# =============================================================================
FROM development AS user-setup

# Create non-root user following Bitnami security practices
RUN groupadd -g ${CONTAINER_GID} ${CONTAINER_USER} && \
    useradd -u ${CONTAINER_UID} -g ${CONTAINER_GID} -m -s /bin/bash ${CONTAINER_USER} && \
    # Configure sudo access
    echo "${CONTAINER_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${CONTAINER_USER} && \
    chmod 0440 /etc/sudoers.d/${CONTAINER_USER} && \
    # Create workspace directory
    mkdir -p ${WORKSPACE_DIR} && \
    chown -R ${CONTAINER_USER}:${CONTAINER_USER} ${WORKSPACE_DIR}

# Configure SSH for development
RUN mkdir -p /etc/ssh && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# =============================================================================
# Stage 4: Final Production Image
# =============================================================================
FROM user-setup AS final

# Copy configuration files and scripts
COPY --chown=${CONTAINER_USER}:${CONTAINER_USER} scripts/ /opt/scripts/
COPY --chown=${CONTAINER_USER}:${CONTAINER_USER} dotfiles/ ${HOME_DIR}/.config/
COPY --chown=${CONTAINER_USER}:${CONTAINER_USER} .ssh/ ${HOME_DIR}/.ssh/
COPY --chown=${CONTAINER_USER}:${CONTAINER_USER} ca-certificates/ /usr/local/share/ca-certificates/

# Set proper permissions
RUN chmod +x /opt/scripts/*.sh && \
    chmod 700 ${HOME_DIR}/.ssh && \
    chmod 600 ${HOME_DIR}/.ssh/* 2>/dev/null || true && \
    # Update CA certificates
    update-ca-trust

# Switch to non-root user
USER ${CONTAINER_USER}
WORKDIR ${WORKSPACE_DIR}

# Configure shell environment
RUN echo 'source ~/.config/bashrc' >> ${HOME_DIR}/.bashrc && \
    echo 'source ~/.config/aliases' >> ${HOME_DIR}/.bashrc

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /opt/scripts/healthcheck.sh

# Expose common development ports
EXPOSE 3000 8000 8080 9000

# Default command
CMD ["/bin/bash"]
