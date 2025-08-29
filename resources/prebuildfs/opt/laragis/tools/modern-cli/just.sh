#!/usr/bin/env bash
# =============================================================================
# just - Command runner (Make alternative)
# =============================================================================
# DESCRIPTION: A handy way to save and run project-specific commands
# URL: https://github.com/casey/just
# VERSION: v1.37.0
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="just"
readonly TOOL_VERSION="${JUST_VERSION:-1.37.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/just.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    # Install just via cargo if available
    if command -v cargo >/dev/null 2>&1; then
        cargo install just --version "${TOOL_VERSION}"
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
        
        # Download just binary
        local download_url="https://github.com/casey/just/releases/download/${TOOL_VERSION}/just-${TOOL_VERSION}-${arch}.tar.gz"
        
        log_info "Downloading just from: ${download_url}"
        curl -fsSL "${download_url}" -o "${temp_dir}/just.tar.gz"
        
        # Extract and install
        cd "${temp_dir}"
        tar -xzf just.tar.gz
        
        # Install binary
        install -m 755 just /usr/local/bin/just
    fi
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "just installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing just v${TOOL_VERSION}..."
    
    is_installed && { log_info "just is already installed"; return 0; }
    
    install_tool
    
    log_success "just v${TOOL_VERSION} installed successfully"
}

main "$@"
