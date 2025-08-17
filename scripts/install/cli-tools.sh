#!/bin/bash
# =============================================================================
# CLI Tools Installation Orchestrator
# =============================================================================

set -euo pipefail

install_cli_tools() {
    echo "==> Installing CLI development tools"
    
    # Create install locks directory
    mkdir -p /usr/local/share/install-locks
    
    # Install individual CLI tools
    if [ -f "/usr/local/scripts/tools/install-task.sh" ]; then
        bash /usr/local/scripts/tools/install-task.sh
    fi
    
    if [ -f "/usr/local/scripts/tools/install-lazydocker.sh" ]; then
        bash /usr/local/scripts/tools/install-lazydocker.sh
    fi
    
    if [ -f "/usr/local/scripts/tools/install-lazygit.sh" ]; then
        bash /usr/local/scripts/tools/install-lazygit.sh
    fi
    
    if [ -f "/usr/local/scripts/tools/install-yq.sh" ]; then
        bash /usr/local/scripts/tools/install-yq.sh
    fi
    
    echo "==> CLI tools installation completed"
}

install_cli_tools
