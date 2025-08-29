#!/usr/bin/env bash
# =============================================================================
# fastfetch - System information tool
# =============================================================================
# DESCRIPTION: Like neofetch, but much faster because written in C
# URL: https://github.com/fastfetch-cli/fastfetch
# VERSION: v2.32.0
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="fastfetch"
readonly TOOL_VERSION="${FASTFETCH_VERSION:-2.32.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/fastfetch.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_tool() {
    local temp_dir="$(mktemp -d)"
    trap "rm -rf '${temp_dir}'" EXIT
    
    # Determine architecture
    local arch="$(uname -m)"
    
    case "$arch" in
        "x86_64") arch="amd64" ;;
        "aarch64") arch="aarch64" ;;
        *) log_error "Unsupported architecture: $arch"; return 1 ;;
    esac
    
    # Download fastfetch binary
    local download_url="https://github.com/fastfetch-cli/fastfetch/releases/download/${TOOL_VERSION}/fastfetch-linux-${arch}.tar.gz"
    
    log_info "Downloading fastfetch from: ${download_url}"
    curl -fsSL "${download_url}" -o "${temp_dir}/fastfetch.tar.gz"
    
    # Extract and install
    cd "${temp_dir}"
    tar -xzf fastfetch.tar.gz
    
    # Install binary and data files
    install -m 755 fastfetch-linux-${arch}/usr/bin/fastfetch /usr/local/bin/fastfetch
    
    # Install presets and completions if they exist
    if [[ -d "fastfetch-linux-${arch}/usr/share" ]]; then
        cp -r fastfetch-linux-${arch}/usr/share/fastfetch /usr/local/share/ 2>/dev/null || true
    fi
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { log_error "fastfetch installation verification failed"; return 1; }
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Installing fastfetch v${TOOL_VERSION}..."
    
    is_installed && { log_info "fastfetch is already installed"; return 0; }
    
    install_tool
    
    log_success "fastfetch v${TOOL_VERSION} installed successfully"
}

main "$@"
