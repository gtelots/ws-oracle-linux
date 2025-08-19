#!/bin/bash

# =============================================================================
# Gomplate Installation Script
# A template engine for Go with extensive data source support
# https://github.com/hairyhenderson/gomplate
# =============================================================================

set -euo pipefail

# Load shared functions
# shellcheck source=../common/functions.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common/functions.sh"

# Configuration
readonly TOOL_NAME="gomplate"
readonly VERSION="${GOMPLATE_VERSION:-v4.3.3}"
readonly GITHUB_REPO="hairyhenderson/gomplate"
readonly LOCK_FILE="/tmp/install-gomplate.lock"

# Global cleanup
trap cleanup EXIT

install_gomplate() {
    log_info "Installing Gomplate ${VERSION}..."
    
    # Create lock file
    create_lock_file "$LOCK_FILE" "Gomplate installation"
    
    # Check if already installed
    if is_tool_installed gomplate --version; then
        local current_version
        current_version=$(gomplate --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        if [[ "$current_version" == "$VERSION" ]]; then
            log_success "Gomplate ${VERSION} is already installed"
            return 0
        else
            log_info "Upgrading Gomplate from ${current_version} to ${VERSION}"
        fi
    fi
    
    # Download URL (hardcoded for x86_64 Linux)
    local download_url="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/gomplate_linux-amd64"
    
    log_info "Downloading Gomplate ${VERSION} for x86_64..."
    if ! download_file "$download_url" "/usr/local/bin/gomplate"; then
        log_error "Failed to download Gomplate from: $download_url"
        return 1
    fi
    
    # Make executable
    log_info "Setting executable permissions..."
    chmod +x /usr/local/bin/gomplate
    
    # Verify installation
    if command -v gomplate >/dev/null 2>&1; then
        local installed_version
        installed_version=$(gomplate --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        log_success "Gomplate ${installed_version} installed successfully!"
        
        # Show usage examples
        show_gomplate_usage
    else
        log_error "Gomplate installation verification failed"
        return 1
    fi
}

show_gomplate_usage() {
    log_info "Usage examples:"
    echo "  gomplate --help                    # Show help"
    echo "  gomplate -f template.tmpl          # Process template file"
    echo "  echo '{{.Env.USER}}' | gomplate    # Use environment variables"
    echo "  gomplate -d config=config.yaml     # Use data sources"
    echo ""
    log_info "For more information: https://docs.gomplate.ca/"
}

cleanup() {
    remove_lock_file "$LOCK_FILE"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "Starting Gomplate installation..."
    install_gomplate
    log_success "Gomplate installation completed successfully!"
fi
