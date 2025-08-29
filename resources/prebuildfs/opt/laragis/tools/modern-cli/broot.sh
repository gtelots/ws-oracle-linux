#!/usr/bin/env bash
# =============================================================================
# broot - Tree view and file manager
# =============================================================================
# DESCRIPTION: A new way to see and navigate directory trees
# URL: https://github.com/Canop/broot
# VERSION: v1.44.2
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="broot"
readonly TOOL_VERSION="${BROOT_VERSION:-1.44.2}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/broot.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    # Install broot via cargo if available
    if command -v cargo >/dev/null 2>&1; then
        cargo install broot --version "${TOOL_VERSION}"
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
        
        # Download broot binary
        local download_url="https://github.com/Canop/broot/releases/download/v${TOOL_VERSION}/broot_${TOOL_VERSION}.zip"
        
        log_info "Downloading broot from: ${download_url}"
        curl -fsSL "${download_url}" -o "${temp_dir}/broot.zip"
        
        # Extract and install
        cd "${temp_dir}"
        unzip -q broot.zip
        
        # Find the correct binary for our architecture
        local binary_name="broot"
        if [[ -f "${arch}/broot" ]]; then
            binary_name="${arch}/broot"
        fi
        
        # Install binary
        install -m 755 "${binary_name}" /usr/local/bin/broot
    fi
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "broot installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing broot v${TOOL_VERSION}..."
    
    is_installed && { log_info "broot is already installed"; return 0; }
    
    install_tool
    
    log_success "broot v${TOOL_VERSION} installed successfully"
}

main "$@"
