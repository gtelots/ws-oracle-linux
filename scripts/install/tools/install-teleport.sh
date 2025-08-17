#!/bin/bash
# -----------------------------------------------------------------------------
# Teleport CLI Installation Script
# -----------------------------------------------------------------------------
# This script installs Teleport CLI for secure access and identity-aware proxy
# -----------------------------------------------------------------------------

set -euo pipefail

# Function to log messages
log() {
    echo "==> $1"
}

# Install Teleport CLI
install_teleport() {
    if [ "${INSTALL_TELEPORT:-0}" = "1" ]; then
        local version="${TELEPORT_VERSION:-17.1.5}"
        log "Installing Teleport CLI v$version"
        
        # Download and install Teleport
        local download_url="https://get.gravitational.com/teleport-v${version}-linux-amd64-bin.tar.gz"
        curl -fsSL -o /tmp/teleport.tar.gz "$download_url"
        tar -xzf /tmp/teleport.tar.gz -C /tmp
        mv /tmp/teleport/tsh /usr/local/bin/tsh
        mv /tmp/teleport/tctl /usr/local/bin/tctl
        chmod +x /usr/local/bin/tsh /usr/local/bin/tctl
        rm -rf /tmp/teleport*
        
        log "Teleport CLI v$version installed successfully"
        log "Note: Use 'tsh' for client operations and 'tctl' for admin tasks"
    else
        log "Skipping Teleport CLI installation"
    fi
}

# Run installation
install_teleport
