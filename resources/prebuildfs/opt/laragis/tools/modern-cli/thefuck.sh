#!/usr/bin/env bash
# =============================================================================
# thefuck - Corrects errors in previous console commands
# =============================================================================
# DESCRIPTION: Magnificent app which corrects your previous console command
# URL: https://github.com/nvbn/thefuck
# VERSION: v3.32
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="thefuck"
readonly TOOL_VERSION="${THEFUCK_VERSION:-3.32}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/thefuck.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    # Install thefuck via pipx for better isolation
    pipx install "thefuck==${TOOL_VERSION}" --global || {
        log_warn "pipx installation failed, trying pip3"
        pip3 install --user "thefuck==${TOOL_VERSION}"
    }
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "thefuck installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing thefuck v${TOOL_VERSION}..."
    
    is_installed && { log_info "thefuck is already installed"; return 0; }
    
    install_tool
    
    log_success "thefuck v${TOOL_VERSION} installed successfully"
}

main "$@"
