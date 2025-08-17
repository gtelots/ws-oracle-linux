#!/bin/bash
# -----------------------------------------------------------------------------
# Terraform CLI Installation Script
# -----------------------------------------------------------------------------
# This script installs HashiCorp Terraform for infrastructure as code
# -----------------------------------------------------------------------------

set -euo pipefail

# Function to log messages
log() {
    echo "==> $1"
}

# Install Terraform CLI
install_terraform() {
    if [ "${INSTALL_TERRAFORM:-0}" = "1" ]; then
        local version="${TERRAFORM_VERSION:-1.10.3}"
        log "Installing Terraform CLI v$version"
        
        # Download and install Terraform
        local download_url="https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip"
        curl -fsSL -o /tmp/terraform.zip "$download_url"
        unzip -q /tmp/terraform.zip -d /tmp
        mv /tmp/terraform /usr/local/bin/terraform
        chmod +x /usr/local/bin/terraform
        rm -f /tmp/terraform.zip
        
        log "Terraform CLI v$version installed successfully"
    else
        log "Skipping Terraform CLI installation"
    fi
}

# Run installation
install_terraform
