#!/usr/bin/env bash
# =============================================================================
# wp-cli
# =============================================================================
# DESCRIPTION: The command line interface for WordPress
# URL: https://github.com/wp-cli/wp-cli
# VERSION: v2.12.0
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="wp"
readonly TOOL_VERSION="${WP_CLI_VERSION:-2.12.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local download_url="https://github.com/wp-cli/wp-cli/releases/download/v${TOOL_VERSION}/wp-cli-${TOOL_VERSION}.phar"
  
  local temp_dir="$(mktemp -d)"
  local phar_file="${temp_dir}/${TOOL_NAME}.phar"

  # Setup temporary directory and cleanup trap
  mkdir -p "$temp_dir" && trap "rm -rf '${temp_dir}'" EXIT

  # Download and install binary
  curl -fsSL -o "${phar_file}" "${download_url}" && \
  mv "${phar_file}" "${INSTALL_DIR}/${TOOL_NAME}" && \
  chmod +x "${INSTALL_DIR}/${TOOL_NAME}"

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
