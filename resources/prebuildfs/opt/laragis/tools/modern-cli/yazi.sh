#!/usr/bin/env bash
# =============================================================================
# yazi - Blazing fast terminal file manager
# =============================================================================
# DESCRIPTION: Blazing fast terminal file manager written in Rust
# URL: https://github.com/sxyazi/yazi
# VERSION: v0.4.2
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="yazi"
readonly TOOL_VERSION="${YAZI_VERSION:-0.4.2}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/yazi.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    # Install yazi via cargo if available
    if command -v cargo >/dev/null 2>&1; then
        cargo install yazi-fm --version "${TOOL_VERSION}"
    else
        # Fallback to binary installation
        local temp_dir="$(mktemp -d)"
        trap "rm -rf '${temp_dir}'" EXIT
        
        # Determine architecture
        local arch="$(uname -m)"
        
        case "$arch" in
            "x86_64") arch="x86_64-unknown-linux-gnu" ;;
            "aarch64") arch="aarch64-unknown-linux-gnu" ;;
            *) log_error "Unsupported architecture: $arch"; return 1 ;;
        esac
        
        # Download yazi binary
        local download_url="https://github.com/sxyazi/yazi/releases/download/v${TOOL_VERSION}/yazi-${arch}.zip"
        
        log_info "Downloading yazi from: ${download_url}"
        curl -fsSL "${download_url}" -o "${temp_dir}/yazi.zip"
        
        # Extract and install
        cd "${temp_dir}"
        unzip -q yazi.zip
        
        # Install binary
        install -m 755 yazi-${arch}/yazi /usr/local/bin/yazi
        install -m 755 yazi-${arch}/ya /usr/local/bin/ya
    fi
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "yazi installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing yazi v${TOOL_VERSION}..."
    
    is_installed && { log_info "yazi is already installed"; return 0; }
    
    install_tool
    
    log_success "yazi v${TOOL_VERSION} installed successfully"
}

main "$@"
