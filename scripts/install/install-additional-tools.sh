#!/bin/bash
# -----------------------------------------------------------------------------
# Additional Tools Installation Script
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
    log "Starting additional tools installation"
    
    # Install tools by running individual scripts
    # Each script checks its own INSTALL_* environment variable
    run_tool_install "install-ansible.sh"
    run_tool_install "install-crontab.sh"
    run_tool_install "install-ngrok.sh"
    run_tool_install "install-tailscale.sh"
    run_tool_install "install-terraform.sh"
    run_tool_install "install-cloudflare.sh"
    run_tool_install "install-teleport.sh"
    run_tool_install "install-dry.sh"
    run_tool_install "install-wp-cli.sh"
    run_tool_install "install-docker.sh"
    run_tool_install "install-supervisor.sh"
    
    log "Additional tools installation completed"
}

# Run main function
main "$@"
