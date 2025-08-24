#!/bin/bash
# =============================================================================
# Enhanced Development Tools Installation Script
# =============================================================================
# DESCRIPTION: Installs modern CLI tools and creates necessary symlinks
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# VERSION: 1.0.0
# =============================================================================

set -euo pipefail

# Load libraries
. /opt/laragis/scripts/liblog.sh

# Core enhanced tools (usually available in repos)
readonly CORE_ENHANCED_TOOLS=(
  "jq"
  "htop"
  "tree"
  # "rsync"  # Already in 02-essential-pkgs.sh NETWORK_TOOLS
  "httpie"
)

# Modern CLI tools (may need EPEL or external sources)
readonly MODERN_CLI_TOOLS=(
  "ripgrep"
  "fzf"
  "bat"
  "yq"
  "tldr"
  "ncdu"
  "glances"
  "speedtest-cli"
)

# File and system tools
readonly FILE_SYSTEM_TOOLS=(
  "fd-find"
  "eza"
  "zoxide"
  "duf"
  "procs"
  "sd"
  "broot"
)

# Network and monitoring tools
readonly NETWORK_MONITORING_TOOLS=(
  "gping"
  "ctop"
  "bpytop"
  "NetworkManager"
)

# Terminal and productivity tools
readonly TERMINAL_PRODUCTIVITY_TOOLS=(
  "mcfly"
  "starship"
  "fastfetch"
  "thefuck"
  "choose"
  "hyperfine"
  "just"
  "zellij"
  "yazi"
)

create_symlinks() {
  info "Creating symlinks for tool compatibility..."
  
  # Create batcat symlink if bat exists but batcat doesn't
  if command -v bat >/dev/null && ! command -v batcat >/dev/null; then
    info "✓ Creating batcat symlink..."
    ln -sf "$(command -v bat)" /usr/local/bin/batcat
  fi
  
  # Create fd symlink if fdfind exists but fd doesn't
  if command -v fdfind >/dev/null && ! command -v fd >/dev/null; then
    info "✓ Creating fd symlink..."
    ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  fi
  
  # Create speedtest symlink if speedtest-cli exists
  if command -v speedtest-cli >/dev/null && ! command -v speedtest >/dev/null; then
    info "✓ Creating speedtest symlink..."
    ln -sf "$(command -v speedtest-cli)" /usr/local/bin/speedtest
  fi
  
  info "Symlinks configuration completed!"
}

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
        info "Note: These tools may be available via external installation methods"
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

install_external_tools() {
  info "Installing tools that require external sources..."
  
  # List of tools that typically need external installation
  local external_tools=(
    "starship"
    "zellij" 
    "yazi"
    "fastfetch"
    "mcfly"
    "choose"
    "hyperfine"
    "just"
    "broot"
    "gping"
    "duf"
    "procs"
    "sd"
    "ctop"
  )
  
  warn "The following tools may need external installation:"
  for tool in "${external_tools[@]}"; do
    warn "  - $tool (check /opt/laragis/scripts/tools/ for installation scripts)"
  done
  
  info "External tools installation will be handled by individual tool scripts"
}

main() {
  info "Starting enhanced development tools installation..."
  
  # Combine all packages for single transaction (fastest approach)
  local all_packages=(
    "${CORE_ENHANCED_TOOLS[@]}" 
    "${MODERN_CLI_TOOLS[@]}" 
    "${FILE_SYSTEM_TOOLS[@]}" 
    "${NETWORK_MONITORING_TOOLS[@]}" 
    "${TERMINAL_PRODUCTIVITY_TOOLS[@]}"
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
      info "Note: Many modern tools may not be available in standard repos"
      
      # Fallback to group installation for better error handling
      install_package_group "Core Enhanced Tools" "${CORE_ENHANCED_TOOLS[@]}"
      install_package_group "Modern CLI Tools" "${MODERN_CLI_TOOLS[@]}"
      install_package_group "File & System Tools" "${FILE_SYSTEM_TOOLS[@]}"
      install_package_group "Network & Monitoring Tools" "${NETWORK_MONITORING_TOOLS[@]}"
      install_package_group "Terminal & Productivity Tools" "${TERMINAL_PRODUCTIVITY_TOOLS[@]}"
    fi
  else
    info "✓ All packages already installed, skipping installation"
  fi
  
  # Handle external tools
  install_external_tools
  
  # Create symlinks for compatibility
  create_symlinks
  
  info "Enhanced development tools setup completed successfully!"
  info "Check logs above for any tools that need external installation"
}

main "$@"