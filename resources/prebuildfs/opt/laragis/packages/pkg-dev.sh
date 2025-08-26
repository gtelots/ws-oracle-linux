#!/bin/bash
# =============================================================================
# Development Tools & Libraries Installation Script
# =============================================================================
# DESCRIPTION: Installs development tools, compilers, and development libraries
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# VERSION: 1.1.0 - Optimized for Oracle Linux 9 package availability
# =============================================================================
# 
# PACKAGE CHANGES FOR ORACLE LINUX 9 COMPATIBILITY:
# - Removed: ninja-build (not available in standard repos)
# - Removed: supervisor (not available in standard repos, use systemd instead)
# - Removed: neovim (not available in standard repos)
# - Added: vim-enhanced (standard alternative to neovim)
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Development tools grouped by category
readonly COMPILERS=(
  "gcc"
  "gcc-c++"
)

readonly BUILD_TOOLS=(
  "make"
  "cmake"
  "pkgconf-pkg-config"
  "autoconf"
  "automake"
  "libtool"
  "patch"
)

readonly DEV_LIBRARIES=(
  "openssl-devel"
  "zlib-devel"
  "libffi-devel"
  "readline-devel"
  "bzip2-devel"
  "xz-devel"
  "libxml2-devel"
  "libxslt-devel"
  "libcurl-devel"
  "sqlite-devel"
)

readonly RUNTIME_TOOLS=(
  "python3"
  "python3-pip"
  "python3-devel"
  "git"
  "cronie"
  # "supervisor"  # Not available in Oracle Linux 9 standard repos (use systemd instead)
  "sqlite"
  "vim-enhanced"  # Replaced neovim (not available in standard repos)
)

readonly MONITORING_TOOLS=(
  "sysstat"
  "iotop"
  "strace"
  "ltrace"
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

main() {
  info "Starting development packages installation..."
  
  # Combine all packages for single transaction (fastest approach)
  local all_packages=(
    "${COMPILERS[@]}" 
    "${BUILD_TOOLS[@]}" 
    "${DEV_LIBRARIES[@]}" 
    "${RUNTIME_TOOLS[@]}" 
    "${MONITORING_TOOLS[@]}"
  )
  
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
      warn "⚠ Batch installation failed, falling back to group installation..."
      
      # Fallback to group installation for better error handling
      install_package_group "Compilers" "${COMPILERS[@]}"
      install_package_group "Build Tools" "${BUILD_TOOLS[@]}"
      install_package_group "Development Libraries" "${DEV_LIBRARIES[@]}"
      install_package_group "Runtime Tools" "${RUNTIME_TOOLS[@]}"
      install_package_group "Monitoring Tools" "${MONITORING_TOOLS[@]}"
    fi
  else
    info "✓ All packages already installed, skipping installation"
  fi
  
  info "All development packages installation process completed successfully!"
}

main "$@"