#!/bin/bash
# -----------------------------------------------------------------------------
# WordPress CLI Installation Script
# -----------------------------------------------------------------------------
# This script installs WordPress CLI for WordPress development and management
# -----------------------------------------------------------------------------

set -euo pipefail

# Function to log messages
log() {
    echo "==> $1"
}

# Install WP CLI
install_wp_cli() {
    if [ "${INSTALL_WP_CLI:-0}" = "1" ]; then
        local version="${WP_CLI_VERSION:-2.12.0}"
        log "Installing WP CLI v$version"
        
        # Install PHP runtime (required for WP CLI)
        log "Installing PHP runtime dependencies"
        dnf -y install --setopt=install_weak_deps=False --nodocs \
            php-cli php-common php-json php-mbstring php-xml php-zip \
            php-curl php-gd php-mysqlnd php-pdo
        
        # Download WP CLI
        curl -fsSL -o /usr/local/bin/wp "https://github.com/wp-cli/wp-cli/releases/download/v${version}/wp-cli-${version}.phar"
        chmod +x /usr/local/bin/wp
        
        log "WP CLI v$version installed successfully"
        log "Note: Use 'wp' command for WordPress management"
    else
        log "Skipping WP CLI installation"
    fi
}

# Run installation
install_wp_cli
