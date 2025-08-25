# =============================================================================
# AWS Cli
# =============================================================================
# DESCRIPTION: Installs Gum - A tool for glamorous shell scripts
# URL: https://github.com/charmbracelet/gum
# VERSION: v0.16.2
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/os.sh

# Configuration
readonly TOOL_NAME="aws"
readonly TOOL_VERSION="${AWS_CLI_VERSION:-2.28.16}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local arch="$(uname -m)"
  local download_url="https://awscli.amazonaws.com/awscli-exe-linux-${arch}-${TOOL_VERSION}.zip"

  local temp_dir="$(mktemp -d)"
  local zip_file="${temp_dir}/${TOOL_NAME}.zip"
  
  # Setup temporary directory and cleanup trap
  mkdir -p "$temp_dir" && trap "rm -rf '${temp_dir}'" EXIT

  # Download -> extract -> install
  curl -fsSL -o "${zip_file}" "${download_url}" && \
  unzip -q -o "${zip_file}" -d "${temp_dir}" && \
  ${temp_dir}/aws/install --bin-dir "${INSTALL_DIR}" --update

  # Verify installation
  os_command_is_installed "$TOOL_NAME" || { error "${TOOL_NAME} installation verification failed"; return 1; }

  # Create lock file
  mkdir -p "${TOOL_FOLDER}"
  touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
  log_info "Installing ${TOOL_NAME} v${TOOL_VERSION}..."

  is_installed && { log_info "${TOOL_NAME} is already installed"; return 0; }

  install_tool

  log_success "${TOOL_NAME} v${TOOL_VERSION} installed successfully"
}

main "$@"
