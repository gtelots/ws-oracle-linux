#!/usr/bin/env bash
# =============================================================================
# jq - Command-line JSON processor
# =============================================================================
# DESCRIPTION: A lightweight and flexible command-line JSON processor
# URL: https://github.com/jqlang/jq
# VERSION: v1.7.1
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/install.sh
. /opt/laragis/lib/github.sh

# Configuration
setup_tool_config "jq" "${JQ_VERSION:-1.7.1}"

# Custom installation function for jq (direct binary download)
install_jq_binary() {
  local temp_dir="$(create_temp_dir)"
  local arch="$(get_github_arch)"
  local download_url="https://github.com/jqlang/jq/releases/download/jq-${TOOL_VERSION}/jq-linux-${arch}"

  if download_file "$download_url" "${temp_dir}/jq"; then
    install_binary "${temp_dir}/jq" "/usr/local/bin/jq"
    return 0
  else
    return 1
  fi
}

# Main function
main() {
  log_info "Installing ${TOOL_NAME} v${TOOL_VERSION}..."

  # Check if already installed
  if is_tool_installed "$TOOL_NAME" "$TOOL_LOCK_FILE"; then
    log_info "${TOOL_NAME} is already installed"
    return 0
  fi

  # Try package manager first, then custom binary installation
  if try_package_install "$TOOL_NAME" || install_jq_binary; then
    create_tool_lock_file "$TOOL_LOCK_FILE"
    verify_tool_installation "$TOOL_NAME" "$TOOL_VERSION"
    log_success "${TOOL_NAME} v${TOOL_VERSION} installed successfully"
  else
    log_error "${TOOL_NAME} installation failed"
    return 1
  fi
}

main "$@"
