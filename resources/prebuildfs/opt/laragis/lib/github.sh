#!/usr/bin/env bash
# =============================================================================
# GitHub Releases Utilities Library
# =============================================================================
# DESCRIPTION: Common patterns for downloading and installing from GitHub releases
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load dependencies
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/install.sh
. /opt/laragis/lib/validation.sh

# =============================================================================
# GITHUB RELEASE UTILITIES
# =============================================================================

# Get latest release version from GitHub API
# Usage: get_latest_github_version <owner/repo>
get_latest_github_version() {
  local repo="$1"
  
  local api_url="https://api.github.com/repos/${repo}/releases/latest"
  local version
  
  if ! validate_url "$api_url"; then
    return 1
  fi
  
  version="$(curl -s "$api_url" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/' | sed 's/^v//')"
  
  if [[ -n "$version" ]]; then
    echo "$version"
    return 0
  else
    log_error "Failed to get latest version for $repo"
    return 1
  fi
}

# Build GitHub release download URL
# Usage: build_github_download_url <owner/repo> <version> <filename>
build_github_download_url() {
  local repo="$1"
  local version="$2"
  local filename="$3"
  
  # Add 'v' prefix if not present
  [[ "$version" != v* ]] && version="v${version}"
  
  echo "https://github.com/${repo}/releases/download/${version}/${filename}"
}

# Generate common GitHub release filename patterns
# Usage: generate_github_filename <tool_name> <version> <pattern> [arch] [os]
generate_github_filename() {
  local tool_name="$1"
  local version="$2"
  local pattern="$3"
  local arch="${4:-$(get_github_arch)}"
  local os="${5:-$(get_github_os)}"
  
  case "$pattern" in
    "standard")
      echo "${tool_name}-${version}-${os}-${arch}.tar.gz"
      ;;
    "rust")
      local rust_target="$(get_rust_target)"
      echo "${tool_name}-v${version}-${rust_target}.tar.gz"
      ;;
    "go")
      echo "${tool_name}_${version}_${os}_${arch}.tar.gz"
      ;;
    "simple")
      echo "${tool_name}-${os}-${arch}"
      ;;
    "versioned")
      echo "${tool_name}_v${version}_${os}_${arch}.tar.gz"
      ;;
    *)
      log_error "Unknown filename pattern: $pattern"
      return 1
      ;;
  esac
}

# =============================================================================
# GITHUB INSTALLATION PATTERNS
# =============================================================================

# Install tool from GitHub releases (binary)
# Usage: install_from_github_binary <owner/repo> <tool_name> <version> <pattern> [binary_path_in_archive]
install_from_github_binary() {
  local repo="$1"
  local tool_name="$2"
  local version="$3"
  local pattern="$4"
  local binary_path="${5:-$tool_name}"
  
  log_info "Installing $tool_name v$version from GitHub releases..."
  
  # Validate prerequisites
  if ! validate_installation_prerequisites "$tool_name" 50 "curl" "tar"; then
    return 1
  fi
  
  local temp_dir="$(create_temp_dir)"
  local filename="$(generate_github_filename "$tool_name" "$version" "$pattern")"
  local download_url="$(build_github_download_url "$repo" "$version" "$filename")"
  local archive_path="${temp_dir}/${filename}"
  
  # Download the release
  if ! download_file "$download_url" "$archive_path"; then
    return 1
  fi
  
  # Extract the archive
  cd "$temp_dir"
  case "$filename" in
    *.tar.gz|*.tgz)
      tar -xzf "$filename"
      ;;
    *.tar.bz2)
      tar -xjf "$filename"
      ;;
    *.zip)
      unzip -q "$filename"
      ;;
    *)
      # Assume it's a direct binary
      chmod +x "$filename"
      binary_path="$filename"
      ;;
  esac
  
  # Find and install the binary
  local binary_source
  if [[ -f "$binary_path" ]]; then
    binary_source="$binary_path"
  elif [[ -f "${tool_name}-v${version}-$(get_rust_target)/${tool_name}" ]]; then
    binary_source="${tool_name}-v${version}-$(get_rust_target)/${tool_name}"
  elif [[ -f "${tool_name}/${tool_name}" ]]; then
    binary_source="${tool_name}/${tool_name}"
  else
    # Try to find the binary
    binary_source="$(find . -name "$tool_name" -type f -executable | head -n1)"
    if [[ -z "$binary_source" ]]; then
      log_error "Could not find binary '$tool_name' in downloaded archive"
      return 1
    fi
  fi
  
  # Install the binary
  if ! install_binary "$binary_source" "/usr/local/bin/$tool_name"; then
    return 1
  fi
  
  # Verify installation
  if ! verify_tool_installation "$tool_name" "$version"; then
    return 1
  fi
  
  return 0
}

