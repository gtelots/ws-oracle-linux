#!/usr/bin/env bash
# =============================================================================
# HTTPie
# =============================================================================
# DESCRIPTION: Modern, user-friendly command-line HTTP client for the API era
# URL: https://github.com/httpie/httpie
# VERSION: v3.2.4
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="http"
readonly TOOL_VERSION="${HTTPIE_VERSION:-3.2.4}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/httpie.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  # Install HTTPie via pipx for better isolation
  pipx install "httpie==${TOOL_VERSION}" --global

  # Verify installation
  os_command_is_installed "$TOOL_NAME" || { error "HTTPie installation verification failed"; return 1; }

  # Create lock file
  mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
  log_info "Installing HTTPie v${TOOL_VERSION}..."

  is_installed && { log_info "HTTPie is already installed"; return 0; }

  install_tool

  log_success "HTTPie v${TOOL_VERSION} installed successfully"
}

main "$@"
