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

# Load shared functions
# shellcheck source=../common/functions.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common/functions.sh"

# Color codes for output formatting
# Logging functions
log_warn() { echo -e "${YELLOW}[STARTUP]${NC} $*"; }
log_error() { echo -e "${RED}[STARTUP]${NC} $*"; }
log_debug() { echo -e "${BLUE}[STARTUP]${NC} $*"; }

# Configuration
readonly INIT_DIR="/usr/local/scripts/init"
readonly SUPERVISOR_CMD="/usr/local/bin/start-supervisor"
readonly SSH_CMD="/usr/local/bin/start-sshd"

# Function to run initialization scripts
run_init_scripts() {
    log_info "Running initialization scripts..."
    
    if [[ ! -d "$INIT_DIR" ]]; then
        log_info "No initialization directory found, skipping init scripts"
        return 0
    fi
    
    # Find and execute all executable scripts in init directory
    local init_scripts
    init_scripts=$(find "$INIT_DIR" -type f -executable -name "*.sh" | sort)
    
    if [[ -z "$init_scripts" ]]; then
        log_info "No initialization scripts found"
        return 0
    fi
    
    log_info "Found initialization scripts:"
    echo "$init_scripts" | while read -r script; do
        log_info "  - $(basename "$script")"
    done
    
    # Execute each script
    echo "$init_scripts" | while read -r script; do
        local script_name
        script_name=$(basename "$script")
        
        log_info "Executing: $script_name"
        
        if "$script"; then
            log_info "✓ $script_name completed successfully"
        else
            local exit_code=$?
            log_error "✗ $script_name failed with exit code: $exit_code"
            # Continue with other scripts rather than failing completely
        fi
    done
    
    log_info "Initialization scripts completed"
}

# Function to start Supervisor
start_supervisor() {
    log_info "Starting Supervisor service manager..."
    
    if [[ ! -f "$SUPERVISOR_CMD" ]]; then
        log_error "Supervisor start script not found: $SUPERVISOR_CMD"
        return 1
    fi
    
    if [[ ! -x "$SUPERVISOR_CMD" ]]; then
        log_error "Supervisor start script is not executable: $SUPERVISOR_CMD"
        return 1
    fi
    
    log_info "Executing Supervisor..."
    exec "$SUPERVISOR_CMD"
}

# Function to start SSH daemon
start_ssh() {
    log_info "Starting SSH daemon..."
    
    if [[ ! -f "$SSH_CMD" ]]; then
        log_error "SSH start script not found: $SSH_CMD"
        return 1
    fi
    
    if [[ ! -x "$SSH_CMD" ]]; then
        log_error "SSH start script is not executable: $SSH_CMD"
        return 1
    fi
    
    log_info "Executing SSH daemon..."
    exec "$SSH_CMD"
}

# Function to determine which service to start
determine_startup_mode() {
    local install_supervisor="${INSTALL_SUPERVISOR:-1}"
    
    if [[ "$install_supervisor" == "1" ]]; then
        log_info "Supervisor is enabled, will start Supervisor service manager"
        return 0  # Use Supervisor
    else
        log_info "Supervisor is disabled, will start SSH daemon only"
        return 1  # Use SSH only
    fi
}

# Main startup function
main() {
    log_info "Container startup initiated"
    log_info "Container ID: $(hostname)"
    log_info "User: $(whoami)"
    log_info "Working directory: $(pwd)"
    
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
trap 'log_info "Received termination signal, shutting down..."; exit 0' TERM INT

# Only run if called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
