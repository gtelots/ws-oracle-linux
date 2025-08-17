#!/bin/bash
# -----------------------------------------------------------------------------
# Tailscale VPN Installation Script
# -----------------------------------------------------------------------------
# This script installs Tailscale VPN client for secure networking
# -----------------------------------------------------------------------------

set -euo pipefail

# Function to log messages
log() {
    echo "==> $1"
}

# Install Tailscale
install_tailscale() {
    if [ "${INSTALL_TAILSCALE:-0}" = "1" ]; then
        log "Installing Tailscale v${TAILSCALE_VERSION:-latest}"
        
        # Download and install Tailscale using official installer
        curl -fsSL https://tailscale.com/install.sh | sh
        
        # Create tailscale state directories
        mkdir -p /var/lib/tailscale /var/run/tailscale
        
        log "Tailscale installed successfully"
        log "Note: Use 'tailscale up' to connect to your tailnet"
    else
        log "Skipping Tailscale installation"
    fi
}

# Run installation
install_tailscale
