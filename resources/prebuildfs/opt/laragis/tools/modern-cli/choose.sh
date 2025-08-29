#!/usr/bin/env bash
# =============================================================================
# choose - Human-friendly alternative to cut and awk
# =============================================================================
# DESCRIPTION: A human-friendly and fast alternative to cut and (sometimes) awk
# URL: https://github.com/theryangeary/choose
# VERSION: v1.3.6
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="choose"
readonly TOOL_VERSION="${CHOOSE_VERSION:-1.3.6}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/choose.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    # Install choose via cargo if available
    if command -v cargo >/dev/null 2>&1; then
        cargo install choose --version "${TOOL_VERSION}"
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
        
        # Download choose binary
        local download_url="https://github.com/theryangeary/choose/releases/download/v${TOOL_VERSION}/choose-${arch}"
        
        log_info "Downloading choose from: ${download_url}"
        curl -fsSL "${download_url}" -o "${temp_dir}/choose"
        
        # Install binary
        install -m 755 "${temp_dir}/choose" /usr/local/bin/choose
    fi
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "choose installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing choose v${TOOL_VERSION}..."
    
    is_installed && { log_info "choose is already installed"; return 0; }
    
    install_tool
    
    log_success "choose v${TOOL_VERSION} installed successfully"
}

main "$@"
