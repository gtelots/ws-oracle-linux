# =============================================================================
# github-cli
# =============================================================================
# DESCRIPTION: GitHub’s official command line tool
# URL: https://github.com/cli/cli
# VERSION: v2.78.0
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# REQUIRED TOOLS: git
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="gh"
readonly TOOL_VERSION="${GITHUB_CLI_VERSION:-2.78.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { command -v "$TOOL_NAME" >/dev/null 2>&1 || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  local arch="$(uname -m)"

  case "$arch" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    armv7l) arch="armv7" ;;
    i386|i686) arch="386" ;;
  esac

  local download_url="https://github.com/cli/cli/releases/download/v${TOOL_VERSION}/gh_${TOOL_VERSION}_${os}_${arch}.tar.gz"
  
  local temp_dir="$(mktemp -d)"
  local tar_file="${temp_dir}/${TOOL_NAME}.tar.gz"

  # Setup temporary directory and cleanup trap
  mkdir -p "$temp_dir" && trap "rm -rf '${temp_dir}'" EXIT
  
  # Download -> extract -> install binary
  curl -fsSL -o "${tar_file}" "${download_url}" && \
  tar -xzf "${tar_file}" -C "${temp_dir}" --strip-components=1 && \
  install -m 0755 "${temp_dir}/bin/${TOOL_NAME}" "$INSTALL_DIR/${TOOL_NAME}"

  # Install extensions
  if [ -n "${GH_TOKEN:-}" ]; then
    gh extension install github/gh-copilot
  fi

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

  install_tool

  log_success "${TOOL_NAME} v${TOOL_VERSION} installed successfully"
}

main "$@"
