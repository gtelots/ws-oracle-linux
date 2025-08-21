#!/bin/bash
# =============================================================================
# Example Script - Demonstrates how to use common functions
# =============================================================================

set -euo pipefail

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../common" && pwd)"

# Source common functions
source "$COMMON_DIR/functions.sh"
source "$COMMON_DIR/system-functions.sh"
source "$COMMON_DIR/user-functions.sh"

# Example usage of common functions
main() {
    log_info "Starting example script demonstration"
    
    # Print system information
    log_info "System Information:"
    log_info "  OS: $(get_system_info os)"
    log_info "  Architecture: $(get_system_info arch)"
    log_info "  Kernel: $(get_system_info kernel)"
    log_info "  Container: $(is_running_in_container && echo "yes" || echo "no")"
    
    # Package manager detection
    local pkg_manager
    if pkg_manager=$(get_package_manager); then
        log_success "Detected package manager: $pkg_manager"
    else
        log_error "No package manager detected"
    fi
    
    # Environment validation example
    if validate_env_vars "HOME" "USER"; then
        log_success "Basic environment variables validated"
    fi
    
    # Numeric validation example
    if validate_numeric "TEST_NUMBER" "123"; then
        log_success "Numeric validation works"
    fi
    
    # User functions example (read-only operations)
    if id -u "$(whoami)" >/dev/null 2>&1; then
        log_success "Current user exists: $(whoami)"
    fi
    
    log_success "Example script completed successfully"
}

# Run main function
main "$@"
