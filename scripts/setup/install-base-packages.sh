#!/bin/bash
# =============================================================================
# Base Package Installation Script for Oracle Linux 9
# =============================================================================
# Comprehensive package installation for development containers
# Optimized for minimal footprint and maximum functionality
# =============================================================================

set -euo pipefail

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../common" && pwd)"

if [[ -f "$COMMON_DIR/functions.sh" ]]; then
    source "$COMMON_DIR/functions.sh"
else
    # Fallback logging
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[SUCCESS] ✅ $1"; }
    log_error() { echo "[ERROR] ❌ $1"; }
    log_warning() { echo "[WARNING] ⚠️ $1"; }
fi

# Configuration
readonly SCRIPT_VERSION="2.0.0"
readonly LOCK_FILE="/tmp/install-base-packages.lock"

# Installation flags (can be overridden by environment)
INSTALL_CORE_PACKAGES="${INSTALL_CORE_PACKAGES:-1}"
INSTALL_DEV_PACKAGES="${INSTALL_DEV_PACKAGES:-1}"
INSTALL_ENHANCED_TOOLS="${INSTALL_ENHANCED_TOOLS:-1}"
INSTALL_PYTHON="${INSTALL_PYTHON:-1}"
INSTALL_NODEJS="${INSTALL_NODEJS:-0}"
CLEAN_CACHE="${CLEAN_CACHE:-1}"

# Package categories
declare -a CORE_PACKAGES=(
    # User & privilege management
    "sudo" "shadow-utils" "util-linux-user"
    # Process management & monitoring
    "procps-ng" "psmisc" "lsof" "htop"
    # File & archive management
    "tar" "xz" "gzip" "bzip2" "unzip" "zip" "rsync"
    # Network utilities
    "wget" "iproute" "iputils" "bind-utils" "net-tools" "nmap-ncat"
    # Text processing & search
    "grep" "sed" "gawk" "diffutils" "patch" "file" "less" "tree" "jq"
    # System utilities
    "which" "findutils" "coreutils" "ncurses"
    # Locale support
    "glibc-langpack-en" "glibc-langpack-vi"
)

declare -a DEV_PACKAGES=(
    # Text editors
    "vim-enhanced" "nano"
    # Version control
    "git" "git-lfs"
    # Security & crypto
    "gnupg2" "openssl" "openssh-clients"
    # Shell environment
    "bash-completion" "zsh" "man-pages" "man-db" "info"
    # Development libraries
    "kernel-headers" "openssl-devel" "zlib-devel" "libcurl-devel" "ncurses-devel"
    # Build tools (additional to Development Tools group)
    "cmake"
)

declare -a ENHANCED_PACKAGES=(
    # Advanced debugging & profiling
    "valgrind" "perf"
    # Disk usage analysis
    "ncdu"
    # Network analysis
    "tcpdump" "wireshark-cli"
    # Terminal multiplexers
    "tmux" "screen"
)

declare -a PYTHON_PACKAGES=(
    "python3" "python3-pip" "python3-devel" "python3-setuptools" 
    "python3-wheel" "python3-virtualenv" "python3-pytest"
)

declare -a NODEJS_PACKAGES=(
    "nodejs" "npm"
)

