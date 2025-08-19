#!/bin/bash
# -----------------------------------------------------------------------------
# Additional Tools Installation Script - LEGACY VERSION
# -----------------------------------------------------------------------------
# NOTE: This script is now primarily for reference or manual installation.
# In the Dockerfile, each tool is installed in separate layers for better
# Docker cache optimization. See Dockerfile stages for the optimized approach.
# -----------------------------------------------------------------------------
# This script orchestrates installation of additional development tools
# by calling individual installation scripts for better maintainability
# -----------------------------------------------------------------------------

set -euo pipefail

# Function to log messages
log() {
    echo "==> $1"
}

# Function to run tool installation script
run_tool_install() {
    local script_name="$1"
    local script_path="/usr/local/scripts/tools/$script_name"
    
    if [ -f "$script_path" ]; then
        log "Running $script_name"
        bash "$script_path"
    else
        log "Warning: $script_name not found at $script_path"
    fi
}

# Main installation function
main() {
    log "Starting additional tools installation (Legacy mode)"
    log "NOTE: For Docker builds, tools are installed in separate stages for better caching"
    
    # Install infrastructure tools (most stable)
    log "==> Installing infrastructure tools..."
    run_tool_install "install-crontab.sh"
    run_tool_install "install-supervisor.sh"
    
    # Install DevOps & Infrastructure tools
    log "==> Installing DevOps tools..."
    run_tool_install "install-ansible.sh"
    run_tool_install "install-terraform.sh"
    run_tool_install "install-cloudflare.sh"
    
    # Install container & system tools
    log "==> Installing container tools..."
    run_tool_install "install-docker.sh"
    run_tool_install "install-dry.sh"
    
    # Install web development tools
    log "==> Installing web development tools..."
    run_tool_install "install-wp-cli.sh"
    
    # Install network & remote access tools
    log "==> Installing network tools..."
    run_tool_install "install-ngrok.sh"
    run_tool_install "install-tailscale.sh"
    run_tool_install "install-teleport.sh"
    
    log "Additional tools installation completed"
    log "Total tools processed: 10"
}

# Show usage information
show_usage() {
    cat << EOF
Additional Tools Installation Script (Legacy)

USAGE:
    $0 [OPTIONS]

DESCRIPTION:
    This script installs additional development tools by calling individual
    installation scripts. Each tool checks its own INSTALL_* environment
    variable to determine if it should be installed.

DOCKER OPTIMIZATION NOTE:
    In Docker builds, each tool is installed in separate stages for better
    cache optimization. This script is primarily for manual installations
    or reference.

TOOLS INSTALLED (in order):
    1. Infrastructure: crontab, supervisor
    2. DevOps: ansible, terraform, cloudflare
    3. Container: docker, dry
    4. Web Dev: wp-cli
    5. Network: ngrok, tailscale, teleport

ENVIRONMENT VARIABLES:
    INSTALL_CRONTAB     - Install crontab utility (default: 1)
    INSTALL_SUPERVISOR  - Install Supervisor process manager (default: 1)
    INSTALL_ANSIBLE     - Install Ansible automation (default: 1)
    INSTALL_TERRAFORM   - Install Terraform IaC (default: 1)
    INSTALL_CLOUDFLARE  - Install Cloudflare CLI (default: 1)
    INSTALL_DOCKER      - Install Docker (default: 1)
    INSTALL_DRY         - Install Dry Docker manager (default: 1)
    INSTALL_WP_CLI      - Install WordPress CLI (default: 1)
    INSTALL_NGROK       - Install Ngrok tunneling (default: 0)
    INSTALL_TAILSCALE   - Install Tailscale VPN (default: 0)
    INSTALL_TELEPORT    - Install Teleport access (default: 0)

EXAMPLES:
    # Install all tools (respects environment variables)
    $0

    # Install only specific tools
    INSTALL_ANSIBLE=1 INSTALL_DOCKER=1 $0

    # Skip network tools
    INSTALL_NGROK=0 INSTALL_TAILSCALE=0 INSTALL_TELEPORT=0 $0

EOF
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    *)
        # Run main function
        main "$@"
        ;;
esac
