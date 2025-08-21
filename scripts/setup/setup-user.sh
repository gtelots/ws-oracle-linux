#!/bin/bash
# =============================================================================
# User Setup Script - Create non-root user with sudo privileges
# =============================================================================

set -euo pipefail

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../common" && pwd)"

# Source common functions
source "$COMMON_DIR/functions.sh"
source "$COMMON_DIR/system-functions.sh"
source "$COMMON_DIR/user-functions.sh"

# Main execution
main() {
    log_info "Starting user setup process"
    log_info "Script version: 2.0.0 (modular)"
    
    # Print environment for debugging
    print_debug_environment
    
    log_info "Environment variables:"
    log_info "  USERNAME=${USERNAME:-<not set>}"
    log_info "  USER_UID=${USER_UID:-<not set>}"
    log_info "  USER_GID=${USER_GID:-<not set>}"
    log_info "  ROOT_PASSWORD=${ROOT_PASSWORD:+<set>}"
    log_info "  USER_PASSWORD=${USER_PASSWORD:+<set>}"
    
    # Validate required environment variables
    validate_env_vars "USERNAME" "USER_UID" "USER_GID" || exit 1
    
    # Validate user arguments specifically
    validate_user_args || exit 1
    
    # Validate numeric values
    validate_numeric "USER_UID" "$USER_UID" || exit 1
    validate_numeric "USER_GID" "$USER_GID" || exit 1
    
    # Set root password if provided
    if [[ -n "${ROOT_PASSWORD:-}" ]]; then
        set_user_password "root" "$ROOT_PASSWORD" || exit 1
    else
        log_info "No root password provided, keeping existing"
    fi
    
    # Setup user completely
    setup_user_complete "$USERNAME" "$USER_UID" "$USER_GID" "${USER_PASSWORD:-}" || exit 1
    
    log_success "User setup completed successfully"
    log_success "  User: ${USERNAME} (UID: ${USER_UID}, GID: ${USER_GID})"
    log_success "  Sudo: Enabled without password via wheel group"
    log_success "  Home: /home/${USERNAME}"
    log_success "  Shell: /bin/bash"
}

# Run main function
main "$@"
