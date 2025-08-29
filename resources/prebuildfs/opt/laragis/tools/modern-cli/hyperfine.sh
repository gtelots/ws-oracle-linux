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

# Configuration
readonly TOOL_NAME="hyperfine"
readonly TOOL_VERSION="${HYPERFINE_VERSION:-1.19.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/hyperfine.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    # Install hyperfine via cargo if available
    if command -v cargo >/dev/null 2>&1; then
        cargo install hyperfine --version "${TOOL_VERSION}"
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
        
        # Download hyperfine binary
        local download_url="https://github.com/sharkdp/hyperfine/releases/download/v${TOOL_VERSION}/hyperfine-v${TOOL_VERSION}-${arch}.tar.gz"
        
        log_info "Downloading hyperfine from: ${download_url}"
        curl -fsSL "${download_url}" -o "${temp_dir}/hyperfine.tar.gz"
        
        # Extract and install
        cd "${temp_dir}"
        tar -xzf hyperfine.tar.gz
        
        # Install binary
        install -m 755 hyperfine-v${TOOL_VERSION}-${arch}/hyperfine /usr/local/bin/hyperfine
    fi
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "hyperfine installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing hyperfine v${TOOL_VERSION}..."
    
    is_installed && { log_info "hyperfine is already installed"; return 0; }
    
    install_tool
    
    log_success "hyperfine v${TOOL_VERSION} installed successfully"
}

main "$@"
