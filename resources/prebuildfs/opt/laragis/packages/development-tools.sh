#!/usr/bin/env bash
# =============================================================================
# Essential Development Tools Installation
# =============================================================================
# DESCRIPTION: Install essential development utilities and tools
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly PYTHON_VERSION="${PYTHON_VERSION:-3.12}"

install_development_tools() {
    log_info "Installing essential development tools..."
    
    # Install development tools and compilers
    dnf -y install \
        # Build tools and compilers
        gcc \
        gcc-c++ \
        make \
        cmake \
        autoconf \
        automake \
        libtool \
        pkgconfig \
        # Version control systems
        git \
        git-lfs \
        subversion \
        mercurial \
        # Text editors and IDEs
        vim \
        nano \
        emacs \
        # Development libraries
        openssl-devel \
        libcurl-devel \
        zlib-devel \
        pcre-devel \
        # Database clients
        mysql \
        postgresql \
        sqlite \
        redis \
        # Container and virtualization tools
        podman \
        buildah \
        skopeo \
        # Network development tools
        nmap \
        tcpdump \
        wireshark-cli \
        # Performance and debugging tools
        gdb \
        valgrind \
        perf \
        # Documentation tools
        man-pages \
        man-db \
        info
    
    log_success "Essential development tools installed successfully"
}

install_language_runtimes() {
    log_info "Installing basic language runtimes..."
    
    # Install language runtimes available via package manager
    dnf -y install \
        # Language runtimes
        golang \
        nodejs \
        npm \
        rust \
        cargo \
        # Scripting languages
        perl \
        ruby \
        lua \
        # Shell environments
        zsh \
        fish \
        # Package managers
        yarn
    
    log_success "Basic language runtimes installed successfully"
}

install_container_tools() {
    log_info "Installing container development tools..."
    
    # Install container-related tools
    dnf -y install \
        # Container runtimes
        docker-ce \
        docker-ce-cli \
        containerd.io \
        # Container build tools
        docker-buildx-plugin \
        docker-compose-plugin \
        # Kubernetes tools (basic)
        kubernetes-client
    
    # Enable and start Docker service
    systemctl enable docker
    systemctl start docker
    
    # Add user to docker group (will be effective after restart)
    usermod -aG docker "${USER_NAME}" 2>/dev/null || true
    
    log_success "Container development tools installed successfully"
}

install_database_tools() {
    log_info "Installing database development tools..."
    
    # Install database development tools
    dnf -y install \
        # Database servers (for development)
        mariadb-server \
        postgresql-server \
        redis \
        # Database clients and tools
        mysql-devel \
        postgresql-devel \
        sqlite-devel \
        # Database administration tools
        phpmyadmin \
        pgadmin4
    
    log_success "Database development tools installed successfully"
}

configure_development_environment() {
    log_info "Configuring development environment..."
    
    # Configure Git (basic setup)
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf input
    
    # Create development directories
    mkdir -p /opt/development/{projects,tools,scripts}
    chown -R "${USER_UID}:${USER_GID}" /opt/development
    
    # Create symbolic links for common development paths
    ln -sf /opt/development /home/"${USER_NAME}"/dev
    
    # Set up development environment variables
    cat >> /etc/environment << 'EOF'
# Development environment variables
DEVELOPMENT_ROOT=/opt/development
PROJECTS_DIR=/opt/development/projects
TOOLS_DIR=/opt/development/tools
SCRIPTS_DIR=/opt/development/scripts
EOF
    
    log_success "Development environment configured successfully"
}

verify_development_tools() {
    log_info "Verifying development tools installation..."
    
    # Verify essential development commands
    local dev_commands=(
        "gcc" "g++" "make" "cmake" "git" "vim"
        "docker" "podman" "go" "node" "npm" "cargo"
    )
    
    local missing_commands=()
    
    for cmd in "${dev_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -eq 0 ]]; then
        log_success "✅ All development tools are installed"
    else
        log_warn "⚠️  Some optional tools are missing: ${missing_commands[*]}"
    fi
    
    # Verify specific tools
    if command -v git >/dev/null 2>&1; then
        log_success "✅ Git: $(git --version)"
    fi
    
    if command -v docker >/dev/null 2>&1; then
        log_success "✅ Docker: $(docker --version)"
    fi
    
    if command -v go >/dev/null 2>&1; then
        log_success "✅ Go: $(go version)"
    fi
    
    if command -v node >/dev/null 2>&1; then
        log_success "✅ Node.js: $(node --version)"
    fi
}

# Main function
main() {
    log_info "Installing essential development tools and utilities..."
    
    install_development_tools
    install_language_runtimes
    install_container_tools
    install_database_tools
    configure_development_environment
    verify_development_tools
    
    log_success "Essential development tools installation completed successfully"
}

main "$@"
