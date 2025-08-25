#!/usr/bin/env bash
# =============================================================================
# Teleport
# =============================================================================
# DESCRIPTION: The easiest, and most secure way to access and protect all of your infrastructure.
# URL: https://github.com/gravitational/teleport
# VERSION: v18.1.6
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/os.sh
. /opt/laragis/lib/arch.sh

# Configuration
readonly TOOL_NAME="teleport"
readonly TOOL_VERSION="${TELEPORT_VERSION:-18.1.6}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local arch="$(arch_auto)"
  local download_url="https://cdn.teleport.dev/teleport-${TOOL_VERSION}-1.${arch}.rpm"
  
  # Download -> extract -> install binary
  dnf install -y "${download_url}"

  # Verify installation
  os_command_is_installed "$TOOL_NAME" || { error "${TOOL_NAME} installation verification failed"; return 1; }

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
