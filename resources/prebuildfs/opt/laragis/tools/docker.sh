#!/usr/bin/env bash
# =============================================================================
# docker
# =============================================================================
# DESCRIPTION: Docker Engine - Community
# URL: https://github.com/docker/docker-ce
# VERSION: v28.3.2
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/arch.sh
. /opt/laragis/lib/os.sh

# Configuration
readonly TOOL_NAME="docker"
readonly TOOL_VERSION="${DOCKER_VERSION:-28.3.2}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool(){
  dnf -y install dnf-plugins-core
  dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
  dnf install "docker-ce-${TOOL_VERSION}" "docker-ce-cli-${TOOL_VERSION}" containerd.io docker-buildx-plugin docker-compose-plugin
  
  if [[ $EUID -ne 0 ]]; then
    usermod -aG docker "${USER_NAME}" || true
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
