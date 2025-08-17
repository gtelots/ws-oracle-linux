#!/bin/bash
# =============================================================================
# LazyDocker Installation Script
# =============================================================================

set -euo pipefail

LOCK_FILE="/usr/local/share/install-locks/lazydocker.lock"

install_lazydocker() {
    if [ "${INSTALL_LAZYDOCKER:-1}" = "1" ]; then
        # Check if already installed
        if [ -f "$LOCK_FILE" ]; then
            echo "==> LazyDocker already installed, skipping"
            return 0
        fi
        
        local version="${LAZYDOCKER_VERSION:-0.24.1}"
        echo "==> Installing LazyDocker v${version}"
        
        # Create lock directory
        mkdir -p "$(dirname "$LOCK_FILE")"
        
        # Download and install lazydocker
        curl -fsSL -o /tmp/lazydocker.tgz "https://github.com/jesseduffield/lazydocker/releases/download/v${version}/lazydocker_${version}_Linux_x86_64.tar.gz"
        tar -xzf /tmp/lazydocker.tgz -C /usr/local/bin lazydocker
        rm -f /tmp/lazydocker.tgz
        
        # Create lock file
        echo "LazyDocker v${version} installed on $(date)" > "$LOCK_FILE"
        
        echo "==> LazyDocker v${version} installed successfully"
    else
        echo "==> Skipping LazyDocker installation"
    fi
}

install_lazydocker
