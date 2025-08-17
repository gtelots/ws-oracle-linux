#!/bin/bash
# =============================================================================
# DBeaver Installation Script
# =============================================================================

set -euo pipefail

install_dbeaver() {
    if [ "${INSTALL_DBEAVER:-1}" = "1" ]; then
        local version="${DBEAVER_VERSION:-24.3.1}"
        
        echo "==> Installing DBeaver Community Edition v${version}"
        
        # Install Java (required for DBeaver)
        dnf -y install --setopt=install_weak_deps=False --nodocs \
            java-11-openjdk java-11-openjdk-headless
        
        # Download and install DBeaver
        curl -fsSL -o /tmp/dbeaver.rpm \
            "https://github.com/dbeaver/dbeaver/releases/download/${version}/dbeaver-ce-${version}-linux.gtk.x86_64.rpm"
        
        dnf -y install /tmp/dbeaver.rpm
        rm -f /tmp/dbeaver.rpm
        
        # Create desktop entry for easy access
        mkdir -p /usr/share/applications
        cat > /usr/share/applications/dbeaver.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=DBeaver Community
Comment=Universal Database Tool
Exec=dbeaver
Icon=dbeaver
Terminal=false
Categories=Development;Database;
StartupWMClass=DBeaver
EOF
        
        echo "==> DBeaver Community Edition v${version} installed successfully"
        echo "    Launch with: dbeaver"
    else
        echo "==> Skipping DBeaver installation"
    fi
}

install_dbeaver
