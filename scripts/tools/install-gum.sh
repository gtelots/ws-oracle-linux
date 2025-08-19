#!/bin/bash

# =============================================================================
# Install Gum - A tool for glamorous shell scripts
# https://github.com/charmbracelet/gum
# =============================================================================

set -euo pipefail

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly COMMON_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/common"

# Source common functions if available
if [[ -f "$COMMON_DIR/functions.sh" ]]; then
    # shellcheck source=../../common/functions.sh
    source "$COMMON_DIR/functions.sh"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[SUCCESS] ✅ $1"; }
    log_error() { echo "[ERROR] ❌ $1"; }
    log_warning() { echo "[WARNING] ⚠️ $1"; }
fi

# Configuration
readonly TOOL_NAME="gum"
readonly VERSION="${GUM_VERSION:-0.16.2}"
readonly GITHUB_REPO="charmbracelet/gum"
readonly LOCK_FILE="/tmp/install-gum.lock"

# Lock file management
cleanup() {
    if [[ -f "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE"
    fi
}
trap cleanup EXIT

install_gum() {
    log_info "Installing Gum v${VERSION}..."
    
    # Create lock file
    if [[ -f "$LOCK_FILE" ]]; then
        log_error "Gum installation already in progress"
        return 1
    fi
    echo $$ > "$LOCK_FILE"
    
    # Check if already installed
    if command -v gum >/dev/null 2>&1; then
        local current_version
        current_version=$(gum --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        if [[ "$current_version" == "$VERSION" ]]; then
            log_success "Gum v${VERSION} is already installed"
            return 0
        else
            log_info "Upgrading Gum from v${current_version} to v${VERSION}"
        fi
    fi
    
    # Download URL (hardcoded for x86_64)
    local download_url="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/gum_${VERSION}_Linux_x86_64.tar.gz"
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local archive_file="$tmp_dir/gum.tar.gz"
    
    # Cleanup temp directory on exit
    cleanup() {
        if [[ -n "${tmp_dir:-}" && -d "$tmp_dir" ]]; then
            rm -rf "$tmp_dir" 2>/dev/null || true
        fi
    }
    trap cleanup EXIT ERR
    
    log_info "Downloading Gum v${VERSION} for x86_64..."
    if ! curl -fsSL "$download_url" -o "$archive_file"; then
        log_error "Failed to download Gum from: $download_url"
        return 1
    fi
    
    log_info "Extracting Gum..."
    if ! tar -xzf "$archive_file" -C "$tmp_dir"; then
        log_error "Failed to extract Gum archive"
        return 1
    fi
    
    # Find the gum binary
    local gum_binary
    gum_binary=$(find "$tmp_dir" -name "gum" -type f | head -1)
    if [[ ! -f "$gum_binary" ]]; then
        log_error "Gum binary not found in extracted archive"
        return 1
    fi
    
    # Install to /usr/local/bin
    log_info "Installing Gum to /usr/local/bin..."
    if [[ $EUID -eq 0 ]]; then
        cp "$gum_binary" /usr/local/bin/gum
        chmod +x /usr/local/bin/gum
    else
        sudo cp "$gum_binary" /usr/local/bin/gum
        sudo chmod +x /usr/local/bin/gum
    fi
    
    # Verify installation
    if command -v gum >/dev/null 2>&1; then
        local installed_version
        installed_version=$(gum --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        log_success "Gum v${installed_version} installed successfully!"
        
        # Test gum functionality
        if gum style "Gum is working! 🎉" --foreground="#04B575" --border-foreground="#04B575" --border="thick" --align="center" --width=30 2>/dev/null; then
            log_success "Gum is fully functional!"
        else
            log_warning "Gum installed but some features may not work properly"
        fi
    else
        log_error "Gum installation verification failed"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting Gum installation..."
    
    if install_gum; then
        log_success "Gum installation completed successfully!"
        
        # Show usage example
        echo
        log_info "Example usage:"
        echo "  gum style 'Hello, World!' --foreground='#04B575'"
        echo "  gum input --placeholder 'Enter your name...'"
        echo "  gum confirm 'Are you sure?'"
        echo "  gum spin --spinner dot --title 'Loading...' -- sleep 3"
        
    else
        log_error "Gum installation failed!"
        return 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
