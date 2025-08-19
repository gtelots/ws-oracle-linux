#!/bin/bash

# =============================================================================
# AWS CLI v2 Installation Script
# =============================================================================

set -euo pipefail

# Load shared functions
# shellcheck source=../common/functions.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common/functions.sh"

# Configuration
readonly TOOL_NAME="aws"
readonly VERSION="${AWS_CLI_VERSION:-2.15.30}"
readonly LOCK_FILE="/tmp/install-aws-cli.lock"
readonly INSTALL_MARKER="/usr/local/bin/.aws-cli-installed"

# Lock file management
cleanup() {
    cleanup_on_exit "$LOCK_FILE"
}
trap cleanup EXIT

main() {
    log_info "Installing AWS CLI v2..."
    
    # Check if already installed
    if [[ -f "$INSTALL_MARKER" ]]; then
        log_success "AWS CLI is already installed, skipping..."
        return 0
    fi
    
    # Create lock file
    if ! create_lock_file "$LOCK_FILE" "AWS CLI installation"; then
        return 1
    fi
    
    # Check if tool is already available
    if is_tool_installed "aws" "--version"; then
        touch "$INSTALL_MARKER"
        log_success "AWS CLI is already available in PATH"
        return 0
    fi
    
    # AWS CLI download URL (hardcoded for x86_64)
    local aws_cli_url="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
    
    # Create temporary directory for download
    local tmp_dir
    tmp_dir=$(mktemp -d)
    
    # Cleanup function
    cleanup_tmp() {
        if [[ -n "${tmp_dir:-}" && -d "$tmp_dir" ]]; then
            rm -rf "$tmp_dir"
        fi
    }
    trap cleanup_tmp EXIT
    
    # Download AWS CLI
    log_info "Downloading AWS CLI for x86_64 architecture..."
    curl -fsSL "$aws_cli_url" -o "$tmp_dir/awscliv2.zip"
    
    # Extract and install
    log_info "Extracting and installing AWS CLI..."
    cd "$tmp_dir"
    unzip -q awscliv2.zip
    
    # Install AWS CLI (will install to /usr/local/bin by default)
    ./aws/install
    
    # Verify installation
    if command -v aws >/dev/null 2>&1; then
        local version
        version=$(aws --version)
        log_info "AWS CLI installed successfully: $version"
        
        # Create installation marker
        touch "$INSTALL_MARKER"
        echo "AWS CLI v2 installed on $(date)" > "$INSTALL_MARKER"
    else
        log_error "AWS CLI installation failed - command not found"
        exit 1
    fi
    
    log_info "AWS CLI installation completed successfully"
}

# Only run if called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
