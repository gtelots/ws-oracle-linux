#!/usr/bin/env bash
# =============================================================================
# kubectl
# =============================================================================
# DESCRIPTION: The Kubernetes command-line tool
# URL: https://github.com/kubernetes/kubectl
# VERSION: v1.30.2
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/arch.sh
. /opt/laragis/lib/os.sh

# Configuration
readonly TOOL_NAME="kubectl"
readonly TOOL_VERSION="${KUBECTL_VERSION:-1.31.12}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local os="$(detect_os)"
  local arch="$(arch_auto deb)"
  local download_url="https://dl.k8s.io/release/v${TOOL_VERSION}/bin/${os}/${arch}/kubectl"

  local temp_dir="$(mktemp -d)"
  local bin_file="${temp_dir}/${TOOL_NAME}"

  # Setup temporary directory and cleanup trap
  mkdir -p "$temp_dir" && trap "rm -rf '${temp_dir}'" EXIT
  
  # Download -> install binary
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
