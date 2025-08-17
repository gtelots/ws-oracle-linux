#!/bin/bash
# =============================================================================
# Task Runner Installation Script
# =============================================================================

set -euo pipefail

LOCK_FILE="/usr/local/share/install-locks/task.lock"

install_task() {
    if [ "${INSTALL_TASK:-1}" = "1" ]; then
        # Check if already installed
        if [ -f "$LOCK_FILE" ]; then
            echo "==> Task already installed, skipping"
            return 0
        fi
        
        local version="${TASK_VERSION:-3.44.1}"
        echo "==> Installing Task v${version}"
        
        # Create lock directory
        mkdir -p "$(dirname "$LOCK_FILE")"
        
        # Download and install task
        curl -fsSL -o /tmp/task.tgz "https://github.com/go-task/task/releases/download/v${version}/task_linux_amd64.tar.gz"
        tar -xzf /tmp/task.tgz -C /usr/local/bin task
        rm -f /tmp/task.tgz
        
        # Create lock file
        echo "Task v${version} installed on $(date)" > "$LOCK_FILE"
        
        echo "==> Task v${version} installed successfully"
    else
        echo "==> Skipping Task installation"
    fi
}

install_task