# Install tool from GitHub releases (archive with multiple files)
# Usage: install_from_github_archive <owner/repo> <tool_name> <version> <pattern> <install_script>
install_from_github_archive() {
  local repo="$1"
  local tool_name="$2"
  local version="$3"
  local pattern="$4"
  local install_script="$5"
  
  log_info "Installing $tool_name v$version from GitHub archive..."
  
  # Validate prerequisites
  if ! validate_installation_prerequisites "$tool_name" 100 "curl" "tar"; then
    return 1
  fi
  
  local temp_dir="$(create_temp_dir)"
  local filename="$(generate_github_filename "$tool_name" "$version" "$pattern")"
  local download_url="$(build_github_download_url "$repo" "$version" "$filename")"
  local archive_path="${temp_dir}/${filename}"
  
  # Download the release
  if ! download_file "$download_url" "$archive_path"; then
    return 1
  fi
  
  # Extract the archive
  cd "$temp_dir"
  case "$filename" in
    *.tar.gz|*.tgz)
      tar -xzf "$filename"
      ;;
    *.tar.bz2)
      tar -xjf "$filename"
      ;;
    *.zip)
      unzip -q "$filename"
      ;;
    *)
      log_error "Unsupported archive format: $filename"
      return 1
      ;;
  esac
  
  # Run the install script
  if [[ -f "$install_script" ]]; then
    chmod +x "$install_script"
    if ! ./"$install_script"; then
      log_error "Installation script failed: $install_script"
      return 1
    fi
  else
    log_error "Installation script not found: $install_script"
    return 1
  fi
  
  # Verify installation
  if ! verify_tool_installation "$tool_name" "$version"; then
    return 1
  fi
  
  return 0
}

# =============================================================================
# SPECIALIZED GITHUB PATTERNS
# =============================================================================

# Install Rust-based tool from GitHub (common pattern)
# Usage: install_rust_tool_from_github <owner/repo> <tool_name> <version>
install_rust_tool_from_github() {
  local repo="$1"
  local tool_name="$2"
  local version="$3"
  
  # Try cargo first if available
  if install_via_language_pm "cargo" "$tool_name" "$version"; then
    return 0
  fi
  
  # Fallback to GitHub binary installation
  install_from_github_binary "$repo" "$tool_name" "$version" "rust"
}

# Install Go-based tool from GitHub (common pattern)
# Usage: install_go_tool_from_github <owner/repo> <tool_name> <version>
install_go_tool_from_github() {
  local repo="$1"
  local tool_name="$2"
  local version="$3"
  
  install_from_github_binary "$repo" "$tool_name" "$version" "go"
}

# Install Node.js-based tool from GitHub (common pattern)
# Usage: install_node_tool_from_github <owner/repo> <tool_name> <version>
install_node_tool_from_github() {
  local repo="$1"
  local tool_name="$2"
  local version="$3"
  
  # Try npm first if available
  if install_via_language_pm "npm" "$tool_name" "$version"; then
    return 0
  fi
  
  # Fallback to GitHub binary installation
  install_from_github_binary "$repo" "$tool_name" "$version" "standard"
}

# =============================================================================
# GITHUB RELEASE INFORMATION
# =============================================================================

# Get release information from GitHub API
# Usage: get_github_release_info <owner/repo> <version>
get_github_release_info() {
  local repo="$1"
  local version="$2"
  
  # Add 'v' prefix if not present
  [[ "$version" != v* ]] && version="v${version}"
  
  local api_url="https://api.github.com/repos/${repo}/releases/tags/${version}"
  
  if ! validate_url "$api_url"; then
    return 1
  fi
  
  curl -s "$api_url"
}

# Check if GitHub release exists
# Usage: github_release_exists <owner/repo> <version>
github_release_exists() {
  local repo="$1"
  local version="$2"
  
  local release_info="$(get_github_release_info "$repo" "$version")"
  
  if echo "$release_info" | grep -q '"tag_name"'; then
    return 0
  else
    return 1
  fi
}

# List available assets for a GitHub release
# Usage: list_github_release_assets <owner/repo> <version>
list_github_release_assets() {
  local repo="$1"
  local version="$2"
  
  local release_info="$(get_github_release_info "$repo" "$version")"
  
  echo "$release_info" | grep '"name":' | sed -E 's/.*"name": "([^"]+)".*/\1/'
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Generic GitHub tool installer with fallback strategies
# Usage: install_github_tool <owner/repo> <tool_name> <version> [strategies...]
install_github_tool() {
  local repo="$1"
  local tool_name="$2"
  local version="$3"
  shift 3
  local strategies=("$@")
  
  # Default strategies if none provided
  if [[ ${#strategies[@]} -eq 0 ]]; then
    strategies=("package" "cargo" "npm" "binary")
  fi
  
  for strategy in "${strategies[@]}"; do
    log_info "Trying installation strategy: $strategy"
    
    case "$strategy" in
      "package")
        if try_package_install "$tool_name"; then
          return 0
        fi
        ;;
      "cargo")
        if install_via_language_pm "cargo" "$tool_name" "$version"; then
          return 0
        fi
        ;;
      "npm")
        if install_via_language_pm "npm" "$tool_name" "$version"; then
          return 0
        fi
        ;;
      "binary")
        if install_from_github_binary "$repo" "$tool_name" "$version" "rust"; then
          return 0
        fi
        ;;
      "go-binary")
        if install_from_github_binary "$repo" "$tool_name" "$version" "go"; then
          return 0
        fi
        ;;
    esac
  done
  
  log_error "All installation strategies failed for $tool_name"
  return 1
}

# Export all functions for use in other scripts
export -f get_latest_github_version
export -f build_github_download_url
export -f generate_github_filename
export -f install_from_github_binary
export -f install_from_github_archive
export -f install_rust_tool_from_github
export -f install_go_tool_from_github
export -f install_node_tool_from_github
export -f get_github_release_info
export -f github_release_exists
export -f list_github_release_assets
export -f install_github_tool
