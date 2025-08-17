#!/bin/bash
# =============================================================================
# YQ Installation Script
# =============================================================================

set -euo pipefail

LOCK_FILE="/usr/local/share/install-locks/yq.lock"

install_yq() {
    if [ "${INSTALL_YQ:-1}" = "1" ]; then
        # Check if already installed
        if [ -f "$LOCK_FILE" ]; then
            echo "==> YQ already installed, skipping"
            return 0
        fi
        
        local version="${YQ_VERSION:-4.47.1}"
        echo "==> Installing YQ v${version}"
        
        # Create lock directory
        mkdir -p "$(dirname "$LOCK_FILE")"
        
        # Download and install yq
        curl -fsSL -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${version}/yq_linux_amd64"
        chmod +x /usr/local/bin/yq
        
        # Create lock file
        echo "YQ v${version} installed on $(date)" > "$LOCK_FILE"
        
        echo "==> YQ v${version} installed successfully"
    else
        echo "==> Skipping YQ installation"
    fi
}

install_yq
