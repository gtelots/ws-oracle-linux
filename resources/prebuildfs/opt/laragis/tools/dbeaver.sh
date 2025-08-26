#!/usr/bin/env bash
# =============================================================================
# dbbeaver
# =============================================================================
# DESCRIPTION: Universal Database Tool
# URL: https://github.com/dbeaver/dbeaver
# VERSION: v25.1.5
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/arch.sh
. /opt/laragis/lib/os.sh

# Configuration
readonly TOOL_NAME="dbeaver"
readonly TOOL_VERSION="${DBEAVER_VERSION:-25.1.5}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { command -v "$TOOL_NAME" >/dev/null 2>&1 || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local os="$(detect_os)"
  local arch="$(arch_auto)"
  local download_url="https://github.com/dbeaver/dbeaver/releases/download/${TOOL_VERSION}/dbeaver-ce-${TOOL_VERSION}-stable.${arch}.rpm"
  
  local temp_dir="$(mktemp -d)"
  local rpm_file="${temp_dir}/${TOOL_NAME}.rpm"

  # Setup temporary directory and cleanup trap
  mkdir -p "$temp_dir" && trap "rm -rf '${temp_dir}'" EXIT
  
  # Download -> install
  curl -fsSL -o "${rpm_file}" "${download_url}" && \
  dnf install -y "${rpm_file}"

  # Verify installation
  command -v "$TOOL_NAME" >/dev/null 2>&1 || { error "${TOOL_NAME} installation verification failed"; return 1; }

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
