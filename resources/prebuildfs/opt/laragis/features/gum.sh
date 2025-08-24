#!/usr/bin/env bash
# =============================================================================
# Gum CLI Tool Installer
# =============================================================================
# DESCRIPTION: Installs Gum - A tool for glamorous shell scripts
# URL: https://github.com/charmbracelet/gum
# VERSION: v0.16.2
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

set -euo pipefail

# Load libraries
. /opt/laragis/lib/lib-log.sh

# Configuration
readonly FEATURE_NAME="gum"
readonly FEATURE_VERSION="0.16.2"
readonly FEATURE_FOLDER="/opt/laragis/features"
readonly LOCK_FILE="${FEATURE_FOLDER}/${FEATURE_NAME}.installed"
readonly INSTALL_DIR="/usr/local/bin"

# Check if gum is already installed
is_installed() {
  if command -v "${FEATURE_NAME}" >/dev/null 2>&1 || [[ -f "${LOCK_FILE}" ]]; then
    return 0
  fi
  return 1
}

# Install gum from GitHub releases
install_gum(){
  local architecture="$(uname -m)"
  local download_url="https://github.com/charmbracelet/gum/releases/download/v${FEATURE_VERSION}/gum_${FEATURE_VERSION}_Linux_${architecture}.tar.gz"

  # Create temporary directory
  local temp_dir="/tmp/features/${FEATURE_NAME}-${FEATURE_VERSION}"
  local tar_file="${temp_dir}/${FEATURE_NAME}.tar.gz"
  mkdir -p "$temp_dir"

  # Ensure cleanup on exit
  trap "rm -rf '${temp_dir}'" EXIT

  # Download gum
  curl -fsSL -o "${tar_file}" "${download_url}"
  # Extract gum
  tar -xzf "${tar_file}" -C "${temp_dir}" --strip-components=1
  # Install binary
  install -m 0755 "${temp_dir}/${FEATURE_NAME}" "$INSTALL_DIR/${FEATURE_NAME}"

  # Verify installation
  command -v "${FEATURE_NAME}" >/dev/null 2>&1 || { error "${FEATURE_NAME} installation verification failed"; return 1; }

  # Create lock file
  mkdir -p "${FEATURE_FOLDER}"
  touch "${LOCK_FILE}"
}

# Main function
main() {
  info "Installing ${FEATURE_NAME} v${FEATURE_VERSION}..."

  is_installed && { info "${FEATURE_NAME} is already installed"; return 0; }

  install_gum

  success "${FEATURE_NAME} v${FEATURE_VERSION} installed successfully"
}

main "$@"
