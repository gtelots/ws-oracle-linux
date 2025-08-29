#!/usr/bin/env bash
# =============================================================================
# zoxide
# =============================================================================
# DESCRIPTION: A smarter cd command inspired by z and autojump
# URL: https://github.com/ajeetdsouza/zoxide
# VERSION: v0.9.6
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/arch.sh
. /opt/laragis/lib/os.sh

# Configuration
readonly TOOL_NAME="zoxide"
readonly TOOL_VERSION="${ZOXIDE_VERSION:-0.9.6}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local os="$(detect_os)"
  local arch="$(arch_auto)"
  
  # zoxide uses different architecture naming
  case "$arch" in
    "amd64") arch="x86_64" ;;
    "arm64") arch="aarch64" ;;
  esac
  
  local download_url="https://github.com/ajeetdsouza/zoxide/releases/download/v${TOOL_VERSION}/zoxide-${TOOL_VERSION}-${arch}-unknown-${os}-musl.tar.gz"
  
  local temp_dir="$(mktemp -d)"
  local tar_file="${temp_dir}/${TOOL_NAME}.tar.gz"

  # Setup temporary directory and cleanup trap
  mkdir -p "$temp_dir" && trap "rm -rf '${temp_dir}'" EXIT
  
  # Download -> extract -> install binary
  curl -fsSL -o "${tar_file}" "${download_url}" && \
  tar -xzf "${tar_file}" -C "${temp_dir}" && \
  install -m 0755 "${temp_dir}/${TOOL_NAME}" "${INSTALL_DIR}/${TOOL_NAME}"

  # Create z alias for compatibility
  ln -sf "${INSTALL_DIR}/${TOOL_NAME}" "${INSTALL_DIR}/z"

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
