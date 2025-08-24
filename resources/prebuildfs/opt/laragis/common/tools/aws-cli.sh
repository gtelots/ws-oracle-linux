#!/usr/bin/env bash
# AWS CLI Installation Script
# LaraGIS Development Environment - Oracle Linux 9
# Version: 1.0.0

set -euo pipefail

# Fallback logging functions (defined first)
log_info() { echo "$(date '+%H:%M:%S.%2N') INFO  ==> $*"; }
log_warn() { echo "$(date '+%H:%M:%S.%2N') WARN  ==> $*"; }
log_error() { echo "$(date '+%H:%M:%S.%2N') ERROR ==> $*"; }

# Configuration
INSTALL_AWS_CLI="${INSTALL_AWS_CLI:-true}"
AWS_CLI_VERSION="${AWS_CLI_VERSION:-latest}"
LOCK_DIR="/opt/laragis/data/locks"
LOCK_FILE="$LOCK_DIR/aws-cli.lock"

# Source logging library if available (override fallback)
if [[ -f "/opt/laragis/scripts/liblog.sh" ]]; then
    source "/opt/laragis/scripts/liblog.sh"
elif [[ -f "/opt/laragis/common/lib/liblog.sh" ]]; then
    source "/opt/laragis/common/lib/liblog.sh"
fi

# Create lock directory
mkdir -p "$LOCK_DIR"

# Check if AWS CLI is already installed
check_aws_cli_installed() {
    if [[ -f "$LOCK_FILE" ]]; then
        local installed_version
        installed_version=$(cat "$LOCK_FILE" 2>/dev/null || echo "unknown")
        log_info "AWS CLI already installed (version: $installed_version)"
        return 0
    fi
    
    if command -v aws &>/dev/null; then
        local current_version
        current_version=$(aws --version 2>&1 | awk '{print $1}' | cut -d'/' -f2 || echo "unknown")
        echo "$current_version" > "$LOCK_FILE"
        log_info "AWS CLI found and lock file created (version: $current_version)"
        return 0
    fi
    
    return 1
}

# Install AWS CLI v2
install_aws_cli() {
    log_info "Starting AWS CLI installation..."
    
    # Set architecture
    local arch
    case "$(uname -m)" in
        x86_64) arch="x86_64" ;;
        aarch64) arch="aarch64" ;;
        *) 
            log_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
    
    # Determine download URL
    local download_url
    if [[ "$AWS_CLI_VERSION" == "latest" ]]; then
        download_url="https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip"
    else
        download_url="https://awscli.amazonaws.com/awscli-exe-linux-${arch}-${AWS_CLI_VERSION}.zip"
    fi
    
    local temp_dir="/tmp/aws-cli-install"
    
    # Clean up any previous installation attempts
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"
    
    log_info "Downloading AWS CLI from: $download_url"
    
    # Download AWS CLI
    if ! curl -fsSL "$download_url" -o "$temp_dir/awscli.zip"; then
        log_error "Failed to download AWS CLI"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Install unzip if not available
    if ! command -v unzip &>/dev/null; then
        log_info "Installing unzip..."
        pkg-install unzip
    fi
    
    # Extract and install
    log_info "Extracting AWS CLI..."
    cd "$temp_dir"
    unzip -q awscli.zip
    
    log_info "Installing AWS CLI..."
    sudo ./aws/install --update 2>/dev/null || sudo ./aws/install
    
    # Verify installation
    if command -v aws &>/dev/null; then
        local installed_version
        installed_version=$(aws --version 2>&1 | awk '{print $1}' | cut -d'/' -f2 || echo "unknown")
        echo "$installed_version" > "$LOCK_FILE"
        log_info "✓ AWS CLI installed successfully (version: $installed_version)"
        
        # Test basic functionality
        log_info "Testing AWS CLI installation..."
        aws --version
    else
        log_error "AWS CLI installation failed - command not found"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    log_info "AWS CLI installation completed!"
}

# Main execution
main() {
    if [[ "$INSTALL_AWS_CLI" != "true" ]]; then
        log_info "AWS CLI installation is disabled (INSTALL_AWS_CLI=$INSTALL_AWS_CLI)"
        exit 0
    fi
    
    log_info "==> Starting AWS CLI installation process..."
    log_info "Configuration:"
    log_info "  - INSTALL_AWS_CLI: $INSTALL_AWS_CLI"
    log_info "  - AWS_CLI_VERSION: $AWS_CLI_VERSION"
    log_info "  - Lock file: $LOCK_FILE"
    
    # Check if already installed
    if check_aws_cli_installed; then
        log_info "AWS CLI installation skipped - already installed"
        exit 0
    fi
    
    # Install AWS CLI
    install_aws_cli
    
    log_info "AWS CLI installation process completed successfully!"
}

# Execute main function
main "$@"