#!/bin/bash
# =============================================================================
# Essential System Utilities Installation Script
# =============================================================================
# DESCRIPTION: Installs essential command-line utilities and networking tools
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# VERSION: 1.0.0
# =============================================================================

set -euo pipefail

# Load libraries
. /opt/laragis/scripts/liblog.sh

# Essential packages grouped by category
readonly NETWORK_TOOLS=(
  "curl"
  "wget" 
  "openssl"
  "bind-utils"
  "iproute"
  "iputils"
  "openssh-clients"
  "openssh-server"
  "rsync"
  "telnet"
  "nc"
)

readonly ARCHIVE_TOOLS=(
  "tar"
  "gzip"
  "bzip2"
  "xz"
  "unzip"
  "zip"
  "p7zip"
  "lz4"
  "zstd"
)

readonly SYSTEM_UTILS=(
  "procps-ng"
  "util-linux"
  "findutils"
  "which"
  "diffutils"
  "less"
  "file"
  "lsof"
)

readonly TERMINAL_LIBRARIES=(
  "ncurses"
  "ncurses-devel"
  "readline"
  # "readline-devel"  # Moved to 03-dev-pkgs.sh DEV_LIBRARIES
)

readonly EDITOR_TOOLS=(
  "vim"
  "nano"
  "tmux"
  "screen"
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
  info "Starting essential packages installation..."
  
  # Combine all packages for single transaction (fastest approach)
  local all_packages=(
    "${NETWORK_TOOLS[@]}" 
    "${ARCHIVE_TOOLS[@]}" 
    "${SYSTEM_UTILS[@]}" 
    "${TERMINAL_LIBRARIES[@]}" 
    "${EDITOR_TOOLS[@]}"
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
      install_package_group "Network Tools" "${NETWORK_TOOLS[@]}"
      install_package_group "Archive Tools" "${ARCHIVE_TOOLS[@]}"
      install_package_group "System Utilities" "${SYSTEM_UTILS[@]}"
      install_package_group "Terminal Libraries" "${TERMINAL_LIBRARIES[@]}"
      install_package_group "Editor Tools" "${EDITOR_TOOLS[@]}"
    fi
  else
    info "✓ All packages already installed, skipping installation"
  fi
  
  info "All essential packages installation completed successfully!"
}

main "$@"