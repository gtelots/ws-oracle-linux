#!/usr/bin/env bash
# =============================================================================
# uv
# =============================================================================
# DESCRIPTION: An extremely fast Python package and project manager, written in Rust.
# URL: https://github.com/astral-sh/uv
# VERSION: v0.8.13
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/arch.sh
. /opt/laragis/lib/os.sh

# Configuration
readonly TOOL_NAME="uv"
readonly TOOL_VERSION="${UV_VERSION:-0.8.13}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local os="$(detect_os)"
  local arch="$(arch_auto)"
  local download_url="https://github.com/astral-sh/uv/releases/download/${TOOL_VERSION}/uv-${arch}-unknown-${os}-gnu.tar.gz"
  
  local temp_dir="$(mktemp -d)"
  local tar_file="${temp_dir}/${TOOL_NAME}.tar.gz"

  # Setup temporary directory and cleanup trap
  mkdir -p "$temp_dir" && trap "rm -rf '${temp_dir}'" EXIT
  
  # Download -> extract -> install binary
  curl -fsSL -o "${tar_file}" "${download_url}" && \
  tar -xzf "${tar_file}" -C "${temp_dir}" --strip-components=1 && \
  install -m 0755 "${temp_dir}/uv" "${INSTALL_DIR}/uv" && \
  install -m 0755 "${temp_dir}/uvx" "${INSTALL_DIR}/uvx"

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
