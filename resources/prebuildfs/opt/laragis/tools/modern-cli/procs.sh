#!/usr/bin/env bash
# =============================================================================
# procs - Modern replacement for ps written in Rust
# =============================================================================
# DESCRIPTION: A modern replacement for ps written in Rust
# URL: https://github.com/dalance/procs
# VERSION: v0.14.8
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="procs"
readonly TOOL_VERSION="${PROCS_VERSION:-0.14.8}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/procs.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    # Install procs via cargo if available
    if command -v cargo >/dev/null 2>&1; then
        cargo install procs --version "${TOOL_VERSION}"
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
        
        # Download procs binary
        local download_url="https://github.com/dalance/procs/releases/download/v${TOOL_VERSION}/procs-v${TOOL_VERSION}-${arch}.zip"
        
        log_info "Downloading procs from: ${download_url}"
        curl -fsSL "${download_url}" -o "${temp_dir}/procs.zip"
        
        # Extract and install
        cd "${temp_dir}"
        unzip -q procs.zip
        
        # Install binary
        install -m 755 procs /usr/local/bin/procs
    fi
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "procs installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing procs v${TOOL_VERSION}..."
    
    is_installed && { log_info "procs is already installed"; return 0; }
    
    install_tool
    
    log_success "procs v${TOOL_VERSION} installed successfully"
}

main "$@"
