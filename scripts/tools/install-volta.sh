#!/bin/bash

# =============================================================================
# Volta (Node.js Version Manager) Installation Script
# Fast, reliable way to manage Node.js versions
# https://volta.sh/
# =============================================================================

set -euo pipefail

# Load shared functions
# shellcheck source=../common/functions.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common/functions.sh"

# Configuration
readonly TOOL_NAME="volta"
readonly VOLTA_VERSION="${VOLTA_VERSION:-latest}"
readonly LOCK_FILE="/tmp/install-volta.lock"
readonly USERNAME="${USERNAME:-dev}"
readonly USER_UID="${USER_UID:-1000}"
readonly USER_GID="${USER_GID:-1000}"

# Global cleanup
trap cleanup EXIT

install_volta() {
    log_info "Installing Volta Node.js manager..."
    
    # Create lock file
    create_lock_file "$LOCK_FILE" "Volta installation"
    
    # Check if should install
    if [[ "${INSTALL_VOLTA:-1}" != "1" ]]; then
        log_info "Volta installation is disabled in configuration"
        return 0
    fi
    
    # Install Volta
    log_info "Downloading and installing Volta..."
    curl -fsSL https://get.volta.sh | bash
    
    # Setup environment for installation
    export VOLTA_HOME="/home/${USERNAME}/.volta"
    export PATH="$VOLTA_HOME/bin:$PATH"
    
    # Source the Volta environment to make volta command available
    log_info "Loading Volta environment..."
    if [[ -f "/home/${USERNAME}/.volta/volta.sh" ]]; then
        source "/home/${USERNAME}/.volta/volta.sh"
    elif [[ -f "/home/${USERNAME}/.bashrc" ]]; then
        source "/home/${USERNAME}/.bashrc"
    fi
    
    # Alternative method - use full path if volta command not found
    local volta_bin="$VOLTA_HOME/bin/volta"
    if [[ ! -x "$volta_bin" ]]; then
        log_warning "Volta binary not found at expected location, checking alternatives..."
        # Try different possible locations
        if [[ -x "/home/${USERNAME}/.volta/bin/volta" ]]; then
            volta_bin="/home/${USERNAME}/.volta/bin/volta"
        elif command -v volta >/dev/null 2>&1; then
            volta_bin="volta"
        else
            log_error "Cannot find volta binary after installation"
            return 1
        fi
    fi
    
    # Install Node.js LTS
    log_info "Installing Node.js LTS via Volta..."
    "$volta_bin" install node@lts
    
    # Install package managers
    log_info "Installing npm, yarn, and pnpm..."
    "$volta_bin" install npm@latest
    
    # Add volta to PATH for npm commands
    if command -v npm >/dev/null 2>&1; then
        npm install -g yarn@latest pnpm@latest
    else
        log_warning "npm not found in PATH, skipping yarn and pnpm installation"
    fi
    
    # Verify installations
    log_info "Verifying installations..."
    if command -v node >/dev/null 2>&1; then
        node --version
    fi
    if command -v npm >/dev/null 2>&1; then
        npm --version
    fi
    if command -v yarn >/dev/null 2>&1; then
        yarn --version
    fi
    if command -v pnpm >/dev/null 2>&1; then
        pnpm --version
    fi
    
    # Set proper ownership
    chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}/.volta"
    
    log_success "Volta and Node.js tools installed successfully!"
}

setup_volta_environment() {
    log_info "Setting up Volta environment..."
    
    # Add Volta to shell profiles
    local volta_env='
# Volta Node.js manager
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
'
    
    # Add to bashrc
    if ! grep -q "VOLTA_HOME" "/home/${USERNAME}/.bashrc" 2>/dev/null; then
        echo "$volta_env" >> "/home/${USERNAME}/.bashrc"
    fi
    
    # Add to zshrc if exists
    if [[ -f "/home/${USERNAME}/.zshrc" ]]; then
        if ! grep -q "VOLTA_HOME" "/home/${USERNAME}/.zshrc"; then
            echo "$volta_env" >> "/home/${USERNAME}/.zshrc"
        fi
    fi
    
    log_success "Volta environment configured!"
}

show_volta_usage() {
    log_info "Volta Node.js manager is ready!"
    echo ""
    echo "Usage:"
    echo "  volta install node@18    # Install specific Node.js version"
    echo "  volta install node@lts   # Install LTS version"
    echo "  volta list              # List installed versions"
    echo "  volta pin node@18       # Pin version for project"
    echo ""
    echo "Available tools:"
    echo "  node                    # Node.js runtime"
    echo "  npm                     # NPM package manager"
    echo "  yarn                    # Yarn package manager" 
    echo "  pnpm                    # PNPM package manager"
    echo ""
    log_info "For more info: https://volta.sh/"
}

cleanup() {
    remove_lock_file "$LOCK_FILE"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "Starting Volta installation..."
    
    install_volta
    setup_volta_environment
    show_volta_usage
    
    log_success "Volta installation completed successfully!"
fi
