#!/usr/bin/env bash
# =============================================================================
# Zsh Shell Setup
# =============================================================================
# DESCRIPTION: Configure Zsh shell with modern features and plugins
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly ZSH_VERSION="${ZSH_VERSION:-5.9}"
readonly ZINIT_VERSION="${ZINIT_VERSION:-master}"
readonly USER_HOME="/home/${USER_NAME}"
readonly ZSH_CONFIG_DIR="${USER_HOME}/.config/zsh"
readonly ZINIT_DIR="${USER_HOME}/.local/share/zinit"

install_zsh() {
    log_info "Installing Zsh shell..."

    # Check if Zsh is already installed
    if command -v zsh >/dev/null 2>&1; then
        log_info "Zsh is already installed: $(zsh --version)"
        return 0
    fi

    # Install Zsh via package manager
    dnf -y install zsh

    # Verify installation
    if command -v zsh >/dev/null 2>&1; then
        log_success "Zsh installed successfully: $(zsh --version)"
    else
        log_error "Zsh installation failed"
        return 1
    fi
}

install_zinit() {
    log_info "Installing Zinit plugin manager..."

    # Check if Zinit is already installed
    if [[ -d "${ZINIT_DIR}" ]]; then
        log_info "Zinit is already installed"
        return 0
    fi

    # Create Zinit directory
    mkdir -p "${ZINIT_DIR}"
    chown "${USER_UID}:${USER_GID}" "${ZINIT_DIR}"

    # Download and install Zinit
    sudo -u "${USER_NAME}" bash -c "
        git clone https://github.com/zdharma-continuum/zinit.git '${ZINIT_DIR}/zinit.git'
    "

    if [[ -d "${ZINIT_DIR}/zinit.git" ]]; then
        log_success "Zinit installed successfully"
    else
        log_error "Zinit installation failed"
        return 1
    fi
}

setup_zinit_plugins() {
    log_info "Setting up Zinit plugin configuration..."

    # Zinit will handle plugin installation automatically via .zshrc
    # No need to manually clone repositories

    log_success "Zinit plugin configuration prepared"
}

configure_zshrc() {
    log_info "Configuring Zsh configuration..."

    local zshrc_file="${USER_HOME}/.zshrc"

    # Create modern .zshrc configuration with Zinit
    cat > "${zshrc_file}" << 'EOF'
# =============================================================================
# Zsh Configuration for Oracle Linux Development Container
# =============================================================================

# Zinit Plugin Manager Configuration
ZINIT_HOME="${HOME}/.local/share/zinit"

# Download Zinit if not present
if [[ ! -f ${ZINIT_HOME}/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "${ZINIT_HOME}" && command chmod g-rwX "${ZINIT_HOME}"
    command git clone https://github.com/zdharma-continuum/zinit "${ZINIT_HOME}/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

# Load Zinit
source "${ZINIT_HOME}/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load Oh My Zsh as a plugin for compatibility
zinit load "ohmyzsh/ohmyzsh"

# Load Oh My Zsh plugins via Zinit
zinit load "ohmyzsh/ohmyzsh" path:"plugins/git"
zinit load "ohmyzsh/ohmyzsh" path:"plugins/docker"
zinit load "ohmyzsh/ohmyzsh" path:"plugins/kubectl"
zinit load "ohmyzsh/ohmyzsh" path:"plugins/terraform"
zinit load "ohmyzsh/ohmyzsh" path:"plugins/ansible"
zinit load "ohmyzsh/ohmyzsh" path:"plugins/aws"
zinit load "ohmyzsh/ohmyzsh" path:"plugins/node"
zinit load "ohmyzsh/ohmyzsh" path:"plugins/npm"
zinit load "ohmyzsh/ohmyzsh" path:"plugins/python"
zinit load "ohmyzsh/ohmyzsh" path:"plugins/pip"
zinit load "ohmyzsh/ohmyzsh" path:"plugins/rust"
zinit load "ohmyzsh/ohmyzsh" path:"plugins/cargo"

# Load modern Zsh plugins
zinit load "zsh-users/zsh-autosuggestions"
zinit load "zsh-users/zsh-syntax-highlighting"
zinit load "zsh-users/zsh-completions"

# Load additional useful plugins
zinit load "zdharma-continuum/fast-syntax-highlighting"
zinit load "marlonrichert/zsh-autocomplete"

# =============================================================================
# Custom Configuration
# =============================================================================

# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Completion configuration
autoload -U compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

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
EOF

    # Set proper ownership and permissions
    chown "${USER_UID}:${USER_GID}" "${zshrc_file}"
    chmod 644 "${zshrc_file}"

    log_success "Zsh configuration created successfully"
}

setup_zsh_as_optional() {
    log_info "Setting up Zsh as optional shell..."

    # Add Zsh to available shells if not already present
    if ! grep -q "$(which zsh)" /etc/shells; then
        echo "$(which zsh)" >> /etc/shells
    fi

    # Create shell switching aliases in bashrc
    local bashrc_file="${USER_HOME}/.bashrc"

    # Add Zsh switching function to bashrc
    if ! grep -q "switch_to_zsh" "${bashrc_file}" 2>/dev/null; then
        cat >> "${bashrc_file}" << 'EOF'

# =============================================================================
# Shell Switching Functions
# =============================================================================

# Function to switch to Zsh
switch_to_zsh() {
    echo "🐚 Switching to Zsh shell..."
    exec zsh
}

# Alias for easy switching
alias zsh-switch='switch_to_zsh'
alias use-zsh='switch_to_zsh'

# Show available shells
show-shells() {
    echo "Available shells:"
    echo "  bash (current default)"
    echo "  zsh (modern shell with plugins)"
    echo ""
    echo "To switch to Zsh: zsh-switch"
    echo "To use Zsh temporarily: zsh"
}
EOF

        chown "${USER_UID}:${USER_GID}" "${bashrc_file}"
    fi

    log_success "Zsh configured as optional shell"
    log_info "Users can switch to Zsh using 'zsh-switch' or 'use-zsh' commands"
}

verify_zsh_setup() {
    log_info "Verifying Zsh setup..."

    # Check Zsh installation
    if command -v zsh >/dev/null 2>&1; then
        log_success "✅ Zsh is installed: $(zsh --version)"
    else
        log_error "❌ Zsh is not installed"
        return 1
    fi

    # Check Zinit installation
    if [[ -d "${ZINIT_DIR}/zinit.git" ]]; then
        log_success "✅ Zinit is installed"
    else
        log_warn "⚠️  Zinit is not installed"
    fi

    # Check Zsh configuration
    if [[ -f "${USER_HOME}/.zshrc" ]]; then
        log_success "✅ Zsh configuration is present"
    else
        log_warn "⚠️  Zsh configuration is missing"
    fi

    # Check Zinit plugins (will be installed on first Zsh run)
    log_info "Zsh plugins will be managed by Zinit"
}

# Main function
main() {
    log_info "Setting up Zsh shell..."

    # Install and configure Zsh
    install_zsh
    install_zinit
    setup_zinit_plugins
    configure_zshrc
    setup_zsh_as_optional

    # Verify setup
    verify_zsh_setup

    log_success "Zsh shell setup completed successfully"
    log_info "Zsh is available as an optional shell"
    log_info "Use 'zsh-switch' or 'use-zsh' to switch to Zsh"
}

main "$@"