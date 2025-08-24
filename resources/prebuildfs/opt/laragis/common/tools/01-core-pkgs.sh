#!/bin/bash
# =============================================================================
# Core System Foundation Setup Script
# =============================================================================
# DESCRIPTION: Sets up repositories, installs core packages, and configures
#              basic system settings for Oracle Linux 9
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# VERSION: 1.0.0
# =============================================================================

set -euo pipefail

# Load libraries
. /opt/laragis/scripts/liblog.sh

# Repository and system update
setup_repositories() {
  info "Setting up repositories and updating system..."
  
  # Check if EPEL is already configured
  if dnf repolist enabled | grep -q epel; then
    info "✓ EPEL repository already enabled"
  else
    # Enable EPEL repository
    info "Configuring EPEL repository..."
    if ! pkg-install oracle-epel-release-el9; then
      info "Fallback: Enabling EPEL via config-manager..."
      dnf -y config-manager --enable ol9_developer_EPEL || warn "EPEL setup failed"
    fi
  fi
  
  # Update system with security patches (combined with cache refresh)
  info "Updating system packages and refreshing cache..."
  if ! dnf -y update-minimal --security --setopt=install_weak_deps=False --refresh; then
    warn "Security update failed or no updates available"
  fi
}

# Core system packages
readonly CORE_PACKAGES=(
  "ca-certificates"
  "tzdata" 
  "shadow-utils"
  "passwd"
  "sudo"
  "systemd"
)

# Locale packages
readonly LOCALE_PACKAGES=(
  "glibc-langpack-en"
  "glibc-langpack-vi"
  "glibc-locale-source"
)

install_package_group() {
  local group_name=$1
  shift
  local packages=("$@")
  
  info "Installing $group_name..."
  
  # Check which packages are already installed (faster batch check)
  local to_install=()
  local already_installed=()
  
  info "Checking package status..."
  for package in "${packages[@]}"; do
    if rpm -q "$package" >/dev/null 2>&1; then
      already_installed+=("$package")
    else
      to_install+=("$package")
    fi
  done
  
  # Report already installed packages
  if [[ ${#already_installed[@]} -gt 0 ]]; then
    info "✓ Already installed: ${already_installed[*]}"
  fi
  
  # Install missing packages in batch (much faster)
  if [[ ${#to_install[@]} -gt 0 ]]; then
    info "Installing missing packages: ${to_install[*]}"
    
    # Use pkg-install for better retry logic and optimization
    if pkg-install "${to_install[@]}"; then
      info "✓ All packages installed successfully"
    else
      warn "⚠ Some packages may have failed, checking individual status..."
      
      # Fallback: check which ones actually failed
      local failed_packages=()
      for package in "${to_install[@]}"; do
        if ! rpm -q "$package" >/dev/null 2>&1; then
          failed_packages+=("$package")
        fi
      done
      
      if [[ ${#failed_packages[@]} -gt 0 ]]; then
        warn "Failed packages: ${failed_packages[*]}"
        # Try individual installation for failed packages
        for package in "${failed_packages[@]}"; do
          info "Retrying individual install: $package"
          if pkg-install "$package"; then
            info "✓ $package installed on retry"
          else
            warn "✗ $package installation failed completely"
          fi
        done
      fi
    fi
  else
    info "✓ All packages already installed"
  fi
  
  info "$group_name installation completed!"
}

configure_system() {
  info "Configuring basic system settings..."
  
  # Set timezone if TZ variable is available
  if [[ -n "${TZ:-}" ]]; then
    info "Setting timezone to: $TZ"
    if [[ -f "/usr/share/zoneinfo/$TZ" ]]; then
      ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
      echo "$TZ" > /etc/timezone
    else
      warn "Timezone $TZ not found, keeping default"
    fi
  fi
  
  # Set locale
  info "Configuring locale settings..."
  if command -v localectl >/dev/null 2>&1; then
    # Try to set locale, but don't fail if systemd is not running
    if systemctl is-system-running >/dev/null 2>&1 || [[ -z "${SYSTEMD_IGNORE_CHROOT:-}" ]]; then
      localectl set-locale LANG=en_US.UTF-8 2>/dev/null || warn "Failed to set locale via localectl"
    else
      info "Systemd not available, setting locale manually..."
      echo 'LANG=en_US.UTF-8' > /etc/locale.conf
    fi
  else
    info "localectl not available, setting locale manually..."
    echo 'LANG=en_US.UTF-8' > /etc/locale.conf
  fi
  
  info "System configuration completed!"
}

main() {
  info "Starting core system foundation setup..."
  
  # Step 1: Repository setup
  setup_repositories
  
  # Step 2: Install all packages in optimized batches
  info "Installing all packages in optimized batches..."
  
  # Combine all packages for single transaction (fastest approach)
  local all_packages=("${CORE_PACKAGES[@]}" "${LOCALE_PACKAGES[@]}")
  
  info "Checking status of ${#all_packages[@]} packages..."
  local to_install=()
  local already_installed=()
  
  # Batch check all packages at once
  for package in "${all_packages[@]}"; do
    if rpm -q "$package" >/dev/null 2>&1; then
      already_installed+=("$package")
    else
      to_install+=("$package")
    fi
  done
  
  # Report status
  if [[ ${#already_installed[@]} -gt 0 ]]; then
    info "✓ Already installed (${#already_installed[@]}): ${already_installed[*]}"
  fi
  
  # Install all missing packages in single transaction
  if [[ ${#to_install[@]} -gt 0 ]]; then
    info "Installing ${#to_install[@]} missing packages in single transaction..."
    info "Packages: ${to_install[*]}"
    
    if pkg-install "${to_install[@]}"; then
      info "✓ All ${#to_install[@]} packages installed successfully"
    else
      warn "⚠ Batch installation failed, falling back to individual checks..."
      
      # Fallback to group installation for better error handling
      install_package_group "Core System Packages" "${CORE_PACKAGES[@]}"
      install_package_group "Locale Packages" "${LOCALE_PACKAGES[@]}"
    fi
  else
    info "✓ All packages already installed, skipping installation"
  fi
  
  # Step 3: Configure system
  configure_system
  
  info "Core system foundation setup completed successfully!"
}

main "$@"