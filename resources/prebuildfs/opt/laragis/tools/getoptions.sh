#!/usr/bin/env bash
# =============================================================================
# getoptions Library Installer
# =============================================================================
# DESCRIPTION: Installs getoptions - An elegant option parser for shell scripts
# URL: https://github.com/ko1nksm/getoptions
# VERSION: v3.3.2
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

set -euo pipefail

# Load libraries
. /opt/laragis/lib/lib-log.sh

# Configuration
readonly TOOL_NAME="getoptions"
readonly TOOL_VERSION="3.3.2"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Check if getoptions is already installed
is_installed() {
  if command -v "${TOOL_NAME}" >/dev/null 2>&1 || [[ -f "${TOOL_LOCK_FILE}" ]]; then
    return 0
  fi
  return 1
}

# Install getoptions from GitHub source
install_getoptions(){
  local download_url="https://github.com/ko1nksm/getoptions/releases/download/v${TOOL_VERSION}/getoptions.tar.gz"

  # Create temporary directory
  local temp_dir="/tmp/tools/${TOOL_NAME}-${TOOL_VERSION}"
  local tar_file="${temp_dir}/${TOOL_NAME}.tar.gz"
  mkdir -p "$temp_dir"

  # Ensure cleanup on exit
  trap "rm -rf '${temp_dir}'" EXIT

  # Download getoptions source
  curl -fsSL -o "${tar_file}" "${download_url}"
  # Extract getoptions
  tar -xzf "${tar_file}" -C "${temp_dir}"

  # Install binary
  install -m 0755 "${temp_dir}/${TOOL_NAME}" "${INSTALL_DIR}/${TOOL_NAME}"

  # Verify installation
  command -v "${TOOL_NAME}" >/dev/null 2>&1 || { error "${TOOL_NAME} installation verification failed"; return 1; }

  # Create lock file with correct extension
  mkdir -p "/opt/laragis/features"
  touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
  info "Installing ${TOOL_NAME} v${TOOL_VERSION}..."

  is_installed && { info "${TOOL_NAME} is already installed"; return 0; }

  install_getoptions

  success "${TOOL_NAME} v${TOOL_VERSION} installed successfully"
}

main "$@"
