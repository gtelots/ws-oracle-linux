#!/bin/bash
# Oracle Linux 9 Development Tools Installation Script
# Modular installation following Laradock patterns and enterprise best practices
# Security-hardened with proper error handling and validation

set -euo pipefail

# =============================================================================
# Configuration and Constants
# =============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/var/log/install-dev-tools.log"
readonly TEMP_DIR="/tmp/dev-tools-install"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# =============================================================================
# Utility Functions
# =============================================================================

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $*${NC}" | tee -a "${LOG_FILE}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $*${NC}" | tee -a "${LOG_FILE}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*${NC}" | tee -a "${LOG_FILE}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*${NC}" | tee -a "${LOG_FILE}"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root for security reasons"
    fi
}

check_system() {
    if ! command -v microdnf &> /dev/null; then
        error "This script requires Oracle Linux with microdnf package manager"
    fi
    
    if ! grep -q "Oracle Linux" /etc/os-release; then
        warn "This script is designed for Oracle Linux but will attempt to continue"
    fi
}

create_temp_dir() {
    mkdir -p "${TEMP_DIR}"
    trap 'rm -rf "${TEMP_DIR}"' EXIT
}

# =============================================================================
# Installation Functions
# =============================================================================

install_modern_cli_tools() {
    log "Installing modern CLI tools and productivity utilities..."
    
    # Install Rust-based CLI tools
    local tools=(
        "https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-x86_64-unknown-linux-musl.tar.gz|bat"
        "https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip|exa"
        "https://github.com/sharkdp/fd/releases/download/v8.7.0/fd-v8.7.0-x86_64-unknown-linux-musl.tar.gz|fd"
        "https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep-13.0.0-x86_64-unknown-linux-musl.tar.gz|rg"
        "https://github.com/dandavison/delta/releases/download/0.16.5/delta-0.16.5-x86_64-unknown-linux-musl.tar.gz|delta"
    )
    
    for tool_info in "${tools[@]}"; do
        local url="${tool_info%|*}"
        local binary="${tool_info#*|}"
        
        info "Installing ${binary}..."
        
        if [[ "${url}" == *.zip ]]; then
            curl -fsSL "${url}" -o "${TEMP_DIR}/${binary}.zip"
            unzip -q "${TEMP_DIR}/${binary}.zip" -d "${TEMP_DIR}/"
            find "${TEMP_DIR}" -name "${binary}" -type f -executable -exec sudo mv {} /usr/local/bin/ \;
        else
            curl -fsSL "${url}" | tar -xzC "${TEMP_DIR}"
            find "${TEMP_DIR}" -name "${binary}" -type f -executable -exec sudo mv {} /usr/local/bin/ \;
        fi
        
        if command -v "${binary}" &> /dev/null; then
            log "✅ ${binary} installed successfully"
        else
            warn "❌ Failed to install ${binary}"
        fi
    done
}

install_development_languages() {
    log "Installing development language runtimes and tools..."
    
    # Install Node.js via NodeSource repository
    info "Installing Node.js..."
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo microdnf install -y nodejs
    
    # Install Yarn package manager
    sudo npm install -g yarn pnpm
    
    # Install Python development tools
    info "Installing Python development tools..."
    sudo microdnf install -y python3-pip python3-venv python3-wheel
    pip3 install --user --upgrade pip setuptools wheel
    pip3 install --user pipenv poetry black flake8 mypy pytest
    
    # Install Go
    info "Installing Go..."
    local go_version="1.21.0"
    curl -fsSL "https://golang.org/dl/go${go_version}.linux-amd64.tar.gz" | \
        sudo tar -xzC /usr/local
    
    # Install Rust
    info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    
    log "✅ Development languages installed successfully"
}

install_container_tools() {
    log "Installing container and orchestration tools..."
    
    # Install Docker CLI (for compatibility)
    info "Installing Docker CLI..."
    sudo microdnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo microdnf install -y docker-ce-cli docker-compose-plugin
    
    # Install Kubernetes tools
    info "Installing Kubernetes tools..."
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
    
    # Install kubectl
    local kubectl_version
    kubectl_version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -fsSL "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl" -o "${TEMP_DIR}/kubectl"
    sudo install -o root -g root -m 0755 "${TEMP_DIR}/kubectl" /usr/local/bin/kubectl
    
    # Install Helm
    curl -fsSL https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar -xzC "${TEMP_DIR}"
    sudo mv "${TEMP_DIR}/linux-amd64/helm" /usr/local/bin/
    
    log "✅ Container tools installed successfully"
}

install_database_clients() {
    log "Installing database clients and tools..."
    
    # Install database clients
    sudo microdnf install -y \
        mysql \
        postgresql \
        redis
    
    # Install MongoDB client
    info "Installing MongoDB client..."
    cat <<EOF | sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
    
    sudo microdnf install -y mongodb-mongosh
    
    log "✅ Database clients installed successfully"
}

install_security_tools() {
    log "Installing security and monitoring tools..."
    
    # Install security scanning tools
    sudo microdnf install -y \
        nmap \
        wireshark-cli \
        tcpdump \
        netstat-nat \
        lsof
    
    # Install system monitoring tools
    sudo microdnf install -y \
        htop \
        iotop \
        nethogs \
        dstat \
        sysstat
    
    log "✅ Security tools installed successfully"
}

configure_shell_environment() {
    log "Configuring shell environment and productivity features..."
    
    # Install Oh My Bash
    if [[ ! -d ~/.oh-my-bash ]]; then
        info "Installing Oh My Bash..."
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
    fi
    
    # Install useful shell plugins and themes
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-bash/custom/plugins/zsh-autosuggestions 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-bash/custom/plugins/zsh-syntax-highlighting 2>/dev/null || true
    
    log "✅ Shell environment configured successfully"
}

# =============================================================================
# Main Installation Process
# =============================================================================

main() {
    log "Starting Oracle Linux 9 development tools installation..."
    
    # Pre-installation checks
    check_root
    check_system
    create_temp_dir
    
    # Create log file
    sudo touch "${LOG_FILE}"
    sudo chown "$(whoami):$(whoami)" "${LOG_FILE}"
    
    # Run installation modules
    install_modern_cli_tools
    install_development_languages
    install_container_tools
    install_database_clients
    install_security_tools
    configure_shell_environment
    
    # Post-installation cleanup
    log "Cleaning up temporary files..."
    rm -rf "${TEMP_DIR}"
    
    log "🎉 Development tools installation completed successfully!"
    log "Please restart your shell or run 'source ~/.bashrc' to apply changes"
    
    # Display installed tools summary
    info "Installed tools summary:"
    echo "  • Modern CLI: bat, exa, fd, rg, delta"
    echo "  • Languages: Node.js, Python, Go, Rust"
    echo "  • Containers: Docker CLI, kubectl, Helm"
    echo "  • Databases: MySQL, PostgreSQL, Redis, MongoDB"
    echo "  • Security: nmap, tcpdump, htop, iotop"
    echo "  • Shell: Oh My Bash with plugins"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
