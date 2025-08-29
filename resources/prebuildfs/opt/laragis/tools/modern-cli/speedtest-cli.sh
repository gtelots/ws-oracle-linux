#!/usr/bin/env bash
# =============================================================================
# speedtest-cli - Command line interface for testing internet bandwidth
# =============================================================================
# DESCRIPTION: Command line interface for testing internet bandwidth using speedtest.net
# URL: https://github.com/sivel/speedtest-cli
# VERSION: v2.1.3
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="speedtest-cli"
readonly TOOL_VERSION="${SPEEDTEST_CLI_VERSION:-2.1.3}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/speedtest-cli.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    # Install speedtest-cli via pipx for better isolation
    pipx install "speedtest-cli==${TOOL_VERSION}" --global || {
        log_warn "pipx installation failed, trying pip3"
        pip3 install --user "speedtest-cli==${TOOL_VERSION}"
    }
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "speedtest-cli installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing speedtest-cli v${TOOL_VERSION}..."
    
    is_installed && { log_info "speedtest-cli is already installed"; return 0; }
    
    install_tool
    
    log_success "speedtest-cli v${TOOL_VERSION} installed successfully"
}

main "$@"
