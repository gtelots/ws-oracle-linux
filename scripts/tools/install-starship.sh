#!/bin/bash

# =============================================================================
# Starship Prompt Installation Script
# A fast, customizable prompt for any shell
# =============================================================================

set -euo pipefail

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly COMMON_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/common"

# Source common functions
if [[ -f "$COMMON_DIR/functions.sh" ]]; then
    # shellcheck source=../../common/functions.sh
    source "$COMMON_DIR/functions.sh"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[SUCCESS] ✅ $1"; }
    log_error() { echo "[ERROR] ❌ $1"; }
    log_warning() { echo "[WARNING] ⚠️ $1"; }
fi

# Configuration
readonly TOOL_NAME="starship"
readonly VERSION="${STARSHIP_VERSION:-1.17.1}"
readonly LOCK_FILE="/tmp/install-starship.lock"
readonly INSTALL_MARKER="/usr/local/bin/.starship-installed"

# Lock file management
cleanup() {
    cleanup_on_exit "$LOCK_FILE"
}
trap cleanup EXIT

# Check if Starship is already installed
if [[ -f "$INSTALL_MARKER" ]]; then
    log_info "Starship is already installed, skipping..."
    exit 0
fi

# Create lock file
if ! (set -C; echo $$ > "$LOCK_FILE") 2>/dev/null; then
    log_warn "Starship installation already in progress"
    exit 1
fi

# Cleanup lock file on exit
trap 'rm -f "$LOCK_FILE"' EXIT

install_starship() {
    log_info "Installing Starship prompt..."
    
    # Download and install Starship using official installer
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
    
    # Verify installation
    if command -v starship >/dev/null 2>&1; then
        local version
        version=$(starship --version)
        log_info "Starship installed successfully: $version"
        
        # Create installation marker
        echo "Starship installed on $(date)" > "$INSTALL_MARKER"
        
        return 0
    else
        log_error "Starship installation failed"
        return 1
    fi
}

setup_starship_config() {
    local config_dir="$HOME/.config"
    local starship_config="$config_dir/starship.toml"
    
    # Create config directory if it doesn't exist
    mkdir -p "$config_dir"
    
    # Create a basic Starship configuration
    cat > "$starship_config" << 'EOF'
# Starship Configuration
# Get editor completions based on the config schema
"$schema" = 'https://starship.rs/config-schema.json'

# Inserts a blank line between shell prompts
add_newline = true

# Replace the '❯' symbol in the prompt with '➜'
[character]
success_symbol = '[➜](bold green)'
error_symbol = '[➜](bold red)'

# Disable the package module, hiding it from the prompt completely
[package]
disabled = true

[git_branch]
symbol = "🌱 "
truncation_length = 20
truncation_symbol = "…"

[git_status]
ahead = "⇡${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
behind = "⇣${count}"

[docker_context]
symbol = "🐳 "

[python]
symbol = "🐍 "
python_binary = ["./venv/bin/python", "python", "python3", "python2"]

[nodejs]
symbol = "⬢ "

[rust]
symbol = "🦀 "

[kubernetes]
disabled = false
symbol = "☸ "

[directory]
truncation_length = 3
truncation_symbol = "…/"

[time]
disabled = false
format = '🕙[\[ $time \]]($style) '
time_format = "%T"
utc_time_offset = "+7"

[cmd_duration]
min_time = 2_000
format = "underwent [$duration](bold yellow)"
EOF

    log_info "Starship configuration created at: $starship_config"
}

main() {
    log_info "Starting Starship installation..."
    
    # Install Starship
    if install_starship; then
        # Setup configuration
        setup_starship_config
        
        log_info "Starship installation completed successfully"
        log_info "Add 'eval \"\$(starship init bash)\"' or 'eval \"\$(starship init zsh)\"' to your shell config"
    else
        log_error "Starship installation failed"
        exit 1
    fi
}

# Only run if called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
