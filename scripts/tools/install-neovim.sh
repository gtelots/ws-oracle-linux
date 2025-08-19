#!/bin/bash

# =============================================================================
# Neovim & LazyVim Installation Script
# Modern Neovim setup with LazyVim configuration
# =============================================================================

set -euo pipefail

# Load shared functions
# shellcheck source=../common/functions.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common/functions.sh"

# Configuration
readonly TOOL_NAME="neovim"
readonly NEOVIM_VERSION="${NEOVIM_VERSION:-latest}"
readonly LOCK_FILE="/tmp/install-neovim.lock"
readonly USERNAME="${USERNAME:-dev}"
readonly USER_UID="${USER_UID:-1000}"
readonly USER_GID="${USER_GID:-1000}"

# Global cleanup
trap cleanup EXIT

install_neovim() {
    log_info "Installing Neovim ${NEOVIM_VERSION}..."
    
    # Create lock file
    create_lock_file "$LOCK_FILE" "Neovim installation"
    
    # Remove old neovim if exists
    log_info "Removing old Neovim installation..."
    dnf remove -y neovim || true
    rm -rf /opt/nvim /opt/nvim-linux-x86_64 || true
    
    # Download and install latest Neovim
    log_info "Downloading Neovim for x86_64..."
    local nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    local temp_file="/tmp/nvim-linux-x86_64.tar.gz"
    
    if ! download_file "$nvim_url" "$temp_file"; then
        log_error "Failed to download Neovim"
        return 1
    fi
    
    # Extract and install
    log_info "Installing Neovim to /opt/nvim..."
    tar -C /opt -xzf "$temp_file"
    ln -sfn /opt/nvim-linux-x86_64 /opt/nvim
    ln -sfn /opt/nvim/bin/nvim /usr/local/bin/nvim
    rm -f "$temp_file"
    
    # Verify installation
    if command -v nvim >/dev/null 2>&1; then
        local nvim_version
        nvim_version=$(nvim --version | head -1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "latest")
        log_success "Neovim ${nvim_version} installed successfully!"
    else
        log_error "Neovim installation verification failed"
        return 1
    fi
}

setup_lazyvim() {
    log_info "Setting up LazyVim configuration..."
    
    # Switch to target user context
    local home_dir="/home/${USERNAME}"
    local config_dir="${home_dir}/.config/nvim"
    
    # Install Python neovim support
    log_info "Installing Python neovim support..."
    python3 -m pip install --no-cache-dir --user pynvim
    
    # Setup LazyVim for target user
    log_info "Cloning LazyVim starter configuration..."
    
    # Remove existing config
    rm -rf "$config_dir"
    
    # Clone LazyVim starter
    git clone --depth=1 https://github.com/LazyVim/starter "$config_dir"
    rm -rf "${config_dir}/.git"
    
    # Set proper ownership
    chown -R "${USER_UID}:${USER_GID}" "$config_dir"
    
    # Run initial Lazy sync (as user)
    log_info "Running initial LazyVim plugin sync..."
    su - "$USERNAME" -c "nvim --headless '+Lazy! sync' +qa" || true
    
    log_success "LazyVim configuration completed!"
}

show_neovim_usage() {
    log_info "Neovim with LazyVim is ready!"
    echo ""
    echo "Usage:"
    echo "  nvim                    # Start Neovim"
    echo "  nvim file.txt          # Edit a file"
    echo ""
    echo "LazyVim shortcuts:"
    echo "  <space>              # Leader key"
    echo "  <space>e             # File explorer"
    echo "  <space>ff            # Find files"
    echo "  <space>fg            # Live grep"
    echo "  <space>l             # Lazy plugin manager"
    echo ""
    log_info "For more info: https://lazyvim.org"
}

cleanup() {
    remove_lock_file "$LOCK_FILE"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "Starting Neovim & LazyVim installation..."
    
    install_neovim
    setup_lazyvim
    show_neovim_usage
    
    log_success "Neovim & LazyVim installation completed successfully!"
fi
