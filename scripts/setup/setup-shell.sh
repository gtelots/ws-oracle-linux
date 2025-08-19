#!/bin/bash

# =============================================================================
# Shell Environment Setup Script
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

setup_zsh_environment() {
    local username="${USERNAME:-dev}"
    local home_dir="/home/${username}"
    
    log_info "Setting up Zsh environment for ${username}"
    
    # Switch to the target user for setup
    sudo -u "${username}" bash << 'SHELL_EOF'
    # Set TERM to avoid tput errors during setup
    export TERM=xterm-256color
    
    # Install Zinit (Zsh plugin manager) if not already installed
    if [[ ! -d "${HOME}/.local/share/zinit" ]]; then
        echo "[SHELL-SETUP] Installing Zinit (Zsh plugin manager)..."
        curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh | bash -s -- -y
    fi
    
    # Configure Zsh with essential plugins and modern shell integrations
    echo "[SHELL-SETUP] Configuring Zsh with essential plugins..."
    {
        echo '# =============================================================================';
        echo '# Zsh Configuration - Enhanced Developer Environment';
        echo '# =============================================================================';
        echo '';
        echo '# Terminal configuration';
        echo 'export TERM=xterm-256color';
        echo '';
        echo '# Zinit initialization';
        echo 'ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"';
        echo '[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"';
        echo '[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"';
        echo 'source "${ZINIT_HOME}/zinit.zsh"';
        echo '';
        
        # Conditionally add Volta (Node.js) environment if enabled
        if [ "${INSTALL_VOLTA:-0}" = "1" ]; then
            echo '# ==> Volta (Node.js version manager) initialization';
            echo 'export VOLTA_HOME="$HOME/.volta"';
            echo 'export PATH="$VOLTA_HOME/bin:$PATH"';
            echo '';
        fi
        
        echo '# ==> Essential Zsh plugins for enhanced shell experience';
        echo 'zinit load "zsh-users/zsh-syntax-highlighting"  # Syntax highlighting for commands';
        echo 'zinit load "zsh-users/zsh-completions"          # Additional completion definitions';
        echo 'zinit load "zsh-users/zsh-autosuggestions"      # Fish-like autosuggestions';
        echo 'zinit load "zsh-users/zsh-history-substring-search"  # History search with arrows';
        echo 'zinit load "Aloxaf/fzf-tab"                     # Replace tab completion with fzf';
        echo 'zinit load "hlissner/zsh-autopair"              # Auto-close quotes and brackets';
        echo 'zinit load "MichaelAquilina/zsh-you-should-use" # Remind about existing aliases';
        echo '';
        echo '# ==> Modern shell integrations';
        echo 'command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"';
        echo 'command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"';
        echo 'command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"';
        echo '';
        echo '# ==> Development aliases for enhanced productivity';
        echo 'alias ll="eza -lha --group-directories-first"   # Better ls with details';
        echo 'alias ls="eza"                                  # Modern ls replacement';
        echo 'alias cat="bat --paging=never"                 # Syntax-highlighted cat';
        echo 'alias vi="nvim"                                # Use Neovim instead of vi';
        echo 'alias vim="nvim"                               # Use Neovim instead of vim';
        echo 'alias lg="lazygit"                             # Git TUI shortcut';
        echo 'alias ld="lazydocker"                          # Docker TUI shortcut';
        echo 'alias hosts="sudo hosts-manager.sh"           # Hosts file management';
        echo '';
        echo '# ==> History configuration for better command recall';
        echo 'HISTSIZE=10000';
        echo 'SAVEHIST=10000';
        echo 'setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS';
        echo 'setopt HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS HIST_IGNORE_SPACE';
        echo '';
        echo '# ==> Key bindings for history substring search';
        echo 'bindkey "^[[A" history-substring-search-up';
        echo 'bindkey "^[[B" history-substring-search-down';
        echo '';
        echo '# ==> FZF integration for fuzzy finding';
        echo '[[ -f /usr/share/fzf/shell/key-bindings.zsh ]] && source /usr/share/fzf/shell/key-bindings.zsh';
        echo '[[ -f /usr/share/fzf/shell/completion.zsh ]] && source /usr/share/fzf/shell/completion.zsh';
    } > ~/.zshrc
    
    echo "[SHELL-SETUP] Zsh configuration completed"
SHELL_EOF
}

setup_bash_environment() {
    local username="${USERNAME:-dev}"
    
    log_info "Setting up Bash environment as fallback for ${username}"
    
    # Configure bash with modern integrations
    sudo -u "${username}" bash << 'BASH_EOF'
    {
        echo '# =============================================================================';
        echo '# Bash Configuration - Enhanced Developer Environment';
        echo '# =============================================================================';
        echo '';
        echo '# Modern shell integrations (if available)';
        echo 'command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"';
        echo 'command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"';
        echo 'command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"';
        echo '';
        echo '# Development aliases';
        echo 'alias ll="eza -lha --group-directories-first 2>/dev/null || ls -lha"';
        echo 'alias ls="eza 2>/dev/null || ls --color=auto"';
        echo 'alias cat="bat --paging=never 2>/dev/null || cat"';
        echo 'alias vi="nvim"';
        echo 'alias vim="nvim"';
        echo 'alias lg="lazygit"';
        echo 'alias ld="lazydocker"';
        echo 'alias hosts="sudo hosts-manager.sh"';
        echo '';
        echo '# FZF integration for fuzzy finding';
        echo '[[ -f /usr/share/fzf/shell/key-bindings.bash ]] && source /usr/share/fzf/shell/key-bindings.bash';
        echo '[[ -f /usr/share/fzf/shell/completion.bash ]] && source /usr/share/fzf/shell/completion.bash';
        echo '';
        
        # Conditionally add Volta (Node.js) environment if enabled
        if [ "${INSTALL_VOLTA:-0}" = "1" ]; then
            echo '# Volta (Node.js version manager) initialization';
            echo 'export VOLTA_HOME="$HOME/.volta"';
            echo 'export PATH="$VOLTA_HOME/bin:$PATH"';
        fi
    } >> ~/.bashrc
    
    echo "[SHELL-SETUP] Bash configuration completed"
BASH_EOF
}

set_default_shell() {
    local username="${USERNAME:-dev}"
    
    log_info "Setting Zsh as default shell for ${username}"
    
    # Set Zsh as default shell for the user
    if command -v zsh >/dev/null 2>&1; then
        sudo chsh -s "$(which zsh)" "${username}"
        log_info "Default shell set to Zsh"
    else
        log_warn "Zsh not found, keeping default shell"
    fi
}

main() {
    log_info "Starting shell environment setup..."
    
    # Setup both Zsh and Bash environments
    setup_zsh_environment
    setup_bash_environment
    
    # Set Zsh as default shell
    set_default_shell
    
    log_info "Shell environment setup completed successfully"
}

# Only run if called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
