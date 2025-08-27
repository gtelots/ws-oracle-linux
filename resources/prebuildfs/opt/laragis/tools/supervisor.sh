#!/usr/bin/env bash
# =============================================================================
# Supervisor
# =============================================================================
# DESCRIPTION: Supervisor is a process control system
# URL: https://github.com/Supervisor/supervisor
# VERSION: v4.3.0
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/arch.sh
. /opt/laragis/lib/os.sh

# Configuration
readonly TOOL_NAME="supervisor"
readonly TOOL_VERSION="${SUPERVISOR_VERSION:-4.3.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { os_command_is_installed supervisord || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  pipx install --global supervisor=="${TOOL_VERSION}"

  # Verify installation
  os_command_is_installed supervisord || { error "${TOOL_NAME} installation verification failed"; return 1; }

  # Create lock file
  mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
  log_info "Installing ${TOOL_NAME} v${TOOL_VERSION}..."

  is_installed && { log_info "${TOOL_NAME} is already installed"; return 0; }

  install_tool

  log_success "${TOOL_NAME} v${TOOL_VERSION} installed successfully"
}

main "$@"
