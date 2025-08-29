#!/usr/bin/env bash
# =============================================================================
# ncdu - Disk usage analyzer with ncurses interface
# =============================================================================
# DESCRIPTION: A disk usage analyzer with an ncurses interface
# URL: https://dev.yorhel.nl/ncdu
# VERSION: v1.19
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="ncdu"
readonly TOOL_VERSION="${NCDU_VERSION:-1.19}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/ncdu.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    # Try package manager first (usually available)
    if dnf -y install ncdu; then
        log_info "ncdu installed via package manager"
    else
        log_error "ncdu installation via package manager failed"
        return 1
    fi
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "ncdu installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing ncdu v${TOOL_VERSION}..."
    
    is_installed && { log_info "ncdu is already installed"; return 0; }
    
    install_tool
    
    log_success "ncdu v${TOOL_VERSION} installed successfully"
}

main "$@"
