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

# Configuration
readonly TOOL_NAME="jq"
readonly TOOL_VERSION="${JQ_VERSION:-1.7.1}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/jq.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    # Try package manager first
    if dnf -y install jq; then
        log_info "jq installed via package manager"
    else
        # Fallback to binary installation
        local temp_dir="$(mktemp -d)"
        trap "rm -rf '${temp_dir}'" EXIT
        
        # Determine architecture
        local arch="$(uname -m)"
        
        case "$arch" in
            "x86_64") arch="amd64" ;;
            "aarch64") arch="arm64" ;;
            *) log_error "Unsupported architecture: $arch"; return 1 ;;
        esac
        
        # Download jq binary
        local download_url="https://github.com/jqlang/jq/releases/download/jq-${TOOL_VERSION}/jq-linux-${arch}"
        
        log_info "Downloading jq from: ${download_url}"
        curl -fsSL "${download_url}" -o "${temp_dir}/jq"
        
        # Install binary
        install -m 755 "${temp_dir}/jq" /usr/local/bin/jq
    fi
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "jq installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing jq v${TOOL_VERSION}..."
    
    is_installed && { log_info "jq is already installed"; return 0; }
    
    install_tool
    
    log_success "jq v${TOOL_VERSION} installed successfully"
}

main "$@"
