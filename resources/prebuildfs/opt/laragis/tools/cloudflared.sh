#!/usr/bin/env bash
# =============================================================================
# cloudflared
# =============================================================================
# DESCRIPTION: Cloudflare Tunnel client (formerly Argo Tunnel)
# URL: https://github.com/cloudflare/cloudflared
# VERSION: v2025.8.1
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/os.sh
. /opt/laragis/lib/arch.sh

# Configuration
readonly TOOL_NAME="cloudflared"
readonly TOOL_VERSION="${CLOUDFLARED_VERSION:-2025.8.1}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local os="$(detect_os)"
  local arch="$(arch_auto deb)"
  local install_method="rpm" # bin / rpm
  
  local temp_dir="$(mktemp -d)"
  local bin_file="${temp_dir}/${TOOL_NAME}"

  local download_url="https://github.com/cloudflare/cloudflared/releases/download/${TOOL_VERSION}/cloudflared-${os}-${arch}"

  # Setup temporary directory and cleanup trap
  mkdir -p "$temp_dir" && trap "rm -rf '${temp_dir}'" EXIT
  
  if [[ "$install_method" != "bin" ]]; then
    arch=$(arch_auto)
    download_url="https://github.com/cloudflare/cloudflared/releases/download/${TOOL_VERSION}/cloudflared-${os}-${arch}.rpm"
    dnf install -y "${download_url}"
  else
    # Download -> extract -> install binary
    curl -fsSL -o "${bin_file}" "${download_url}" && \
    install -m 0755 "${temp_dir}/${TOOL_NAME}" "${INSTALL_DIR}/${TOOL_NAME}"
  fi

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
