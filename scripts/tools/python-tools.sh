#!/bin/bash
# =============================================================================
# Python Development Tools Installation
# =============================================================================

set -euo pipefail

install_python_tools() {
    if [ "${INSTALL_PYTHON:-0}" = "1" ]; then
        echo "==> Installing Python development environment"
        
        # Install Python system packages
        dnf -y install --setopt=install_weak_deps=False --nodocs \
            python3.11 python3.11-pip python3.11-devel
        
        # Create symlinks for easier access
        ln -sf /usr/bin/python3.11 /usr/local/bin/python3
        ln -sf /usr/bin/python3.11 /usr/local/bin/python
        ln -sf /usr/bin/pip3.11 /usr/local/bin/pip3
        
        # Upgrade pip and essential packages
        python3.11 -m pip install --no-cache-dir -U pip setuptools wheel
        
        echo "==> Python development environment installed successfully"
    else
        echo "==> Skipping Python installation"
    fi
}

install_python_tools