# Lock file management
cleanup() {
    if [[ -f "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE"
    fi
}
trap cleanup EXIT

# Main installation function
install_base_packages() {
    log_info "Starting base package installation v${SCRIPT_VERSION}"
    
    # Create lock file
    if [[ -f "$LOCK_FILE" ]]; then
        log_error "Installation already in progress"
        return 1
    fi
    echo $$ > "$LOCK_FILE"
    
    # Setup repositories first
    setup_repositories
    
    # Install package categories
    if [[ "$INSTALL_CORE_PACKAGES" == "1" ]]; then
        install_package_group "CORE SYSTEM PACKAGES" "${CORE_PACKAGES[@]}"
    fi
    
    if [[ "$INSTALL_DEV_PACKAGES" == "1" ]]; then
        # Install Development Tools group first
        install_development_tools_group
        # Then install additional dev packages
        install_package_group "DEVELOPMENT PACKAGES" "${DEV_PACKAGES[@]}"
    fi
    
    if [[ "$INSTALL_ENHANCED_TOOLS" == "1" ]]; then
        install_package_group "ENHANCED TOOLS" "${ENHANCED_PACKAGES[@]}"
    fi
    
    if [[ "$INSTALL_PYTHON" == "1" ]]; then
        install_package_group "PYTHON DEVELOPMENT" "${PYTHON_PACKAGES[@]}"
    fi
    
    if [[ "$INSTALL_NODEJS" == "1" ]]; then
        install_package_group "NODE.JS DEVELOPMENT" "${NODEJS_PACKAGES[@]}"
    fi
    
    # Final cleanup
    if [[ "$CLEAN_CACHE" == "1" ]]; then
        cleanup_package_cache
    fi
    
    log_success "Base package installation completed successfully!"
}

# Repository setup
setup_repositories() {
    log_info "Setting up repositories..."
    
    # Update CA certificates first
    update-ca-trust
    
    # Install repository management tools
    dnf -y install --setopt=install_weak_deps=False --nodocs \
        dnf-plugins-core ca-certificates
    
    # Apply security updates
    dnf -y update-minimal --security --setopt=install_weak_deps=False || true
    
    # Enable EPEL repository
    if ! dnf -y install --setopt=install_weak_deps=False --nodocs oracle-epel-release-el9; then
        log_warning "Failed to install oracle-epel-release-el9, trying to enable developer EPEL"
        dnf -y config-manager --enable ol9_developer_EPEL || true
    fi
    
    # Clean metadata cache
    dnf clean metadata
    
    log_success "Repository setup completed"
}

# Install Development Tools group
install_development_tools_group() {
    log_info "Installing Development Tools group..."
    
    if dnf -y groupinstall "Development Tools" --setopt=install_weak_deps=False --nodocs; then
        log_success "Development Tools group installed successfully"
    else
        log_warning "Failed to install Development Tools group, installing individual packages"
        # Fallback to individual packages
        local dev_tools=(
            "autoconf" "automake" "binutils" "bison" "flex" 
            "gcc" "gcc-c++" "gdb" "glibc-devel" "libtool" 
            "make" "pkgconf" "pkgconf-pkg-config" "rpm-build" "strace"
        )
        install_package_group "DEVELOPMENT TOOLS (FALLBACK)" "${dev_tools[@]}"
    fi
}

# Install package group with error handling
install_package_group() {
    local group_name="$1"
    shift
    local packages=("$@")
    
    log_info "Installing $group_name (${#packages[@]} packages)..."
    
    local failed_packages=()
    local success_count=0
    
    # Try to install all packages at once first
    if dnf -y install --setopt=install_weak_deps=False --nodocs "${packages[@]}" 2>/dev/null; then
        log_success "$group_name installed successfully (batch install)"
        return 0
    fi
    
    # If batch install fails, try individual packages
    log_warning "Batch install failed, trying individual packages..."
    
    for package in "${packages[@]}"; do
        if dnf -y install --setopt=install_weak_deps=False --nodocs "$package" 2>/dev/null; then
            log_success "✅ $package"
            ((success_count++))
        else
            log_warning "❌ Failed to install: $package"
            failed_packages+=("$package")
        fi
    done
    
    # Report results
    log_info "$group_name installation completed:"
    log_info "  ✅ Successful: $success_count/${#packages[@]}"
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warning "  ❌ Failed packages: ${failed_packages[*]}"
    fi
}

# Cleanup package cache
cleanup_package_cache() {
    log_info "Cleaning package cache..."
    
    dnf clean all
    rm -rf /var/cache/dnf/* /var/tmp/* /tmp/*
    
    # Clean log files
    find /var/log -type f -exec truncate -s 0 {} \; 2>/dev/null || true
    
    log_success "Package cache cleaned"
}

# Show installation summary
show_summary() {
    log_info "Installation Summary:"
    log_info "  Core Packages: ${INSTALL_CORE_PACKAGES}"
    log_info "  Development Packages: ${INSTALL_DEV_PACKAGES}"
    log_info "  Enhanced Tools: ${INSTALL_ENHANCED_TOOLS}"
    log_info "  Python Support: ${INSTALL_PYTHON}"
    log_info "  Node.js Support: ${INSTALL_NODEJS}"
    log_info "  Clean Cache: ${CLEAN_CACHE}"
}

# Main execution
main() {
    log_info "Oracle Linux 9 Base Package Installer v${SCRIPT_VERSION}"
    
    # Show configuration
    show_summary
    
    # Verify we're running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
    
    # Run installation
    if install_base_packages; then
        log_success "🎉 All package installations completed successfully!"
        
        # Show some useful information
        echo
        log_info "Installed tools verification:"
        command -v vim >/dev/null && log_success "✅ vim available"
        command -v git >/dev/null && log_success "✅ git available"
        command -v gcc >/dev/null && log_success "✅ gcc available"
        command -v python3 >/dev/null && log_success "✅ python3 available"
        command -v node >/dev/null && log_success "✅ node.js available" || log_info "ℹ️ node.js not installed"
        
    else
        log_error "Package installation failed!"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
