#!/usr/bin/env bash
# =============================================================================
# dry
# =============================================================================
# DESCRIPTION: A Docker manager for the terminal
# URL: https://github.com/moncho/dry
# VERSION: v0.11.2
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# REQUIRED TOOLS: file
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="dry"
readonly TOOL_VERSION="${DRY_VERSION:-0.11.2}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { command -v "$TOOL_NAME" >/dev/null 2>&1 || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local download_url="https://github.com/moncho/dry/releases/download/v${TOOL_VERSION}/dry-linux-amd64"
  
  local temp_dir="$(mktemp -d)"
  local bin_file="${temp_dir}/${TOOL_NAME}"

  # Setup temporary directory and cleanup trap
  mkdir -p "$temp_dir" && trap "rm -rf '${temp_dir}'" EXIT
  
  # Download -> extract -> install binary
  curl -fsSL -o "${bin_file}" "${download_url}" && \
  install -m 0755 "${temp_dir}/${TOOL_NAME}" "$INSTALL_DIR/${TOOL_NAME}"

  # Verify installation
  command -v "${TOOL_NAME}" >/dev/null 2>&1 || { error "${TOOL_NAME} installation verification failed"; return 1; }

  # Create lock file
  mkdir -p "${TOOL_FOLDER}"
  touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
  log_info "Installing ${TOOL_NAME} v${TOOL_VERSION}..."

  is_installed && { log_info "${TOOL_NAME} is already installed"; return 0; }

  install_tool

  log_success "${TOOL_NAME} v${TOOL_VERSION} installed successfully"
}

main "$@"
