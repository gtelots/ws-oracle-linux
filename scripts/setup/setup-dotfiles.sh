#!/bin/bash
# =============================================================================
# Dotfiles Setup Script
# =============================================================================

set -euo pipefail

setup_dotfiles() {
    local username="${USERNAME:-dev}"
    local home_dir="/home/${username}"
    
    echo "==> Setting up development dotfiles for ${username}"
    
    # Copy dotfiles to user home directory
    if [ -d "/tmp/dotfiles" ]; then
        # Copy Git configuration
        if [ -f "/tmp/dotfiles/.gitconfig" ]; then
            cp /tmp/dotfiles/.gitconfig "${home_dir}/.gitconfig"
            echo "==> Git configuration installed"
        fi
        
        # Copy Vim configuration
        if [ -f "/tmp/dotfiles/.vimrc" ]; then
            cp /tmp/dotfiles/.vimrc "${home_dir}/.vimrc"
            echo "==> Vim configuration installed"
        fi
        
        # Copy additional Bash configuration
        if [ -f "/tmp/dotfiles/.bashrc" ]; then
            cp /tmp/dotfiles/.bashrc "${home_dir}/.bashrc.extra"
            # Append source line to main bashrc if not already present
            if ! grep -q "source ~/.bashrc.extra" "${home_dir}/.bashrc"; then
                echo "source ~/.bashrc.extra" >> "${home_dir}/.bashrc"
            fi
            echo "==> Bash configuration installed"
        fi
        
        # Set proper ownership
        chown -R "${USER_UID:-1000}:${USER_GID:-1000}" "${home_dir}/.gitconfig" "${home_dir}/.vimrc" "${home_dir}/.bashrc.extra" 2>/dev/null || true
        
        # Clean up
        rm -rf /tmp/dotfiles
        
        echo "==> Dotfiles setup completed successfully"
    else
        echo "==> No dotfiles found to install"
    fi
}

setup_dotfiles
