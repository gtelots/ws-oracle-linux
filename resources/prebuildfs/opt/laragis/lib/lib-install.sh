#!/usr/bin/env bash
# =============================================================================
# Installation Utilities Library
# =============================================================================
# DESCRIPTION: Common installation functions for features
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# VERSION: 1.0.0

# Load dependencies
source /opt/laragis/lib/lib-log.sh
source /opt/laragis/lib/lib-metadata.sh

# Detect system architecture
# Usage: install_detect_architecture
install_detect_architecture() {
  local arch
  arch=$(uname -m)
  
  case "$arch" in
    x86_64|amd64)
      echo "x86_64"
      ;;
    aarch64|arm64)
      echo "arm64"
      ;;
    armv7l|armv6l)
      echo "armv7"
      ;;
    i386|i686)
      echo "i386"
      ;;
    *)
      error "Unsupported architecture: $arch"
      return 1
      ;;
  esac
}

# Download file with retry logic
# Usage: install_download "url" "output_file" [max_retries]
install_download() {
  local url="$1"
  local output_file="$2"
  local max_retries="${3:-3}"
  
  local retry_count=0
  
  while [[ $retry_count -lt $max_retries ]]; do
    info "Downloading from $url (attempt $((retry_count + 1))/$max_retries)..."
    
    if curl -fsSL --connect-timeout 30 --max-time 300 -o "$output_file" "$url"; then
      info "Download completed successfully"
      return 0
    else
      retry_count=$((retry_count + 1))
      if [[ $retry_count -lt $max_retries ]]; then
        warn "Download failed, retrying in 2 seconds..."
        sleep 2
      else
        error "Failed to download after $max_retries attempts"
        return 1
      fi
    fi
  done
}

# Get latest GitHub release version
# Usage: install_get_github_version "owner/repo"
install_get_github_version() {
  local repo="$1"
  local api_url="https://api.github.com/repos/${repo}/releases/latest"
  local version
  
  # Try to get latest version with retry logic
  local retry_count=0
  local max_retries=3
  
  while [[ $retry_count -lt $max_retries ]]; do
    info "Fetching latest version from GitHub API (attempt $((retry_count + 1))/$max_retries)..."
    
    if version=$(curl -fsSL --connect-timeout 30 --max-time 60 "$api_url" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4 | sed 's/^v//'); then
      if [[ -n "$version" ]]; then
        echo "$version"
        return 0
      fi
    fi
    
    retry_count=$((retry_count + 1))
    if [[ $retry_count -lt $max_retries ]]; then
      warn "Failed to get version, retrying in 2 seconds..."
      sleep 2
    fi
  done
  
  # No version found
  error "Could not fetch latest version for $repo"
  return 1
}

# Check if feature is already installed with version check
# Usage: install_check_existing "feature_name" "required_version"
install_check_existing() {
  local feature_name="$1"
  local required_version="$2"
  
  if metadata_is_installed "$feature_name"; then
    local installed_version
    installed_version=$(metadata_get_version "$feature_name")
    info "$feature_name v${installed_version} is already installed"
    
    if [[ "$installed_version" == "$required_version" ]]; then
      info "Required version v${required_version} is already installed"
      return 0
    else
      warn "Installed version ($installed_version) differs from required version ($required_version)"
      info "Proceeding with installation of v${required_version}"
      return 1
    fi
  fi
  
  return 1
}

# Verify binary installation
# Usage: install_verify_binary "binary_path" "feature_name"
install_verify_binary() {
  local binary_path="$1"
  local feature_name="$2"
  
  if [[ ! -f "$binary_path" ]]; then
    error "$feature_name binary not found at $binary_path"
    return 1
  fi
  
  if [[ ! -x "$binary_path" ]]; then
    error "$feature_name binary is not executable"
    return 1
  fi
  
  # Try to run version command if possible
  local version_output
  if version_output=$("$binary_path" --version 2>&1 || "$binary_path" version 2>&1 || "$binary_path" -v 2>&1); then
    info "$feature_name installation verified: $version_output"
  else
    info "$feature_name binary is executable"
  fi
  
  return 0
}

# Extract tar.gz archive
# Usage: install_extract_tar "archive_file" "destination_dir"
install_extract_tar() {
  local archive_file="$1"
  local destination_dir="$2"
  
  info "Extracting archive to $destination_dir..."
  
  if ! tar -xzf "$archive_file" -C "$destination_dir"; then
    error "Failed to extract archive $archive_file"
    return 1
  fi
  
  info "Archive extracted successfully"
  return 0
}

# Create installation metadata and save to lock file
# Usage: install_save_metadata "feature_name" "version" "install_method" "lock_file" [checksum] [additional_data]
install_save_metadata() {
  local feature_name="$1"
  local version="$2"
  local install_method="$3"
  local lock_file="$4"
  local checksum="${5:-unknown}"
  local additional_data="${6:-{}}"
  
  # Ensure lock directory exists
  mkdir -p "$(dirname "$lock_file")"
  
  # Create metadata and save to lock file
  if ! metadata_create "$feature_name" "$version" "$install_method" "$checksum" "$additional_data" > "$lock_file"; then
    error "Failed to create installation metadata"
    return 1
  fi
  
  info "Installation metadata saved to $lock_file"
  return 0
}

# Create temporary directory with cleanup
# Usage: install_create_temp_dir
install_create_temp_dir() {
  local temp_dir
  temp_dir="/tmp/install-$$-$(date +%s)"
  
  # Create directory
  mkdir -p "$temp_dir"
  
  # Set up cleanup trap
  trap "rm -rf '$temp_dir'" EXIT
  
  echo "$temp_dir"
}

# Ensure directory exists and is writable
# Usage: install_ensure_dir "directory_path"
install_ensure_dir() {
  local dir_path="$1"
  
  if ! mkdir -p "$dir_path"; then
    error "Failed to create directory: $dir_path"
    return 1
  fi
  
  if [[ ! -w "$dir_path" ]]; then
    error "Directory is not writable: $dir_path"
    return 1
  fi
  
  return 0
}
