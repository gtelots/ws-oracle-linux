#!/usr/bin/env bash
# =============================================================================
# hyperfine - Command-line benchmarking tool
# =============================================================================
# DESCRIPTION: A command-line benchmarking tool
# URL: https://github.com/sharkdp/hyperfine
# VERSION: v1.19.0
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/install.sh
. /opt/laragis/lib/github.sh

# Configuration
setup_tool_config "hyperfine" "${HYPERFINE_VERSION:-1.19.0}"

# Main function
main() {
  log_info "Installing ${TOOL_NAME} v${TOOL_VERSION}..."

  # Check if already installed
  if is_tool_installed "$TOOL_NAME" "$TOOL_LOCK_FILE"; then
    log_info "${TOOL_NAME} is already installed"
    return 0
  fi

  # Install using GitHub tool installer with fallback strategies
  if install_github_tool "sharkdp/hyperfine" "$TOOL_NAME" "$TOOL_VERSION" "cargo" "binary"; then
    create_tool_lock_file "$TOOL_LOCK_FILE"
    log_success "${TOOL_NAME} v${TOOL_VERSION} installed successfully"
  else
    log_error "${TOOL_NAME} installation failed"
    return 1
  fi
}

main "$@"
