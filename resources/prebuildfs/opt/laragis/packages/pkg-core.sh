#!/usr/bin/env bash
# =============================================================================
# Core System Packages Installation Script  
# =============================================================================
# DESCRIPTION: Installs core system packages and Python runtime
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# VERSION: 1.0.0
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/user.sh
. /opt/laragis/lib/pkg.sh

# Configuration
readonly SCRIPT_NAME="pkg-core"
readonly SCRIPT_VERSION="1.0.0"

# Python version from environment or default
readonly PYTHON_VERSION="${PYTHON_VERSION:-3.12}"

# Configure repositories and package management
configure_repositories() {
  log_info "Configuring repositories and package management..."
  
  # Install dnf plugins core
  dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
    dnf-plugins-core
  
  # Enable EPEL repository - try Oracle's first, fallback to developer EPEL
  log_info "Enabling EPEL repository..."
  if ! dnf -y install oracle-epel-release-el9; then
    log_warn "Oracle EPEL not available, enabling developer EPEL..."
    dnf -y config-manager --enable ol9_developer_EPEL || true
  fi
  
  log_success "Repository configuration completed"
}

# Apply security updates
apply_security_updates() {
  log_info "Applying security updates..."
  
  # Apply security updates (non-fatal if none available)
  if dnf -y update-minimal --security --setopt=install_weak_deps=False --refresh; then
    log_success "Security updates applied successfully"
  else
    log_warn "No security updates available or update failed"
  fi
}

# Install core system packages
install_core_packages() {
  log_info "Installing core system packages..."
  
  local core_packages=(
    # Core system packages
    ca-certificates
    tzdata
    shadow-utils
    passwd
    sudo
    systemd
    
    # Locale support
    glibc-langpack-en
    glibc-langpack-vi
    glibc-locale-source
  )
  
  # Install core packages in single transaction
  dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
    "${core_packages[@]}"
  
  log_success "Core system packages installed successfully"
}

# Install Python runtime and development tools
install_python_runtime() {
  log_info "Installing Python ${PYTHON_VERSION} runtime and development tools..."
  
  local python_packages=(
    # Python 3 default packages
    python3
    python3-pip
    python3-setuptools
    python3-devel
    
    # Specific Python version packages
    "python${PYTHON_VERSION}"
    "python${PYTHON_VERSION}-pip"
    "python${PYTHON_VERSION}-setuptools"
    "python${PYTHON_VERSION}-wheel"
    "python${PYTHON_VERSION}-devel"
  )

  # Create symbolic links for version consistency
  if [[ "${PYTHON_VERSION}" != "3" ]]; then
    ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python3
    ln -sf /usr/bin/pip${PYTHON_VERSION} /usr/local/bin/pip3
  fi
  
  # Install Python packages
  dnf -y install --setopt=install_weak_deps=False --setopt=tsflags=nodocs \
    "${python_packages[@]}"
  
  # Install pipx for isolated Python tool installation
  log_info "Installing pipx for isolated Python tools..."
  "pip${PYTHON_VERSION}" install pipx
  
  log_success "Python ${PYTHON_VERSION} runtime installed successfully"
}

# Configure timezone settings
configure_timezone() {
  local timezone="${TZ:-UTC}"
  
  log_info "Configuring timezone settings to ${timezone}..."
  
  # Set timezone
  ln -snf "/usr/share/zoneinfo/${timezone}" /etc/localtime
  echo "${timezone}" > /etc/timezone
  
  log_success "Timezone configured to ${timezone}"
}

# Verify repository configuration
verify_repositories() {
  log_info "Verifying repository configuration..."
  
  # List enabled repositories
  dnf repolist enabled
  
  log_success "Repository verification completed"
}

# Main installation function
main() {
  log_info "Core System Packages Installer v${SCRIPT_VERSION}"
  
  # Check prerequisites
  check_root
  
  # Execute installation steps
  configure_repositories
  apply_security_updates
  install_core_packages
  install_python_runtime
  configure_timezone
  verify_repositories
  cleanup_cache
  
  log_success "Core system packages installation completed successfully"
}

# Run main function
main "$@"