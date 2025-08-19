#!/bin/bash
# -----------------------------------------------------------------------------
# Cloudflare CLI Installation Script
# -----------------------------------------------------------------------------
# This script installs Cloudflare CLI (cloudflared) for tunnel management
# -----------------------------------------------------------------------------

set -euo pipefail

# Function to log messages
log() {
    echo "==> $1"
}

# Install Cloudflare CLI (cloudflared)
install_cloudflare() {
    if [ "${INSTALL_CLOUDFLARE:-0}" = "1" ]; then
        local version="${CLOUDFLARE_VERSION:-2024.12.2}"
        log "Installing Cloudflare CLI v$version"
        
        # Download and install cloudflared
        local download_url="https://github.com/cloudflare/cloudflared/releases/download/${version}/cloudflared-linux-amd64"
        curl -fsSL -o /usr/local/bin/cloudflared "$download_url"
        chmod +x /usr/local/bin/cloudflared
        
        log "Cloudflare CLI v$version installed successfully"
        log "Note: Use 'cloudflared tunnel' to manage tunnels"
    else
        log "Skipping Cloudflare CLI installation"
    fi
}

# Run installation
install_cloudflare
