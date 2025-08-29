#!/usr/bin/env bash
# =============================================================================
# Installation Utilities Library
# =============================================================================
# DESCRIPTION: Common installation patterns and utilities
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load dependencies
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/arch.sh
. /opt/laragis/lib/os.sh

# =============================================================================
# COMMON INSTALLATION PATTERNS
# =============================================================================

# Standard tool installation check
# Usage: is_tool_installed <tool_name> [lock_file_path]
is_tool_installed() {
  local tool_name="$1"
  local lock_file="${2:-}"
  
  os_command_is_installed "$tool_name" || [[ -n "$lock_file" && -f "$lock_file" ]]
}

# Create tool lock file
# Usage: create_tool_lock_file <lock_file_path>
create_tool_lock_file() {
  local lock_file="$1"
  local lock_dir="$(dirname "$lock_file")"
  
  mkdir -p "$lock_dir" && touch "$lock_file"
}

# Standard tool configuration setup
# Usage: setup_tool_config <tool_name> <version> [tool_folder]
setup_tool_config() {
  local tool_name="$1"
  local version_var="$2"
  local tool_folder="${3:-/opt/laragis/tools}"
  
  # Export common variables for use in calling script
  export TOOL_NAME="$tool_name"
  export TOOL_VERSION="$version_var"
  export TOOL_FOLDER="$tool_folder"
  export TOOL_LOCK_FILE="${tool_folder}/${tool_name}.installed"
}

# =============================================================================
# ARCHITECTURE AND PLATFORM DETECTION
# =============================================================================

# Get normalized architecture for GitHub releases
# Usage: get_github_arch
get_github_arch() {
  local arch="$(uname -m)"
  
  case "$arch" in
    "x86_64") echo "amd64" ;;
    "aarch64") echo "arm64" ;;
    "armv7l") echo "armv7" ;;
    "i386"|"i686") echo "386" ;;
    *) echo "$arch" ;;
  esac
}

# Get OS name for GitHub releases
# Usage: get_github_os
get_github_os() {
  local os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  
  case "$os" in
    "darwin") echo "darwin" ;;
    "linux") echo "linux" ;;
    "windows") echo "windows" ;;
    *) echo "$os" ;;
  esac
}

# Get Rust target triple
# Usage: get_rust_target
get_rust_target() {
  local arch="$(uname -m)"
  local os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  
  case "$arch" in
    "x86_64")
      case "$os" in
        "linux") echo "x86_64-unknown-linux-musl" ;;
        "darwin") echo "x86_64-apple-darwin" ;;
        *) echo "x86_64-unknown-linux-musl" ;;
      esac
      ;;
    "aarch64")
      case "$os" in
        "linux") echo "aarch64-unknown-linux-musl" ;;
        "darwin") echo "aarch64-apple-darwin" ;;
        *) echo "aarch64-unknown-linux-musl" ;;
      esac
      ;;
    *)
      log_error "Unsupported architecture: $arch"
      return 1
      ;;
  esac
}

# =============================================================================
# DOWNLOAD AND INSTALLATION UTILITIES
# =============================================================================

# Create temporary directory with cleanup trap
# Usage: create_temp_dir
create_temp_dir() {
  local temp_dir="$(mktemp -d)"
  trap "rm -rf '${temp_dir}'" EXIT
  echo "$temp_dir"
}

# Download file with retry and verification
# Usage: download_file <url> <output_path> [max_retries]
download_file() {
  local url="$1"
  local output_path="$2"
  local max_retries="${3:-3}"
  local retry_count=0
  
  log_info "Downloading from: ${url}"
  
  while [[ $retry_count -lt $max_retries ]]; do
    if curl -fsSL --connect-timeout 30 --max-time 300 "$url" -o "$output_path"; then
      log_success "Download completed successfully"
      return 0
    else
      retry_count=$((retry_count + 1))
      if [[ $retry_count -lt $max_retries ]]; then
        log_warn "Download failed, retrying... (attempt $retry_count/$max_retries)"
        sleep 2
      fi
    fi
  done
  
  log_error "Download failed after $max_retries attempts"
  return 1
}

# Install binary with proper permissions
# Usage: install_binary <source_path> <target_path> [permissions]
install_binary() {
  local source_path="$1"
  local target_path="$2"
  local permissions="${3:-755}"
  
  if [[ ! -f "$source_path" ]]; then
    log_error "Source binary not found: $source_path"
    return 1
  fi
  
  install -m "$permissions" "$source_path" "$target_path"
  log_success "Binary installed: $target_path"
}

# Create symbolic link with backup
# Usage: create_symlink <source> <target> [backup_suffix]
create_symlink() {
  local source="$1"
  local target="$2"
  local backup_suffix="${3:-.bak}"
  
  # Backup existing file if it exists and is not a symlink
  if [[ -f "$target" && ! -L "$target" ]]; then
    mv "$target" "${target}${backup_suffix}"
    log_info "Backed up existing file: ${target}${backup_suffix}"
  fi
  
  ln -sf "$source" "$target"
  log_success "Symlink created: $target -> $source"
}

# =============================================================================
# PACKAGE MANAGER UTILITIES
# =============================================================================

