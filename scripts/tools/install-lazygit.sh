#!/bin/bash
# =============================================================================
# LazyGit Installation Script
# =============================================================================

set -euo pipefail

LOCK_FILE="/usr/local/share/install-locks/lazygit.lock"

install_lazygit() {
    if [ "${INSTALL_LAZYGIT:-1}" = "1" ]; then
        # Check if already installed
        if [ -f "$LOCK_FILE" ]; then
            echo "==> LazyGit already installed, skipping"
            return 0
        fi
        
        local version="${LAZYGIT_VERSION:-0.54.2}"
        echo "==> Installing LazyGit v${version}"
        
        # Create lock directory
        mkdir -p "$(dirname "$LOCK_FILE")"
        
        # Download and install lazygit
        curl -fsSL -o /tmp/lazygit.tgz "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_x86_64.tar.gz"
        tar -xzf /tmp/lazygit.tgz -C /usr/local/bin lazygit
        rm -f /tmp/lazygit.tgz
        
        # Create lock file
        echo "LazyGit v${version} installed on $(date)" > "$LOCK_FILE"
        
        echo "==> LazyGit v${version} installed successfully"
    else
        echo "==> Skipping LazyGit installation"
    fi
}

install_lazygit
