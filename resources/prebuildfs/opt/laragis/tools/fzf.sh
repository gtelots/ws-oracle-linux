#!/usr/bin/env bash
# =============================================================================
# fzf
# =============================================================================
# DESCRIPTION: A command-line fuzzy finder
# URL: https://github.com/junegunn/fzf
# VERSION: v0.58.0
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/arch.sh
. /opt/laragis/lib/os.sh

# Configuration
readonly TOOL_NAME="fzf"
readonly TOOL_VERSION="${FZF_VERSION:-0.58.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local os="$(detect_os)"
  local arch="$(arch_auto)"
  
  # fzf uses different architecture naming
  case "$arch" in
    "amd64") arch="amd64" ;;
    "arm64") arch="arm64" ;;
  esac
  
  local download_url="https://github.com/junegunn/fzf/releases/download/v${TOOL_VERSION}/fzf-${TOOL_VERSION}-${os}_${arch}.tar.gz"
  
  local temp_dir="$(mktemp -d)"
  local tar_file="${temp_dir}/${TOOL_NAME}.tar.gz"

  # Setup temporary directory and cleanup trap
  mkdir -p "$temp_dir" && trap "rm -rf '${temp_dir}'" EXIT
  
  # Download -> extract -> install binary
  curl -fsSL -o "${tar_file}" "${download_url}" && \
  tar -xzf "${tar_file}" -C "${temp_dir}" && \
  install -m 0755 "${temp_dir}/${TOOL_NAME}" "${INSTALL_DIR}/${TOOL_NAME}"

  # Install shell integration files
  local fzf_share_dir="/usr/local/share/fzf"
  mkdir -p "${fzf_share_dir}"
  
  # Download and install shell integration
  curl -fsSL -o "${fzf_share_dir}/key-bindings.bash" \
    "https://raw.githubusercontent.com/junegunn/fzf/v${TOOL_VERSION}/shell/key-bindings.bash"
  curl -fsSL -o "${fzf_share_dir}/completion.bash" \
    "https://raw.githubusercontent.com/junegunn/fzf/v${TOOL_VERSION}/shell/completion.bash"
  curl -fsSL -o "${fzf_share_dir}/key-bindings.zsh" \
    "https://raw.githubusercontent.com/junegunn/fzf/v${TOOL_VERSION}/shell/key-bindings.zsh"
  curl -fsSL -o "${fzf_share_dir}/completion.zsh" \
    "https://raw.githubusercontent.com/junegunn/fzf/v${TOOL_VERSION}/shell/completion.zsh"

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
