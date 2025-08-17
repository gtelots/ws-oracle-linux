#!/bin/bash
# -----------------------------------------------------------------------------
# Supervisor Installation Script
# -----------------------------------------------------------------------------
# This script installs Supervisor for process management
# -----------------------------------------------------------------------------

set -euo pipefail

# Function to log messages
log() {
    echo "==> $1"
}

# Install Supervisor
install_supervisor() {
    if [ "${INSTALL_SUPERVISOR:-0}" = "1" ]; then
        log "Installing Supervisor process manager"
        
        # Install supervisor via pip (Python package manager)
        python3.11 -m pip install --no-cache-dir supervisor
        
        # Create supervisor configuration directories
        mkdir -p /etc/supervisor/conf.d /var/log/supervisor
        
        log "Supervisor installed successfully"
        log "Note: Configuration will be set up during container setup"
    else
        log "Skipping Supervisor installation"
    fi
}

# Run installation
install_supervisor
