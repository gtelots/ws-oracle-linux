#!/bin/bash
# -----------------------------------------------------------------------------
# Ngrok Installation Script
# -----------------------------------------------------------------------------
# This script installs ngrok tunneling service
# -----------------------------------------------------------------------------

set -euo pipefail

# Function to log messages
log() {
    echo "==> $1"
}

# Install Ngrok
install_ngrok() {
    if [ "${INSTALL_NGROK:-0}" = "1" ]; then
        local version="${NGROK_VERSION:-3.18.4}"
        log "Installing Ngrok v$version"
        
        # Download and install ngrok
        local download_url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz"
        curl -fsSL -o /tmp/ngrok.tgz "$download_url"
        tar -xzf /tmp/ngrok.tgz -C /tmp
        mv /tmp/ngrok /usr/local/bin/ngrok
        chmod +x /usr/local/bin/ngrok
        rm -f /tmp/ngrok.tgz
        
        log "Ngrok v$version installed successfully"
    else
        log "Skipping Ngrok installation"
    fi
}

# Run installation
install_ngrok
