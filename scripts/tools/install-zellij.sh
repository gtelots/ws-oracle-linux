#!/bin/bash

# =============================================================================
# Install Zellij - A terminal workspace with batteries included
# https://github.com/zellij-org/zellij
# =============================================================================

set -euo pipefail

# Load shared functions  
# shellcheck source=../common/functions.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common/functions.sh"

# Configuration
readonly TOOL_NAME="zellij"
readonly VERSION="${ZELLIJ_VERSION:-0.43.1}"
readonly GITHUB_REPO="zellij-org/zellij"
readonly LOCK_FILE="/tmp/install-zellij.lock"

# Global variables
tmp_dir=""

# Lock file management
cleanup() {
    if [[ -f "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE"
    fi
    if [[ -n "${tmp_dir:-}" && -d "$tmp_dir" ]]; then
        rm -rf "$tmp_dir"
    fi
}
trap cleanup EXIT

install_zellij() {
    log_info "Installing Zellij v${VERSION}..."
    
    # Create lock file
    if [[ -f "$LOCK_FILE" ]]; then
        log_error "Zellij installation already in progress"
        return 1
    fi
    echo $$ > "$LOCK_FILE"
    
    # Check if already installed
    if command -v zellij >/dev/null 2>&1; then
        local current_version
        current_version=$(zellij --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        if [[ "$current_version" == "$VERSION" ]]; then
            log_success "Zellij v${VERSION} is already installed"
            return 0
        else
            log_info "Upgrading Zellij from v${current_version} to v${VERSION}"
        fi
    fi
    
    # Download URL (fixed for x86_64)
    local download_url="https://github.com/zellij-org/zellij/releases/download/v0.43.1/zellij-x86_64-unknown-linux-musl.tar.gz"
    tmp_dir=$(mktemp -d)
    local archive_file="$tmp_dir/zellij.tar.gz"
    
    log_info "Downloading Zellij v${VERSION} for x86_64..."
    if ! curl -fsSL "$download_url" -o "$archive_file"; then
        log_error "Failed to download Zellij from: $download_url"
        return 1
    fi
    
    log_info "Extracting Zellij..."
    if ! tar -xzf "$archive_file" -C "$tmp_dir"; then
        log_error "Failed to extract Zellij archive"
        return 1
    fi
    
    # Find the zellij binary
    local zellij_binary
    zellij_binary=$(find "$tmp_dir" -name "zellij" -type f | head -1)
    if [[ ! -f "$zellij_binary" ]]; then
        log_error "Zellij binary not found in extracted archive"
        return 1
    fi
    
    # Install to /usr/local/bin
    log_info "Installing Zellij to /usr/local/bin..."
    if [[ $EUID -eq 0 ]]; then
        cp "$zellij_binary" /usr/local/bin/zellij
        chmod +x /usr/local/bin/zellij
    else
        sudo cp "$zellij_binary" /usr/local/bin/zellij
        sudo chmod +x /usr/local/bin/zellij
    fi
    
    # Verify installation
    if command -v zellij >/dev/null 2>&1; then
        local installed_version
        installed_version=$(zellij --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        log_success "Zellij v${installed_version} installed successfully!"
    else
        log_error "Zellij installation verification failed"
        return 1
    fi
}

setup_zellij_config() {
    log_info "Setting up Zellij configuration..."
    
    local config_dir="$HOME/.config/zellij"
    local config_file="$config_dir/config.kdl"
    
    # Create config directory
    mkdir -p "$config_dir"
    
    # Create basic configuration
    cat > "$config_file" << 'EOF'
// Zellij Configuration
// For more info: https://zellij.dev/documentation/

// Default shell
default_shell "zsh"

// Default mode
default_mode "normal"

// Theme
theme "default"

// Simplified UI
simplified_ui true

// Pane frames
pane_frames true

// Auto layout
auto_layout true

// Session serialization
session_serialization false

// Plugin aliases
plugins {
    tab-bar { path "tab-bar"; }
    status-bar { path "status-bar"; }
    strider { path "strider"; }
    compact-bar { path "compact-bar"; }
}

// UI configuration
ui {
    pane_frames {
        rounded_corners true
        hide_session_name false
    }
}

// Key bindings (vim-style)
keybinds {
    normal {
        bind "Alt h" { MoveFocus "Left"; }
        bind "Alt l" { MoveFocus "Right"; }
        bind "Alt j" { MoveFocus "Down"; }
        bind "Alt k" { MoveFocus "Up"; }
        bind "Alt =" { Resize "Increase"; }
        bind "Alt -" { Resize "Decrease"; }
        bind "Alt [" { PreviousSwapLayout; }
        bind "Alt ]" { NextSwapLayout; }
    }
    
    shared_except "locked" {
        bind "Ctrl g" { SwitchToMode "Locked"; }
        bind "Ctrl q" { Quit; }
        bind "Alt n" { NewPane; }
        bind "Alt i" { MoveTab "Left"; }
        bind "Alt o" { MoveTab "Right"; }
        bind "Alt t" { NewTab; }
        bind "Alt w" { CloseTab; }
        bind "Alt f" { ToggleFloatingPanes; }
        bind "Alt z" { TogglePaneFrames; }
    }
}

// Layout templates
layouts {
    default_tab_template {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        children
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }
}
EOF
    
    log_success "Zellij configuration created at: $config_file"
}

create_zellij_aliases() {
    log_info "Creating Zellij aliases..."
    
    # Add aliases to shell configuration
    local alias_content='
# Zellij aliases
alias zj="zellij"
alias zja="zellij attach"
alias zjls="zellij list-sessions"
alias zjd="zellij delete-session"
alias zjk="zellij kill-all-sessions"

# Replace tmux commands with zellij
alias tmux="echo \"Use zellij instead: zj\""
alias tmux-ls="zellij list-sessions"
alias tmux-attach="zellij attach"
'
    
    # Add to .bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -q "Zellij aliases" "$HOME/.bashrc"; then
            echo "$alias_content" >> "$HOME/.bashrc"
            log_success "Added Zellij aliases to .bashrc"
        fi
    fi
    
    # Add to .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "Zellij aliases" "$HOME/.zshrc"; then
            echo "$alias_content" >> "$HOME/.zshrc"
            log_success "Added Zellij aliases to .zshrc"
        fi
    fi
}

# Main execution
main() {
    log_info "Starting Zellij installation..."
    
    if install_zellij; then
        setup_zellij_config
        create_zellij_aliases
        
        log_success "Zellij installation completed successfully!"
        
        # Show usage examples
        echo
        log_info "Usage examples:"
        echo "  zellij                    # Start new session"
        echo "  zellij attach session     # Attach to session"
        echo "  zellij list-sessions      # List all sessions"
        echo "  zellij kill-all-sessions  # Kill all sessions"
        echo ""
        log_info "Key bindings:"
        echo "  Alt + h/j/k/l           # Navigate panes"
        echo "  Alt + n                 # New pane"
        echo "  Alt + t                 # New tab"
        echo "  Alt + w                 # Close tab"
        echo "  Alt + f                 # Toggle floating panes"
        echo "  Ctrl + g                # Lock mode"
        echo "  Ctrl + q                # Quit"
        
    else
        log_error "Zellij installation failed!"
        return 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
