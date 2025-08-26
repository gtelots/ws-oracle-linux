#!/usr/bin/env bash
# =============================================================================
# gomplate
# =============================================================================
# DESCRIPTION: A flexible commandline tool for template rendering
# URL: https://github.com/hairyhenderson/gomplate
# VERSION: v4.3.3
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/arch.sh
. /opt/laragis/lib/os.sh

# Configuration
readonly TOOL_NAME="gomplate"
readonly TOOL_VERSION="${GOMPLATE_VERSION:-4.3.3}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local os="$(detect_os)"
  local arch="$(arch_auto deb)"
  local download_url="https://github.com/hairyhenderson/gomplate/releases/download/v${TOOL_VERSION}/gomplate_${os}-${arch}"
  
  local temp_dir="$(mktemp -d)"
  local bin_file="${temp_dir}/${TOOL_NAME}"

  # Setup temporary directory and cleanup trap
  mkdir -p "$temp_dir" && trap "rm -rf '${temp_dir}'" EXIT

  # Download -> extract -> install binary
  curl -fsSL -o "${bin_file}" "${download_url}" && \
  install -m 0755 "${temp_dir}/${TOOL_NAME}" "${INSTALL_DIR}/${TOOL_NAME}"

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
