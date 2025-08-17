#!/bin/bash
# =============================================================================
# Additional Development Tools Installation
# =============================================================================

set -euo pipefail

install_additional_packages() {
    echo "==> Installing additional development packages"
    
    # Install Python packages for system tools
    if [ "${INSTALL_PYTHON:-0}" = "1" ]; then
        python3.11 -m pip install --no-cache-dir speedtest-cli bpytop
        echo "==> Additional Python packages installed successfully"
    else
        echo "==> Skipping additional Python packages (Python not installed)"
    fi
}

install_additional_packages
