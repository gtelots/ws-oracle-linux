#!/usr/bin/env bash
# =============================================================================
# Gum CLI Tool Installer (Independent version)
# =============================================================================
# DESCRIPTION: Installs Gum - A tool for glamorous shell scripts
# URL: https://github.com/charmbracelet/gum
# VERSION: v0.16.2
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>

set -euo pipefail

# Load logging library if available, otherwise use simple functions
if [[ -f "/opt/laragis/lib/lib-log.sh" ]]; then
  source /opt/laragis/lib/lib-log.sh
else
  # Simple logging functions
  info() { echo "[INFO] $*"; }
  error() { echo "[ERROR] $*" >&2; }
  warn() { echo "[WARN] $*" >&2; }
fi

# Configuration
readonly FEATURE_NAME="gum"
readonly FEATURE_VERSION="0.16.2"
readonly LOCK_FILE="/opt/laragis/features/${FEATURE_NAME}.installed"
readonly BINARY_PATH="/opt/laragis/common/bin/gum"
readonly GITHUB_REPO="charmbracelet/gum"

# Detect architecture
detect_architecture() {
  local arch
  arch=$(uname -m)
  
  case "$arch" in
    x86_64|amd64)
      echo "x86_64"
      ;;
    aarch64|arm64)
      echo "arm64"
      ;;
    *)
      error "Unsupported architecture: $arch"
      return 1
      ;;
  esac
}

# Install gum
install_gum() {
  local architecture
  architecture=$(detect_architecture)
  
  info "Installing Gum v${FEATURE_VERSION} for ${architecture} architecture"
  
  local download_url="https://github.com/${GITHUB_REPO}/releases/download/v${FEATURE_VERSION}/gum_${FEATURE_VERSION}_Linux_${architecture}.tar.gz"
  local temp_dir="/tmp/gum-install-$$"
  local tar_file="${temp_dir}/gum.tar.gz"
  
  # Create temp directory
  mkdir -p "$temp_dir"
  trap "rm -rf '$temp_dir'" EXIT
  
  # Ensure target directory exists
  mkdir -p "$(dirname "$BINARY_PATH")"
  
  # Download archive
  info "Downloading from $download_url..."
  if ! curl -fsSL --connect-timeout 30 --max-time 300 -o "$tar_file" "$download_url"; then
    error "Failed to download gum"
    exit 1
  fi
  
  # Extract archive
  info "Extracting archive..."
  if ! tar -xzf "$tar_file" -C "$temp_dir"; then
    error "Failed to extract gum archive"
    exit 1
  fi
  
  # Find and copy the gum binary
  local gum_binary
  gum_binary=$(find "$temp_dir" -name "gum" -type f | head -n1)
  
  if [[ -z "$gum_binary" ]]; then
    error "Gum binary not found in downloaded archive"
    exit 1
  fi
  
  if ! cp "$gum_binary" "$BINARY_PATH"; then
    error "Failed to copy gum binary to $BINARY_PATH"
    exit 1
  fi
  
  # Make executable
  chmod +x "$BINARY_PATH"
  
  info "Gum binary installed to $BINARY_PATH"
}

# Create installation metadata
create_metadata() {
  mkdir -p "$(dirname "$LOCK_FILE")"
  
  cat > "$LOCK_FILE" << EOF
{
  "name": "$FEATURE_NAME",
  "version": "$FEATURE_VERSION",
  "install_method": "binary",
  "install_date": "$(date -Iseconds)",
  "github_repo": "$GITHUB_REPO",
  "binary_path": "$BINARY_PATH",
  "architecture": "$(detect_architecture)"
}
EOF
  
  info "Installation metadata saved to $LOCK_FILE"
}

# Main function
main() {
  info "Starting Gum v${FEATURE_VERSION} installation..."
  
  # Check if gum binary already exists
  if command -v gum &>/dev/null; then
    local existing_version
    existing_version=$(gum --version 2>&1 | grep -o '[0-9.]*' | head -n1 || echo "unknown")
    
    info "Found existing gum installation with version: $existing_version"
    
    if [[ "$existing_version" == "$FEATURE_VERSION" ]]; then
      info "Gum v${FEATURE_VERSION} is already available via system package"
      
      # Create metadata for existing installation
      mkdir -p "$(dirname "$LOCK_FILE")"
      cat > "$LOCK_FILE" << EOF
{
  "name": "$FEATURE_NAME",
  "version": "$FEATURE_VERSION",
  "install_method": "system-package",
  "install_date": "$(date -Iseconds)",
  "github_repo": "$GITHUB_REPO",
  "binary_path": "$(command -v gum)",
  "architecture": "$(detect_architecture)"
}
EOF
      
      info "Installation metadata saved to $LOCK_FILE"
      info "Gum v${FEATURE_VERSION} installation completed successfully!"
      exit 0
    else
      warn "Different version of gum found ($existing_version), proceeding with installation of v${FEATURE_VERSION}"
    fi
  fi
  
  # Check if already installed via our lock system
  if [[ -f "$LOCK_FILE" ]]; then
    local installed_version
    installed_version=$(grep '"version"' "$LOCK_FILE" | cut -d'"' -f4 2>/dev/null || echo "")
    if [[ "$installed_version" == "$FEATURE_VERSION" ]]; then
      info "Gum v${FEATURE_VERSION} is already installed"
      exit 0
    fi
  fi
  
  # Install gum
  install_gum
  
  # Verify installation
  if [[ ! -x "$BINARY_PATH" ]]; then
    error "Gum installation verification failed"
    exit 1
  fi
  
  # Create metadata
  create_metadata
  
  info "Gum v${FEATURE_VERSION} installation completed successfully!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
