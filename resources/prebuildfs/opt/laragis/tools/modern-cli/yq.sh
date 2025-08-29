#!/usr/bin/env bash
# =============================================================================
# yq - Command-line YAML processor
# =============================================================================
# DESCRIPTION: A portable command-line YAML processor
# URL: https://github.com/mikefarah/yq
# VERSION: v4.44.6
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="yq"
readonly TOOL_VERSION="${YQ_VERSION:-4.44.6}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/yq.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    local temp_dir="$(mktemp -d)"
    trap "rm -rf '${temp_dir}'" EXIT
    
    # Determine architecture
    local os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    local arch="$(uname -m)"
    
    case "$arch" in
        "x86_64") arch="amd64" ;;
        "aarch64") arch="arm64" ;;
        *) log_error "Unsupported architecture: $arch"; return 1 ;;
    esac
    
    # Download yq binary
    local download_url="https://github.com/mikefarah/yq/releases/download/v${TOOL_VERSION}/yq_${os}_${arch}"
    
    log_info "Downloading yq from: ${download_url}"
    curl -fsSL "${download_url}" -o "${temp_dir}/yq"
    
    # Install binary
    install -m 755 "${temp_dir}/yq" /usr/local/bin/yq
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "yq installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing yq v${TOOL_VERSION}..."
    
    is_installed && { log_info "yq is already installed"; return 0; }
    
    install_tool
    
    log_success "yq v${TOOL_VERSION} installed successfully"
}

main "$@"
