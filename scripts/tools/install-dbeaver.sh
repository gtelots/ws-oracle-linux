#!/bin/bash
# =============================================================================
# DBeaver Installation Script
# =============================================================================

set -euo pipefail

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/functions.sh"

install_dbeaver() {
    if [ "${INSTALL_DBEAVER:-1}" = "1" ]; then
        local version="${DBEAVER_VERSION:-24.3.1}"
        
        log_install "DBeaver Community Edition" "$version"
        
        # Install Java (required for DBeaver) using our smart installer
        log_info "Installing Java dependencies..." "DBEAVER"
        install_packages java-11-openjdk java-11-openjdk-headless
        
        # Download and install DBeaver
        log_info "Downloading DBeaver v${version}..." "DBEAVER"
        download_file \
            "https://github.com/dbeaver/dbeaver/releases/download/${version}/dbeaver-ce-${version}-linux.gtk.x86_64.rpm" \
            "/tmp/dbeaver.rpm" \
            "DBeaver v${version}"
        
        log_info "Installing DBeaver package..." "DBEAVER"
        install_packages /tmp/dbeaver.rpm
        rm -f /tmp/dbeaver.rpm
        
        # Create desktop entry for easy access
        log_info "Creating desktop entry..." "DBEAVER"
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
        
        log_install_success "DBeaver Community Edition" "$version"
        log_info "Launch with: dbeaver" "DBEAVER"
    else
        log_install_skip "DBeaver" "INSTALL_DBEAVER=0"
    fi
}

install_dbeaver