# Try package manager installation first
# Usage: try_package_install <package_name> [package_manager]
try_package_install() {
  local package_name="$1"
  local package_manager="${2:-auto}"
  
  case "$package_manager" in
    "dnf"|"auto")
      if command -v dnf >/dev/null 2>&1; then
        if dnf -y install "$package_name" 2>/dev/null; then
          log_success "$package_name installed via dnf"
          return 0
        fi
      fi
      ;;
    "apt")
      if command -v apt-get >/dev/null 2>&1; then
        if apt-get update && apt-get install -y "$package_name" 2>/dev/null; then
          log_success "$package_name installed via apt"
          return 0
        fi
      fi
      ;;
    "yum")
      if command -v yum >/dev/null 2>&1; then
        if yum -y install "$package_name" 2>/dev/null; then
          log_success "$package_name installed via yum"
          return 0
        fi
      fi
      ;;
  esac
  
  log_info "Package manager installation failed or not available for: $package_name"
  return 1
}

# Install via language-specific package manager
# Usage: install_via_language_pm <language> <package_name> [version]
install_via_language_pm() {
  local language="$1"
  local package_name="$2"
  local version="${3:-}"
  
  case "$language" in
    "cargo"|"rust")
      if command -v cargo >/dev/null 2>&1; then
        local install_cmd="cargo install $package_name"
        [[ -n "$version" ]] && install_cmd="$install_cmd --version $version"
        
        if eval "$install_cmd"; then
          log_success "$package_name installed via cargo"
          return 0
        fi
      fi
      ;;
    "npm"|"node")
      if command -v npm >/dev/null 2>&1; then
        local install_cmd="npm install -g $package_name"
        [[ -n "$version" ]] && install_cmd="$install_cmd@$version"
        
        if eval "$install_cmd"; then
          log_success "$package_name installed via npm"
          return 0
        fi
      fi
      ;;
    "pip"|"python")
      if command -v pip3 >/dev/null 2>&1; then
        local install_cmd="pip3 install $package_name"
        [[ -n "$version" ]] && install_cmd="$install_cmd==$version"
        
        if eval "$install_cmd"; then
          log_success "$package_name installed via pip"
          return 0
        fi
      fi
      ;;
    "gem"|"ruby")
      if command -v gem >/dev/null 2>&1; then
        local install_cmd="gem install $package_name"
        [[ -n "$version" ]] && install_cmd="$install_cmd --version $version"
        
        if eval "$install_cmd"; then
          log_success "$package_name installed via gem"
          return 0
        fi
      fi
      ;;
  esac
  
  log_info "Language package manager installation failed or not available for: $package_name"
  return 1
}

# =============================================================================
# VERIFICATION UTILITIES
# =============================================================================

# Verify tool installation and version
# Usage: verify_tool_installation <tool_name> [expected_version]
verify_tool_installation() {
  local tool_name="$1"
  local expected_version="${2:-}"
  
  if ! os_command_is_installed "$tool_name"; then
    log_error "$tool_name installation verification failed - command not found"
    return 1
  fi
  
  local installed_version
  case "$tool_name" in
    "jq"|"yq"|"hyperfine"|"just"|"gping")
      installed_version="$($tool_name --version 2>/dev/null | head -n1)"
      ;;
    "java")
      installed_version="$(java -version 2>&1 | head -n1)"
      ;;
    "node")
      installed_version="$(node --version 2>/dev/null)"
      ;;
    "python3")
      installed_version="$(python3 --version 2>/dev/null)"
      ;;
    *)
      installed_version="$($tool_name --version 2>/dev/null || $tool_name -v 2>/dev/null || echo "unknown")"
      ;;
  esac
  
  log_success "$tool_name installed successfully: $installed_version"
  
  if [[ -n "$expected_version" && "$installed_version" != *"$expected_version"* ]]; then
    log_warn "Version mismatch - expected: $expected_version, got: $installed_version"
  fi
  
  return 0
}

# =============================================================================
# ENVIRONMENT SETUP UTILITIES
# =============================================================================

# Add directory to PATH if not already present
# Usage: add_to_path <directory> [profile_file]
add_to_path() {
  local directory="$1"
  local profile_file="${2:-/etc/environment}"
  
  if [[ ":$PATH:" != *":$directory:"* ]]; then
    echo "export PATH=\"$directory:\$PATH\"" >> "$profile_file"
    export PATH="$directory:$PATH"
    log_success "Added to PATH: $directory"
  else
    log_info "Already in PATH: $directory"
  fi
}

# Set environment variable
# Usage: set_env_var <name> <value> [profile_file]
set_env_var() {
  local name="$1"
  local value="$2"
  local profile_file="${3:-/etc/environment}"
  
  echo "export $name=\"$value\"" >> "$profile_file"
  export "$name"="$value"
  log_success "Environment variable set: $name=$value"
}

# Export all functions for use in other scripts
export -f is_tool_installed
export -f create_tool_lock_file
export -f setup_tool_config
export -f get_github_arch
export -f get_github_os
export -f get_rust_target
export -f create_temp_dir
export -f download_file
export -f install_binary
export -f create_symlink
export -f try_package_install
export -f install_via_language_pm
export -f verify_tool_installation
export -f add_to_path
export -f set_env_var
