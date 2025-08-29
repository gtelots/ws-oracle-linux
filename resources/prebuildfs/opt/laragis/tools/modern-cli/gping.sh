#!/usr/bin/env bash
# =============================================================================
# gping - Ping, but with a graph
# =============================================================================
# DESCRIPTION: Ping, but with a graph
# URL: https://github.com/orf/gping
# VERSION: v1.18.0
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="gping"
readonly TOOL_VERSION="${GPING_VERSION:-1.18.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/gping.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    # Install gping via cargo if available
    if command -v cargo >/dev/null 2>&1; then
        cargo install gping --version "${TOOL_VERSION}"
    else
        # Fallback to binary installation
        local temp_dir="$(mktemp -d)"
        trap "rm -rf '${temp_dir}'" EXIT
        
        # Determine architecture
        local arch="$(uname -m)"
        
        case "$arch" in
            "x86_64") arch="x86_64-unknown-linux-musl" ;;
            "aarch64") arch="aarch64-unknown-linux-musl" ;;
            *) log_error "Unsupported architecture: $arch"; return 1 ;;
        esac
        
        # Download gping binary
        local download_url="https://github.com/orf/gping/releases/download/gping-v${TOOL_VERSION}/gping-${arch}.tar.gz"
        
        log_info "Downloading gping from: ${download_url}"
        curl -fsSL "${download_url}" -o "${temp_dir}/gping.tar.gz"
        
        # Extract and install
        cd "${temp_dir}"
        tar -xzf gping.tar.gz
        
        # Install binary
        install -m 755 gping /usr/local/bin/gping
    fi
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "gping installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing gping v${TOOL_VERSION}..."
    
    is_installed && { log_info "gping is already installed"; return 0; }
    
    install_tool
    
    log_success "gping v${TOOL_VERSION} installed successfully"
}

main "$@"
