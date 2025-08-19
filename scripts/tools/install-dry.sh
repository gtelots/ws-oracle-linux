#!/bin/bash
# -----------------------------------------------------------------------------
# Dry (Docker UI) Installation Script
# -----------------------------------------------------------------------------
# This script installs Dry terminal UI for Docker management
# -----------------------------------------------------------------------------

set -euo pipefail

# Function to log messages
log() {
    echo "==> $1"
}

# Function to download and install binary from GitHub releases
install_github_binary() {
    local repo="$1"
    local version="$2"
    local binary_name="$3"
    local archive_pattern="$4"
    local extract_path="${5:-$binary_name}"
    
    log "Installing $binary_name v$version from $repo"
    
    local download_url="https://github.com/$repo/releases/download/v$version/$archive_pattern"
    local temp_file="/tmp/${binary_name}.tgz"
    
    curl -fsSL -o "$temp_file" "$download_url"
    
    if [[ "$archive_pattern" == *.tar.gz ]] || [[ "$archive_pattern" == *.tgz ]]; then
        tar -xzf "$temp_file" -C /tmp
        if [ -f "/tmp/$extract_path" ]; then
            mv "/tmp/$extract_path" "/usr/local/bin/$binary_name"
        else
            find /tmp -name "$binary_name" -type f -exec mv {} "/usr/local/bin/$binary_name" \;
        fi
    elif [[ "$archive_pattern" == *.zip ]]; then
        unzip -q "$temp_file" -d /tmp
        mv "/tmp/$extract_path" "/usr/local/bin/$binary_name"
    else
        # Direct binary download
        mv "$temp_file" "/usr/local/bin/$binary_name"
    fi
    
    chmod +x "/usr/local/bin/$binary_name"
    rm -f "$temp_file"
    rm -rf /tmp/*linux* /tmp/*amd64* 2>/dev/null || true
}

# Install Dry (Docker UI)
install_dry() {
    if [ "${INSTALL_DRY:-0}" = "1" ]; then
        local version="${DRY_VERSION:-0.11.2}"
        install_github_binary "moncho/dry" "$version" "dry" "dry-linux-amd64"
        log "Dry (Docker UI) v$version installed successfully"
        log "Note: Use 'dry' command to launch Docker terminal UI"
    else
        log "Skipping Dry (Docker UI) installation"
    fi
}

# Run installation
install_dry
