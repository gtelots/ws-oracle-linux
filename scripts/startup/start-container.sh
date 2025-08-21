#!/bin/bash

# -----------------------------------------------------------------------------
# Container Startup Script
# -----------------------------------------------------------------------------
# This script handles the container startup process:
# - Runs initialization scripts
# - Sets up services based on configuration
# - Starts appropriate service manager (Supervisor or SSH)
# -----------------------------------------------------------------------------

set -euo pipefail

# Get script directory and load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/functions.sh"

# Configuration
readonly INIT_DIR="/usr/local/scripts/init"
readonly SUPERVISOR_CMD="/usr/local/bin/start-supervisor"
readonly SSH_CMD="/usr/local/bin/start-sshd"

# Function to run initialization scripts
run_init_scripts() {
    log_info "Running initialization scripts..." "STARTUP"
    
    if [[ ! -d "$INIT_DIR" ]]; then
        log_info "No initialization directory found, skipping init scripts" "STARTUP"
        return 0
    fi
    
    # Find and execute all executable scripts in init directory
    local init_scripts
    init_scripts=$(find "$INIT_DIR" -type f -executable -name "*.sh" | sort)
    
    if [[ -z "$init_scripts" ]]; then
        log_info "No initialization scripts found" "STARTUP"
        return 0
    fi
    
    log_info "Found initialization scripts:" "STARTUP"
    echo "$init_scripts" | while read -r script; do
        log_info "  - $(basename "$script")" "STARTUP"
    done
    
    # Execute each script
    echo "$init_scripts" | while read -r script; do
        local script_name
        script_name=$(basename "$script")
        
        log_info "Executing: $script_name" "STARTUP"
        
        if "$script"; then
            log_success "✓ $script_name completed successfully" "STARTUP"
        else
            local exit_code=$?
            log_error "✗ $script_name failed with exit code: $exit_code" "STARTUP"
            # Continue with other scripts rather than failing completely
        fi
    done
    
    log_success "Initialization scripts completed" "STARTUP"
}

# Function to start Supervisor
start_supervisor() {
    log_info "Starting Supervisor service manager..." "STARTUP"
    
    if [[ ! -f "$SUPERVISOR_CMD" ]]; then
        log_error "Supervisor start script not found: $SUPERVISOR_CMD" "STARTUP"
        return 1
    fi
    
    if [[ ! -x "$SUPERVISOR_CMD" ]]; then
        log_error "Supervisor start script is not executable: $SUPERVISOR_CMD" "STARTUP"
        return 1
    fi
    
    log_info "Executing Supervisor..." "STARTUP"
    exec "$SUPERVISOR_CMD"
}

# Function to start SSH daemon
start_ssh() {
    log_info "Starting SSH daemon..." "STARTUP"
    
    if [[ ! -f "$SSH_CMD" ]]; then
        log_error "SSH start script not found: $SSH_CMD" "STARTUP"
        return 1
    fi
    
    if [[ ! -x "$SSH_CMD" ]]; then
        log_error "SSH start script is not executable: $SSH_CMD" "STARTUP"
        return 1
    fi
    
    log_info "Executing SSH daemon..." "STARTUP"
    exec "$SSH_CMD"
}

# Function to determine which service to start
determine_startup_mode() {
    local install_supervisor="${INSTALL_SUPERVISOR:-1}"
    
    if [[ "$install_supervisor" == "1" ]]; then
        log_info "Supervisor is enabled, will start Supervisor service manager" "STARTUP"
        return 0  # Use Supervisor
    else
        log_info "Supervisor is disabled, will start SSH daemon only" "STARTUP"
        return 1  # Use SSH only
    fi
}

# Main startup function
main() {
    log_banner "CONTAINER STARTUP"
    log_info "Container ID: $(hostname)" "STARTUP"
    log_info "User: $(whoami)" "STARTUP"
    log_info "Working directory: $(pwd)" "STARTUP"
    
    # Run initialization scripts
    run_init_scripts
    
    # Determine startup mode and start appropriate service
    if determine_startup_mode; then
        start_supervisor
    else
        start_ssh
    fi
}

# Handle signals gracefully
trap 'log_info "Received termination signal, shutting down..." "STARTUP"; exit 0' TERM INT

# Only run if called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
