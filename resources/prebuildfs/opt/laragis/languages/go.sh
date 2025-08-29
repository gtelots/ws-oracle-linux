#!/usr/bin/env bash
# =============================================================================
# Go Installation
# =============================================================================
# DESCRIPTION: Install Go programming language
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly GO_VERSION="${GO_VERSION:-1.23.4}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/go.installed"

is_installed() { command -v go >/dev/null 2>&1 || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_go() {
    log_info "Installing Go ${GO_VERSION}..."
    
    # Determine architecture
    local arch="$(uname -m)"
    case "$arch" in
        "x86_64") arch="amd64" ;;
        "aarch64") arch="arm64" ;;
        *) log_error "Unsupported architecture: $arch"; return 1 ;;
    esac
    
    # Download and install Go
    local temp_dir="$(mktemp -d)"
    trap "rm -rf '${temp_dir}'" EXIT
    
    local download_url="https://golang.org/dl/go${GO_VERSION}.linux-${arch}.tar.gz"
    log_info "Downloading Go from: ${download_url}"
    
    curl -fsSL "${download_url}" -o "${temp_dir}/go.tar.gz"
    
    # Remove any existing Go installation
    rm -rf /usr/local/go
    
    # Extract Go to /usr/local
    tar -C /usr/local -xzf "${temp_dir}/go.tar.gz"
    
    # Add Go to PATH
    echo 'export PATH="/usr/local/go/bin:$PATH"' >> /etc/environment
    echo 'export GOPATH="$HOME/go"' >> /etc/environment
    echo 'export GOBIN="$GOPATH/bin"' >> /etc/environment
    echo 'export PATH="$GOBIN:$PATH"' >> /etc/environment
    
    # Set up Go environment for current session
    export PATH="/usr/local/go/bin:$PATH"
    export GOPATH="$HOME/go"
    export GOBIN="$GOPATH/bin"
    export PATH="$GOBIN:$PATH"
    
    # Create Go workspace directories
    mkdir -p "$GOPATH/src" "$GOPATH/bin" "$GOPATH/pkg"
    
    # Install common Go tools
    /usr/local/go/bin/go install golang.org/x/tools/gopls@latest
    /usr/local/go/bin/go install golang.org/x/tools/cmd/goimports@latest
    /usr/local/go/bin/go install golang.org/x/lint/golint@latest
    /usr/local/go/bin/go install github.com/go-delve/delve/cmd/dlv@latest
    
    # Verify installation
    if command -v go >/dev/null 2>&1; then
        log_success "Go installed successfully: $(go version)"
    else
        log_error "Go installation verification failed"
        return 1
    fi
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Setting up Go development environment..."
    
    is_installed && { log_info "Go is already installed"; return 0; }
    
    install_go
    
    log_success "Go ${GO_VERSION} development environment installed successfully"
}

main "$@"
