#!/usr/bin/env bash
# =============================================================================
# btop
# =============================================================================
# DESCRIPTION: A feature-rich system monitor with a beautiful interface
# URL: https://github.com/aristocratos/btop
# VERSION: v1.4.0
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/arch.sh
. /opt/laragis/lib/os.sh

# Configuration
readonly TOOL_NAME="btop"
readonly TOOL_VERSION="${BTOP_VERSION:-1.4.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local os="$(detect_os)"
  local arch="$(arch_auto)"

  # btop uses different architecture naming
  case "$arch" in
    "amd64") arch="x86_64" ;;
    "arm64") arch="aarch64" ;;
  esac

  local download_url="https://github.com/aristocratos/btop/releases/download/v${TOOL_VERSION}/btop-${arch}-${os}-musl.tbz"

  local temp_dir="$(mktemp -d)"
  local tar_file="${temp_dir}/${TOOL_NAME}.tbz"

  # Setup temporary directory and cleanup trap
  mkdir -p "$temp_dir" && trap "rm -rf '${temp_dir}'" EXIT

  # Download -> extract -> install binary
  curl -fsSL -o "${tar_file}" "${download_url}" && \
  tar -xjf "${tar_file}" -C "${temp_dir}" && \
  install -m 0755 "${temp_dir}/btop/bin/${TOOL_NAME}" "${INSTALL_DIR}/${TOOL_NAME}"

  # Create compatibility symlink for bottom users
  ln -sf "${INSTALL_DIR}/${TOOL_NAME}" "${INSTALL_DIR}/btm"

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
