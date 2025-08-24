#!/usr/bin/env bash
# =============================================================================
# Gum CLI Tool Installer
# =============================================================================
# DESCRIPTION: Installs Gum - A tool for glamorous shell scripts
# URL: https://github.com/charmbracelet/gum
# VERSION: v0.16.2
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="gum"
readonly TOOL_VERSION="${GUM_VERSION:-0.16.2}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Check if gum is already installed
is_installed() { command -v "$TOOL_NAME" >/dev/null 2>&1 || [[ -f "$TOOL_LOCK_FILE" ]]; }

# Install gum from GitHub releases
install_gum(){
  local arch="$(uname -m)"
  local download_url="https://github.com/charmbracelet/gum/releases/download/v${TOOL_VERSION}/gum_${TOOL_VERSION}_Linux_${arch}.tar.gz"
  
  local temp_dir="$(mktemp -d)"
  local tar_file="${temp_dir}/${TOOL_NAME}.tar.gz"

  # Setup temporary directory and cleanup trap
  mkdir -p "$temp_dir" && trap "rm -rf '${temp_dir}'" EXIT
  
  # Download -> extract -> install binary
  curl -fsSL -o "${tar_file}" "${download_url}" && \
  tar -xzf "${tar_file}" -C "${temp_dir}" --strip-components=1 && \
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

  install_gum

  log_success "${TOOL_NAME} v${TOOL_VERSION} installed successfully"
}

main "$@"
