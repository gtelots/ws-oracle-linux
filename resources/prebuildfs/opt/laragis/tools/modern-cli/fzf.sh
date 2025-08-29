#!/usr/bin/env bash
# =============================================================================
# fzf - Command-line fuzzy finder
# =============================================================================
# DESCRIPTION: A command-line fuzzy finder
# URL: https://github.com/junegunn/fzf
# VERSION: v0.58.0
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="fzf"
readonly TOOL_VERSION="${FZF_VERSION:-0.58.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/fzf.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    local temp_dir="$(mktemp -d)"
    trap "rm -rf '${temp_dir}'" EXIT
    
    # Determine architecture
    local os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    local arch="$(uname -m)"
    
    case "$arch" in
        "x86_64") arch="amd64" ;;
        "aarch64") arch="arm64" ;;
        *) log_error "Unsupported architecture: $arch"; return 1 ;;
    esac
    
    # Download fzf binary
    local download_url="https://github.com/junegunn/fzf/releases/download/v${TOOL_VERSION}/fzf-${TOOL_VERSION}-${os}_${arch}.tar.gz"
    
    log_info "Downloading fzf from: ${download_url}"
    curl -fsSL "${download_url}" -o "${temp_dir}/fzf.tar.gz"
    
    # Extract and install
    cd "${temp_dir}"
    tar -xzf fzf.tar.gz
    
    # Install binary
    install -m 755 fzf /usr/local/bin/fzf
    
    # Install shell integrations
    mkdir -p /usr/local/share/fzf
    
    # Download shell integration files
    curl -fsSL "https://raw.githubusercontent.com/junegunn/fzf/v${TOOL_VERSION}/shell/completion.bash" -o /usr/local/share/fzf/completion.bash
    curl -fsSL "https://raw.githubusercontent.com/junegunn/fzf/v${TOOL_VERSION}/shell/completion.zsh" -o /usr/local/share/fzf/completion.zsh
    curl -fsSL "https://raw.githubusercontent.com/junegunn/fzf/v${TOOL_VERSION}/shell/key-bindings.bash" -o /usr/local/share/fzf/key-bindings.bash
    curl -fsSL "https://raw.githubusercontent.com/junegunn/fzf/v${TOOL_VERSION}/shell/key-bindings.zsh" -o /usr/local/share/fzf/key-bindings.zsh
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "fzf installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing fzf v${TOOL_VERSION}..."
    
    is_installed && { log_info "fzf is already installed"; return 0; }
    
    install_tool
    
    log_success "fzf v${TOOL_VERSION} installed successfully"
}

main "$@"
