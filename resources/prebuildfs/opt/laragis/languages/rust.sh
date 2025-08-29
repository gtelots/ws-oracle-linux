#!/usr/bin/env bash
# =============================================================================
# Rust Installation with Cargo
# =============================================================================
# DESCRIPTION: Install Rust programming language with Cargo package manager
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly RUST_VERSION="${RUST_VERSION:-1.84.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/rust.installed"

is_installed() { command -v rustc >/dev/null 2>&1 || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_rust() {
    log_info "Installing Rust ${RUST_VERSION} with Cargo..."
    
    # Install Rust via rustup
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain "${RUST_VERSION}"
    
    # Source Rust environment
    source ~/.cargo/env
    
    # Make Rust available system-wide
    ln -sf ~/.cargo/bin/rustc /usr/local/bin/rustc
    ln -sf ~/.cargo/bin/cargo /usr/local/bin/cargo
    ln -sf ~/.cargo/bin/rustup /usr/local/bin/rustup
    ln -sf ~/.cargo/bin/rustfmt /usr/local/bin/rustfmt
    ln -sf ~/.cargo/bin/clippy-driver /usr/local/bin/clippy-driver
    
    # Add Rust to system PATH
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /etc/environment
    
    # Install common Rust tools
    ~/.cargo/bin/cargo install cargo-edit cargo-watch cargo-tree
    
    # Install Rust components
    ~/.cargo/bin/rustup component add rustfmt clippy rust-src rust-analyzer
    
    # Verify installation
    if command -v rustc >/dev/null 2>&1; then
        log_success "Rust installed successfully: $(rustc --version)"
    else
        log_error "Rust installation verification failed"
        return 1
    fi
    
    if command -v cargo >/dev/null 2>&1; then
        log_success "Cargo installed successfully: $(cargo --version)"
    fi
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Setting up Rust development environment..."
    
    is_installed && { log_info "Rust is already installed"; return 0; }
    
    install_rust
    
    log_success "Rust ${RUST_VERSION} development environment installed successfully"
}

main "$@"
