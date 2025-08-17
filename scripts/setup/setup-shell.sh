#!/bin/bash
# =============================================================================
# Shell Prompt & Environment Setup Script
# =============================================================================

set -euo pipefail

setup_shell_environment() {
    local username="${USERNAME:-dev}"
    local home_dir="/home/${username}"
    
    echo "==> Setting up modern shell environment for ${username}"
    
    # Switch to the target user
    sudo -u "${username}" bash << 'EOF'
    # Download and install Starship prompt
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
    
    # Download and install Zinit (Zsh plugin manager)
    curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh | bash -s -- -y
    
    # Configure Zsh with essential plugins
    {
        echo ''
        # Conditionally add Volta (Node.js) environment if enabled
        if [ "${INSTALL_VOLTA:-0}" = "1" ]; then
            echo '# ==> Volta (Node.js version manager) initialization'
            echo 'export VOLTA_HOME="$HOME/.volta"'
            echo 'export PATH="$VOLTA_HOME/bin:$PATH"'
            echo ''
        fi
        echo '# ==> Essential Zsh plugins for enhanced shell experience'
        echo 'zinit load "zsh-users/zsh-syntax-highlighting"  # Syntax highlighting'
        echo 'zinit load "zsh-users/zsh-completions"          # Additional completions'
        echo 'zinit load "zsh-users/zsh-autosuggestions"      # Fish-like autosuggestions'
        echo 'zinit load "zsh-users/zsh-history-substring-search"  # History search'
        echo 'zinit load "Aloxaf/fzf-tab"                     # Replace tab completion with fzf'
        echo 'zinit load "hlissner/zsh-autopair"              # Auto-close quotes and brackets'
        echo 'zinit load "MichaelAquilina/zsh-you-should-use" # Remind about existing aliases'
        echo ''
        echo '# ==> Modern shell integrations'
        echo 'command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"'
        echo 'command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"'
        echo 'command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"'
        echo ''
        echo '# ==> Useful aliases for development workflow'
        echo 'alias ll="eza -lha --group-directories-first"   # Better ls with details'
        echo 'alias ls="eza"                                  # Modern ls replacement'
        echo 'alias cat="bat --paging=never"                 # Syntax-highlighted cat'
        echo 'alias vi="nvim"                                # Use Neovim instead of vi'
        echo 'alias vim="nvim"                               # Use Neovim instead of vim'
        echo 'alias lg="lazygit"                             # Git TUI shortcut'
        echo 'alias ld="lazydocker"                          # Docker TUI shortcut'
        echo ''
    } >> ~/.zshrc
    
    # Set up Starship with a beautiful preset theme
    mkdir -p ~/.config
    starship preset nerd-font-symbols -o ~/.config/starship.toml
    
    # Initialize Zsh environment (set terminal type to fix issues)
    export TERM=xterm-256color
    zsh -c "source ~/.zshrc" || true
EOF
    
    echo "==> Shell environment setup completed successfully"
}

setup_shell_environment
