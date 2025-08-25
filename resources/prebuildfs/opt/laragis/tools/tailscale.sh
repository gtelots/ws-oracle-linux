# =============================================================================
# tailscale
# =============================================================================
# DESCRIPTION: The easiest, most secure way to use WireGuard and 2FA.
# URL: https://github.com/tailscale/tailscale
# VERSION: v1.86.2
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/os.sh
. /opt/laragis/lib/arch.sh

# Configuration
readonly TOOL_NAME="tailscale"
readonly TOOL_VERSION="${TAILSCALE_VERSION:-1.86.2}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { os_command_is_installed "$TOOL_NAME" 2>&1 || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  local arch="$(arch_auto)"

  dnf config-manager --add-repo https://pkgs.tailscale.com/stable/oracle/9/tailscale.repo
  dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs "tailscale-${TOOL_VERSION}-1.${arch}"
  
  # Verify installation
  command -v "${TOOL_NAME}" >/dev/null 2>&1 || { error "${TOOL_NAME} installation verification failed"; return 1; }

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
