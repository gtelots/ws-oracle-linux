#!/usr/bin/env bash
# AWS CLI Installation Script
# LaraGIS Development Environment - Oracle Linux 9
# Version: 1.1.0

set -euo pipefail

# Load common libraries
source /opt/laragis/lib/lib-install.sh

# Configuration
readonly FEATURE_NAME="aws-cli"
readonly INSTALL_AWS_CLI="${INSTALL_AWS_CLI:-true}"
readonly AWS_CLI_VERSION="${AWS_CLI_VERSION:-latest}"
readonly LOCK_FILE="/opt/laragis/features/${FEATURE_NAME}.installed"

# Create metadata for AWS CLI installation
create_aws_metadata() {
  local version="$1"
  local install_method="$2"
  
  local additional_data
  additional_data=$(cat << EOF
{
  "binary_path": "/usr/local/bin/aws",
  "install_path": "/usr/local/aws-cli/",
  "architecture": "$(install_detect_architecture)",
  "version_output": "$(aws --version 2>&1 || echo 'unknown')"
}
EOF
)
  
  metadata_create "$FEATURE_NAME" "$version" "$install_method" "unknown" "$additional_data"
}

# Check if AWS CLI is already installed
check_aws_cli_installed() {
  if metadata_is_installed "$FEATURE_NAME"; then
    local installed_version
    installed_version=$(metadata_get_version "$FEATURE_NAME")
    info "AWS CLI already installed (version: $installed_version)"
    return 0
  fi
  
  if command -v aws &>/dev/null; then
    local current_version
    current_version=$(aws --version 2>&1 | awk '{print $1}' | cut -d'/' -f2 || echo "unknown")
    
    # Create metadata for existing installation
    create_aws_metadata "$current_version" "pre-existing" > "$LOCK_FILE"
    info "AWS CLI found and lock file created (version: $current_version)"
    return 0
  fi
  
  return 1
}

# Install AWS CLI v2
install_aws_cli() {
  info "Starting AWS CLI installation..."
  
  # Set architecture
  local arch
  arch=$(install_detect_architecture)
  
  # Map to AWS CLI architecture naming
  case "$arch" in
    x86_64) arch="x86_64" ;;
    arm64) arch="aarch64" ;;
    *) 
      error "Unsupported architecture for AWS CLI: $arch"
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
  
  local temp_dir
  temp_dir=$(install_create_temp_dir)
  
  info "Downloading AWS CLI from: $download_url"
  
  # Download AWS CLI
  if ! install_download "$download_url" "$temp_dir/awscli.zip"; then
    error "Failed to download AWS CLI"
    exit 1
  fi
  
  # Install unzip if not available
  if ! command -v unzip &>/dev/null; then
    info "Installing unzip..."
    pkg-install unzip
  fi
  
  # Extract and install
  info "Extracting AWS CLI..."
  cd "$temp_dir"
  unzip -q awscli.zip
    
    info "Installing AWS CLI..."
    sudo ./aws/install --update 2>/dev/null || sudo ./aws/install
    
    # Verify installation
    if command -v aws &>/dev/null; then
        local installed_version
        installed_version=$(aws --version 2>&1 | awk '{print $1}' | cut -d'/' -f2 || echo "unknown")
        
        # Create metadata and save to lock file
        create_aws_metadata "$installed_version" "binary-download" > "$LOCK_FILE"
        info "✓ AWS CLI installed successfully (version: $installed_version)"
        
        # Test basic functionality
        info "Testing AWS CLI installation..."
        aws --version
    else
        error "AWS CLI installation failed - command not found"
        exit 1
    fi
    
    info "AWS CLI installation completed!"
}

# Main execution
main() {
  if [[ "$INSTALL_AWS_CLI" != "true" ]]; then
    info "AWS CLI installation is disabled (INSTALL_AWS_CLI=$INSTALL_AWS_CLI)"
    exit 0
  fi
  
  info "==> Starting AWS CLI installation process..."
  info "Configuration:"
  info "  - INSTALL_AWS_CLI: $INSTALL_AWS_CLI"
  info "  - AWS_CLI_VERSION: $AWS_CLI_VERSION"
  info "  - Lock file: $LOCK_FILE"
  
  # Check if already installed
  if check_aws_cli_installed; then
    info "AWS CLI installation skipped - already installed"
    exit 0
  fi
  
  # Install AWS CLI
  install_aws_cli
  
  info "AWS CLI installation process completed successfully!"
}

# Execute main function
main "$@"