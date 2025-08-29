#!/usr/bin/env bash
# =============================================================================
# Bash Shell Setup
# =============================================================================
# DESCRIPTION: Configure Bash shell with modern features and shared aliases
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly BASH_VERSION="${BASH_VERSION:-5.1}"
readonly USER_HOME="/home/${USER_NAME}"
readonly BASH_CONFIG_DIR="${USER_HOME}/.config/bash"

configure_bashrc() {
    log_info "Configuring Bash configuration..."
    
    local bashrc_file="${USER_HOME}/.bashrc"
    
    # Backup existing .bashrc if it exists
    if [[ -f "${bashrc_file}" ]]; then
        cp "${bashrc_file}" "${bashrc_file}.backup"
        log_info "Backed up existing .bashrc to .bashrc.backup"
    fi
    
    # Create enhanced .bashrc configuration
    cat >> "${bashrc_file}" << 'EOF'

# =============================================================================
# Enhanced Bash Configuration for Oracle Linux Development Container
# =============================================================================

# History configuration
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
shopt -s checkwinsize

# Enable programmable completion features
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        . /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        . /etc/bash_completion
    fi
fi

# =============================================================================
# Environment Variables
# =============================================================================

# Editor configuration
export EDITOR='nvim'
export VISUAL='nvim'

# Path configuration
export PATH="$HOME/.local/bin:$PATH"

# Tool-specific configurations
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# =============================================================================
# Load Shared Aliases
# =============================================================================

# Source shared aliases with fallbacks for missing tools
if [[ -f "/opt/laragis/dotfiles/aliases.sh" ]]; then
    source "/opt/laragis/dotfiles/aliases.sh"
fi

# =============================================================================
# Functions
# =============================================================================

# Quick directory navigation with fzf
cdf() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git | fzf +m) && cd "$dir"
}

# Quick file editing with fzf
vf() {
    local file
    file=$(fd --type f --hidden --follow --exclude .git | fzf +m) && $EDITOR "$file"
}

# Git branch switching with fzf
gcof() {
    local branch
    branch=$(git branch --all | grep -v HEAD | sed 's/^..//' | fzf +m) && git checkout "$branch"
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [[ -f $1 ]]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# =============================================================================
# Tool Integrations
# =============================================================================

# Starship prompt (if available)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# Zoxide integration (if available)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# FZF integration (if available)
if command -v fzf >/dev/null 2>&1; then
    source /usr/local/share/fzf/key-bindings.bash 2>/dev/null
    source /usr/local/share/fzf/completion.bash 2>/dev/null
fi

# Thefuck integration (if available)
if command -v thefuck >/dev/null 2>&1; then
    eval $(thefuck --alias)
fi

# =============================================================================
# Welcome Message
# =============================================================================

# Display system information on shell startup (only for interactive shells)
if [[ $- == *i* ]]; then
    if command -v fastfetch >/dev/null 2>&1; then
        fastfetch
    elif command -v neofetch >/dev/null 2>&1; then
        neofetch
    fi
    
    echo "🐧 Oracle Linux Development Container (Bash)"
    echo "💡 Type 'task' to see available commands"
    echo "🐚 Switch to Zsh: zsh-switch"
    echo ""
fi
EOF
    
    # Set proper ownership and permissions
    chown "${USER_UID}:${USER_GID}" "${bashrc_file}"
    chmod 644 "${bashrc_file}"
    
    log_success "Bash configuration updated successfully"
}

setup_bash_completion() {
    log_info "Setting up enhanced bash completion..."
    
    # Create bash completion directory
    mkdir -p "${BASH_CONFIG_DIR}/completions"
    chown -R "${USER_UID}:${USER_GID}" "${BASH_CONFIG_DIR}"
    
    log_success "Bash completion setup completed"
}

verify_bash_setup() {
    log_info "Verifying Bash setup..."
    
    # Check Bash version
    if command -v bash >/dev/null 2>&1; then
        log_success "✅ Bash is available: $(bash --version | head -n1)"
    else
        log_error "❌ Bash is not available"
        return 1
    fi
    
    # Check Bash configuration
    if [[ -f "${USER_HOME}/.bashrc" ]]; then
        log_success "✅ Bash configuration is present"
    else
        log_warn "⚠️  Bash configuration is missing"
    fi
    
    # Check shared aliases
    if [[ -f "/opt/laragis/dotfiles/aliases.sh" ]]; then
        log_success "✅ Shared aliases are available"
    else
        log_warn "⚠️  Shared aliases are missing"
    fi
}

# Main function
main() {
    log_info "Setting up Bash shell..."
    
    # Configure Bash
    configure_bashrc
    setup_bash_completion
    
    # Verify setup
    verify_bash_setup
    
    log_success "Bash shell setup completed successfully"
    log_info "Enhanced Bash configuration with shared aliases is now active"
}

main "$@"
