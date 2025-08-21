#!/bin/bash
# =============================================================================
# Test Script for New Modular Function System
# =============================================================================

set -euo pipefail

# Load common functions (new way)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/functions.sh"

# Test all function categories
main() {
    log_banner "TESTING MODULAR FUNCTIONS"
    
    # Test logging functions
    log_info "Testing logging functions"
    log_success "This is a success message"
    log_warning "This is a warning message"
    log_error "This is an error message (non-fatal for test)"
    log_debug "This is a debug message (only shows if DEBUG=true)"
    
    log_separator
    
    # Test specialized logging
    log_install "test-tool" "1.0.0"
    log_install_success "test-tool" "1.0.0"
    log_install_skip "another-tool" "already installed"
    
    log_separator
    
    # Test utility functions
    log_info "Testing utility functions"
    log_info "Architecture: $(get_arch)"
    log_info "Container: $(is_container && echo "yes" || echo "no")"
    log_info "Command exists (bash): $(command_exists bash && echo "yes" || echo "no")"
    
    # Test URL check (with timeout)
    if check_url "https://httpbin.org/status/200" 5; then
        log_success "URL check passed"
    else
        log_warning "URL check failed (expected if no internet)"
    fi
    
    log_separator
    
    # Test system functions
    log_info "Testing system functions"
    validate_env_vars "HOME" "USER" && log_success "Environment validation passed"
    validate_numeric "TEST_NUM" "123" && log_success "Numeric validation passed"
    
    log_info "System info:"
    log_info "  OS: $(get_system_info os)"
    log_info "  Arch: $(get_system_info arch)"
    log_info "  Package Manager: $(get_package_manager 2>/dev/null || echo "none detected")"
    
    log_separator
    
    # Test user functions (read-only)
    log_info "Testing user functions (read-only)"
    if validate_env_vars "USERNAME" "USER_UID" "USER_GID"; then
        log_success "User environment variables validated"
    else
        log_info "Setting test user variables"
        export USERNAME="testuser"
        export USER_UID="1001"  
        export USER_GID="1001"
        validate_user_args && log_success "User arguments validated"
    fi
    
    log_separator
    log_banner "ALL TESTS COMPLETED"
    log_success "Modular function system is working correctly!"
}

# Run tests
main "$@"
