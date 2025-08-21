#!/bin/bash
# =============================================================================
# Package Installer Demo
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/functions.sh"

demo_package_installer() {
    log_banner "PACKAGE INSTALLER DEMO"
    
    log_info "Testing smart package installer..." "DEMO"
    
    # Test basic installation
    log_info "Demo: Basic package installation" "DEMO"
    echo "Command: pkg-install curl wget"
    
    # Test group installation  
    log_info "Demo: Group installation" "DEMO"
    echo "Command: pkg-install --group 'Development Tools' gcc make cmake"
    
    # Test dependency installation
    log_info "Demo: With dependencies" "DEMO"  
    echo "Command: pkg-install --with-deps docker containerd runc"
    
    # Show help
    log_info "Demo: Help information" "DEMO"
    echo "Command: pkg-install --help"
    
    log_separator
    
    # Show optimized flags for different distros
    log_info "Optimized flags by distribution:" "DEMO"
    log_info "  DNF/YUM: --setopt=install_weak_deps=False --nodocs --best --allowerasing" "DEMO"
    log_info "  APT:     --no-install-recommends --no-install-suggests + cleanup" "DEMO" 
    log_info "  APK:     --no-cache --update" "DEMO"
    log_info "  Zypper:  --no-recommends" "DEMO"
    log_info "  Pacman:  --noconfirm" "DEMO"
    
    log_separator
    
    # Show environment shortcuts
    log_info "Environment shortcuts available:" "DEMO"
    log_info "  \$PKG curl wget              # Short form" "DEMO"
    log_info "  pkg-install curl wget       # Full command" "DEMO"
    log_info "  /usr/local/bin/pkg-install   # Direct path" "DEMO"
    
    log_success "Package installer demo completed!" "DEMO"
}

main() {
    demo_package_installer
    
    # Test actual functionality if we're in container
    if is_container; then
        log_info "Testing in container environment..." "DEMO"
        
        # Test if pkg-install is available
        if command -v pkg-install >/dev/null 2>&1; then
            log_success "pkg-install command is available!" "DEMO"
            
            # Show help
            log_info "Showing help:" "DEMO"
            pkg-install --help
        else
            log_warning "pkg-install not found in PATH" "DEMO"
            log_info "Run this after Docker build completes" "DEMO"
        fi
    else
        log_info "Not in container - skipping live test" "DEMO"
    fi
}

main "$@"
