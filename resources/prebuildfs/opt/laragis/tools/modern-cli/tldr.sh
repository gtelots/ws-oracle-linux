#!/usr/bin/env bash
# =============================================================================
# tldr - Simplified and community-driven man pages
# =============================================================================
# DESCRIPTION: A collection of community-maintained help pages for command-line tools
# URL: https://github.com/tldr-pages/tldr
# VERSION: v3.4.0
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="tldr"
readonly TOOL_VERSION="${TLDR_VERSION:-3.4.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/tldr.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    # Install tldr via pipx for better isolation
    pipx install "tldr==${TOOL_VERSION}" --global || {
        log_warn "pipx installation failed, trying pip3"
        pip3 install --user "tldr==${TOOL_VERSION}"
    }
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "tldr installation verification failed"; return 1; }
    
    # Update tldr database
    tldr --update || log_warn "Failed to update tldr database"
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing tldr v${TOOL_VERSION}..."
    
    is_installed && { log_info "tldr is already installed"; return 0; }
    
    install_tool
    
    log_success "tldr v${TOOL_VERSION} installed successfully"
}

main "$@"
