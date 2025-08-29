#!/usr/bin/env bash
# =============================================================================
# sd - Intuitive find & replace CLI (sed alternative)
# =============================================================================
# DESCRIPTION: An intuitive find & replace CLI
# URL: https://github.com/chmln/sd
# VERSION: v1.0.0
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="sd"
readonly TOOL_VERSION="${SD_VERSION:-1.0.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/sd.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    # Install sd via cargo if available
    if command -v cargo >/dev/null 2>&1; then
        cargo install sd --version "${TOOL_VERSION}"
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
        
        # Download sd binary
        local download_url="https://github.com/chmln/sd/releases/download/v${TOOL_VERSION}/sd-v${TOOL_VERSION}-${arch}.tar.gz"
        
        log_info "Downloading sd from: ${download_url}"
        curl -fsSL "${download_url}" -o "${temp_dir}/sd.tar.gz"
        
        # Extract and install
        cd "${temp_dir}"
        tar -xzf sd.tar.gz
        
        # Install binary
        install -m 755 sd /usr/local/bin/sd
    fi
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "sd installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing sd v${TOOL_VERSION}..."
    
    is_installed && { log_info "sd is already installed"; return 0; }
    
    install_tool
    
    log_success "sd v${TOOL_VERSION} installed successfully"
}

main "$@"
