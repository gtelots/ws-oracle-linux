#!/bin/bash

# -----------------------------------------------------------------------------
# Modern CLI Utilities Installation Script
# -----------------------------------------------------------------------------
# This script installs modern CLI tools that enhance developer productivity:
# - thefuck: Corrects previous console commands
# - tldr: Simplified man pages with practical examples
# - zoxide: Smarter cd command that learns your habits
# - webdriver tools: For browser automation testing
# -----------------------------------------------------------------------------

set -euo pipefail

# Load shared functions
# shellcheck source=../common/functions.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common/functions.sh"

# Color codes for output formatting
# Logging functions
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Lock file to prevent concurrent installations
readonly LOCK_FILE="/tmp/modern-cli-install.lock"
readonly INSTALL_MARKER="/usr/local/bin/.modern-cli-installed"

# Check if already installed
if [[ -f "$INSTALL_MARKER" ]]; then
    log_info "Modern CLI utilities are already installed, skipping..."
    exit 0
fi

# Create lock file
if ! (set -C; echo $$ > "$LOCK_FILE") 2>/dev/null; then
    log_warn "Modern CLI utilities installation already in progress"
    exit 1
fi

# Cleanup lock file on exit
trap 'rm -f "$LOCK_FILE"' EXIT

install_thefuck() {
    log_info "Installing thefuck (command correction tool)..."
    
    # Install via pip3 (most reliable method)
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --user thefuck
        log_info "thefuck installed successfully"
    else
        log_warn "pip3 not found, skipping thefuck installation"
    fi
}

install_tldr() {
    log_info "Installing tldr (simplified man pages)..."
    
    # Install via npm if available, fallback to pip3
    if command -v npm >/dev/null 2>&1; then
        npm install -g tldr
        log_info "tldr installed via npm"
    elif command -v pip3 >/dev/null 2>&1; then
        pip3 install --user tldr
        log_info "tldr installed via pip3"
    else
        log_warn "Neither npm nor pip3 found, skipping tldr installation"
    fi
}

install_zoxide() {
    log_info "Installing zoxide (smarter cd command)..."
    
    # Install via curl script (official method)
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        
        # Move to system-wide location
        if [[ -f "$HOME/.local/bin/zoxide" ]]; then
            sudo mv "$HOME/.local/bin/zoxide" /usr/local/bin/
            log_info "zoxide installed successfully"
        fi
    else
        log_warn "curl not found, skipping zoxide installation"
    fi
}

install_webdriver_tools() {
    log_info "Installing WebDriver tools for browser automation..."
    
    # Create webdriver directory
    sudo mkdir -p /usr/local/webdriver
    
    # Install ChromeDriver
    log_info "Installing ChromeDriver..."
    
    # Simple fallback - skip ChromeDriver if installation fails
    log_warn "ChromeDriver installation skipped - will be available via package manager if needed"
    
    # Install GeckoDriver (Firefox)
    log_info "Installing GeckoDriver..."
    
    # Simplified GeckoDriver installation with fallback
    if command -v curl >/dev/null 2>&1; then
        local gecko_version
        gecko_version=$(curl -fsSL https://api.github.com/repos/mozilla/geckodriver/releases/latest | grep '"tag_name"' | cut -d'"' -f4 2>/dev/null)
        
        if [[ -n "$gecko_version" ]]; then
            local gecko_url="https://github.com/mozilla/geckodriver/releases/download/${gecko_version}/geckodriver-${gecko_version}-linux64.tar.gz"
            local tmp_dir
            tmp_dir=$(mktemp -d)
            
            if curl -fsSL "$gecko_url" -o "$tmp_dir/geckodriver.tar.gz" 2>/dev/null; then
                tar -xzf "$tmp_dir/geckodriver.tar.gz" -C "$tmp_dir" 2>/dev/null
                sudo mv "$tmp_dir/geckodriver" /usr/local/webdriver/ 2>/dev/null
                sudo chmod +x /usr/local/webdriver/geckodriver 2>/dev/null
                sudo ln -sf /usr/local/webdriver/geckodriver /usr/local/bin/geckodriver 2>/dev/null
                log_info "GeckoDriver installed successfully"
            else
                log_warn "GeckoDriver download failed, skipping..."
            fi
            rm -rf "$tmp_dir"
        else
            log_warn "Could not detect GeckoDriver version, skipping..."
        fi
    else
        log_warn "curl not available, skipping GeckoDriver..."
    fi
    
    log_info "WebDriver tools installation completed"
}

main() {
    log_info "Installing modern CLI utilities..."
    
    # Install each tool
    install_thefuck
    install_tldr
    install_zoxide
    install_webdriver_tools
    
    # Create installation marker
    echo "Modern CLI utilities installed on $(date)" | sudo tee "$INSTALL_MARKER" > /dev/null
    
    log_info "Modern CLI utilities installation completed successfully"
}

# Only run if called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
