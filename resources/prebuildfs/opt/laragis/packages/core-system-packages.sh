#!/usr/bin/env bash
# =============================================================================
# Core System Packages and Python Runtime Installation
# =============================================================================
# DESCRIPTION: Install essential system packages and Python runtime
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly PYTHON_VERSION="${PYTHON_VERSION:-3.12}"

install_core_system_packages() {
    log_info "Installing core system packages..."
    
    # Update package manager
    dnf -y update
    
    # Install EPEL repository for additional packages
    dnf -y install epel-release
    
    # Install core system packages
    dnf -y install \
        # Base system utilities
        bash-completion \
        ca-certificates \
        curl \
        wget \
        gnupg2 \
        lsb-release \
        # File and archive utilities
        tar \
        gzip \
        bzip2 \
        xz \
        zip \
        unzip \
        # Text processing utilities
        grep \
        sed \
        awk \
        less \
        more \
        # Network utilities
        net-tools \
        iproute \
        iputils \
        telnet \
        nc \
        # Process and system monitoring
        htop \
        iotop \
        lsof \
        strace \
        # File system utilities
        tree \
        rsync \
        # Security and permissions
        sudo \
        passwd \
        shadow-utils \
        # Locale and timezone
        glibc-langpack-en \
        tzdata
    
    log_success "Core system packages installed successfully"
}

install_python_runtime() {
    log_info "Installing Python ${PYTHON_VERSION} runtime and essential packages..."

    # Install Python 3.12 and essential packages
    dnf -y install \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-pip \
        python${PYTHON_VERSION}-setuptools \
        python${PYTHON_VERSION}-wheel \
        python${PYTHON_VERSION}-devel \
        # Alternative package names for compatibility
        python3 \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        python3-venv \
        python3-devel \
        # Python build dependencies
        gcc \
        gcc-c++ \
        make \
        cmake \
        # Library development headers
        openssl-devel \
        libffi-devel \
        zlib-devel \
        bzip2-devel \
        readline-devel \
        sqlite-devel \
        ncurses-devel \
        tk-devel \
        gdbm-devel \
        db4-devel \
        libpcap-devel \
        xz-devel \
        expat-devel

    # Create symbolic links for version consistency
    if [[ "${PYTHON_VERSION}" != "3" ]]; then
        ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python3
        ln -sf /usr/bin/pip${PYTHON_VERSION} /usr/local/bin/pip3
    fi

    # Upgrade pip to latest version using the specific Python version
    python${PYTHON_VERSION} -m pip install --upgrade pip

    # Install pipx using the specific Python version
    pip${PYTHON_VERSION} install --upgrade pipx

    # Install essential Python packages globally using specific version
    python${PYTHON_VERSION} -m pip install --upgrade \
        setuptools \
        wheel \
        virtualenv \
        pipenv

    # Configure pipx
    pipx ensurepath || python${PYTHON_VERSION} -m pipx ensurepath

    log_success "Python ${PYTHON_VERSION} runtime installed successfully"
}

verify_installation() {
    log_info "Verifying core system packages installation..."
    
    # Verify essential commands
    local commands=(
        "bash" "curl" "wget" "tar" "gzip" "unzip"
        "grep" "sed" "awk" "tree" "rsync" "sudo"
        "python3" "python${PYTHON_VERSION}" "pip3" "pip${PYTHON_VERSION}" "pipx"
    )
    
    local missing_commands=()
    
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -eq 0 ]]; then
        log_success "✅ All core system packages are installed"
    else
        log_error "❌ Missing commands: ${missing_commands[*]}"
        return 1
    fi
    
    # Verify Python installation
    if python${PYTHON_VERSION} --version >/dev/null 2>&1; then
        log_success "✅ Python ${PYTHON_VERSION}: $(python${PYTHON_VERSION} --version)"
    else
        log_error "❌ Python ${PYTHON_VERSION} installation failed"
        return 1
    fi

    if python3 --version >/dev/null 2>&1; then
        log_success "✅ Python3 (symlink): $(python3 --version)"
    else
        log_warn "⚠️  Python3 symlink not available"
    fi

    if pip${PYTHON_VERSION} --version >/dev/null 2>&1; then
        log_success "✅ pip ${PYTHON_VERSION}: $(pip${PYTHON_VERSION} --version)"
    else
        log_error "❌ pip ${PYTHON_VERSION} installation failed"
        return 1
    fi

    if pip3 --version >/dev/null 2>&1; then
        log_success "✅ pip3 (symlink): $(pip3 --version)"
    else
        log_warn "⚠️  pip3 symlink not available"
    fi
    
    if pipx --version >/dev/null 2>&1; then
        log_success "✅ pipx: $(pipx --version)"
    else
        log_error "❌ pipx installation failed"
        return 1
    fi
}

# Main function
main() {
    log_info "Installing core system packages and Python runtime..."
    
    install_core_system_packages
    install_python_runtime
    verify_installation
    
    log_success "Core system packages and Python runtime installation completed successfully"
}

main "$@"
