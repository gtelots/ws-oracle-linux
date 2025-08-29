#!/usr/bin/env bash
# =============================================================================
# Node.js Installation with npm and yarn
# =============================================================================
# DESCRIPTION: Install Node.js with npm and yarn package managers
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly NODEJS_VERSION="${NODEJS_VERSION:-22.12.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/nodejs.installed"

is_installed() { command -v node >/dev/null 2>&1 || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_nodejs() {
    log_info "Installing Node.js ${NODEJS_VERSION} with npm and yarn..."
    
    # Determine architecture
    local arch="$(uname -m)"
    case "$arch" in
        "x86_64") arch="x64" ;;
        "aarch64") arch="arm64" ;;
        *) log_error "Unsupported architecture: $arch"; return 1 ;;
    esac
    
    # Download and install Node.js
    local temp_dir="$(mktemp -d)"
    trap "rm -rf '${temp_dir}'" EXIT
    
    local download_url="https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-${arch}.tar.xz"
    log_info "Downloading Node.js from: ${download_url}"
    
    curl -fsSL "${download_url}" -o "${temp_dir}/nodejs.tar.xz"
    
    # Extract Node.js to /usr/local
    tar -C /usr/local --strip-components=1 -xJf "${temp_dir}/nodejs.tar.xz"
    
    # Verify Node.js installation
    if command -v node >/dev/null 2>&1; then
        log_success "Node.js installed successfully: $(node --version)"
    else
        log_error "Node.js installation verification failed"
        return 1
    fi
    
    if command -v npm >/dev/null 2>&1; then
        log_success "npm installed successfully: $(npm --version)"
    fi
    
    # Install yarn package manager
    npm install -g yarn
    
    if command -v yarn >/dev/null 2>&1; then
        log_success "Yarn installed successfully: $(yarn --version)"
    fi
    
    # Install pnpm package manager
    npm install -g pnpm
    
    if command -v pnpm >/dev/null 2>&1; then
        log_success "pnpm installed successfully: $(pnpm --version)"
    fi
    
    # Install common global packages
    npm install -g \
        typescript \
        ts-node \
        nodemon \
        pm2 \
        eslint \
        prettier \
        @vue/cli \
        @angular/cli \
        create-react-app \
        next \
        express-generator
    
    # Set npm global directory
    mkdir -p /usr/local/lib/node_modules
    npm config set prefix /usr/local
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Setting up Node.js development environment..."
    
    is_installed && { log_info "Node.js is already installed"; return 0; }
    
    install_nodejs
    
    log_success "Node.js ${NODEJS_VERSION} development environment installed successfully"
}

main "$@"
