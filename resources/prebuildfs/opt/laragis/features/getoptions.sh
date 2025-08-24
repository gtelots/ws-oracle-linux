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
readonly FEATURE_NAME="getoptions"
readonly FEATURE_VERSION="3.3.2"
readonly FEATURE_FOLDER="/opt/laragis/features"
readonly LOCK_FILE="${FEATURE_FOLDER}/${FEATURE_NAME}.installed"
readonly INSTALL_DIR="/usr/local/bin"

# Check if getoptions is already installed
is_installed() {
  if command -v "${FEATURE_NAME}" >/dev/null 2>&1 || [[ -f "${LOCK_FILE}" ]]; then
    return 0
  fi
  return 1
}

# Install getoptions from GitHub source
install_getoptions(){
  local download_url="https://github.com/ko1nksm/getoptions/releases/download/v${FEATURE_VERSION}/getoptions.tar.gz"

  # Create temporary directory
  local temp_dir="/tmp/features/${FEATURE_NAME}-${FEATURE_VERSION}"
  local tar_file="${temp_dir}/${FEATURE_NAME}.tar.gz"
  mkdir -p "$temp_dir"

  # Ensure cleanup on exit
  trap "rm -rf '${temp_dir}'" EXIT

  # Download getoptions source
  curl -fsSL -o "${tar_file}" "${download_url}"
  # Extract getoptions
  tar -xzf "${tar_file}" -C "${temp_dir}"

  # Install binary
  install -m 0755 "${temp_dir}/${FEATURE_NAME}" "${INSTALL_DIR}/${FEATURE_NAME}"

  # Verify installation
  command -v "${FEATURE_NAME}" >/dev/null 2>&1 || { error "${FEATURE_NAME} installation verification failed"; return 1; }

  # Create lock file with correct extension
  mkdir -p "/opt/laragis/features"
  touch "${LOCK_FILE}"
}

# Main function
main() {
  info "Installing ${FEATURE_NAME} v${FEATURE_VERSION}..."

  is_installed && { info "${FEATURE_NAME} is already installed"; return 0; }

  install_getoptions

  success "${FEATURE_NAME} v${FEATURE_VERSION} installed successfully"
}

main "$@"
