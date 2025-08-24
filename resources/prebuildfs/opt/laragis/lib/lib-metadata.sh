#!/usr/bin/env bash
# =============================================================================
# Metadata Library for Lock Files
# =============================================================================
# DESCRIPTION: Provides functions for creating and managing installation metadata
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# VERSION: 1.0.0

# Create lock file metadata for a feature
# Usage: metadata_create "feature_name" "version" "install_method" [checksum] [additional_data]
metadata_create() {
  local feature_name="$1"
  local version="$2"
  local install_method="$3"
  local checksum="${4:-unknown}"
  local additional_data="${5:-{}}"
  
  if [[ -z "$feature_name" || -z "$version" || -z "$install_method" ]]; then
    echo "Error: metadata_create requires feature_name, version, and install_method" >&2
    return 1
  fi
  
  local installed_at="$(date -Iseconds)"
  local installed_by="$(whoami)"
  local architecture="$(uname -m)"
  local os_id="$(cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d= -f2 | tr -d '"' || echo unknown)"
  local kernel="$(uname -r)"
  local platform="$(uname -s)"
  
  # Create base metadata
  cat << EOF
{
  "feature": "${feature_name}",
  "version": "${version}",
  "architecture": "${architecture}",
  "installed_at": "${installed_at}",
  "installed_by": "${installed_by}",
  "checksum": "${checksum}",
  "install_method": "${install_method}",
  "system": {
    "os": "${os_id}",
    "kernel": "${kernel}",
    "platform": "${platform}"
  },
  "additional": ${additional_data}
}
EOF
}

# Create metadata for binary installation
# Usage: metadata_create_binary "feature_name" "version" "binary_path" [additional_data]
metadata_create_binary() {
  local feature_name="$1"
  local version="$2"
  local binary_path="$3"
  local additional_data="${4:-{}}"
  
  local checksum="unknown"
  if [[ -f "$binary_path" ]]; then
    checksum="$(sha256sum "$binary_path" 2>/dev/null | cut -d' ' -f1 || echo unknown)"
  fi
  
  metadata_create "$feature_name" "$version" "binary-download" "$checksum" "$additional_data"
}

# Create metadata for package manager installation
# Usage: metadata_create_package "feature_name" "version" [additional_data]
metadata_create_package() {
  local feature_name="$1"
  local version="$2"
  local additional_data="${3:-{}}"
  
  metadata_create "$feature_name" "$version" "package-manager" "unknown" "$additional_data"
}

# Create metadata for source installation
# Usage: metadata_create_source "feature_name" "version" "source_path" [additional_data]
metadata_create_source() {
  local feature_name="$1"
  local version="$2"
  local source_path="$3"
  local additional_data="${4:-{}}"
  
  local checksum="unknown"
  if [[ -f "$source_path" ]]; then
    checksum="$(sha256sum "$source_path" 2>/dev/null | cut -d' ' -f1 || echo unknown)"
  fi
  
  metadata_create "$feature_name" "$version" "source-compile" "$checksum" "$additional_data"
}

# Validate lock file metadata
# Usage: metadata_validate "lock_file_path" "expected_feature"
metadata_validate() {
  local lock_file="$1"
  local expected_feature="$2"
  
  if [[ ! -f "$lock_file" ]]; then
    return 1
  fi
  
  # Check if file contains valid JSON
  if ! jq empty "$lock_file" >/dev/null 2>&1; then
    return 1
  fi
  
  # Check if feature matches expected
  if [[ -n "$expected_feature" ]]; then
    local actual_feature
    actual_feature="$(jq -r '.feature // empty' "$lock_file" 2>/dev/null)"
    if [[ "$actual_feature" != "$expected_feature" ]]; then
      return 1
    fi
  fi
  
  # Check required fields
  local required_fields=("feature" "version" "installed_at" "install_method")
  for field in "${required_fields[@]}"; do
    if ! jq -e ".$field" "$lock_file" >/dev/null 2>&1; then
      return 1
    fi
  done
  
  return 0
}

# Get metadata field value
# Usage: metadata_get_field "lock_file_path" "field_path"
metadata_get_field() {
  local lock_file="$1"
  local field_path="$2"
  
  if [[ ! -f "$lock_file" ]]; then
    echo "unknown"
    return 1
  fi
  
  jq -r "${field_path} // \"unknown\"" "$lock_file" 2>/dev/null || echo "unknown"
}

# Check if feature is installed via lock file
# Usage: metadata_is_installed "feature_name"
metadata_is_installed() {
  local feature_name="$1"
  local lock_file="/opt/laragis/features/${feature_name}.installed"
  
  metadata_validate "$lock_file" "$feature_name"
}

# Get installed version of a feature
# Usage: metadata_get_version "feature_name"
metadata_get_version() {
  local feature_name="$1"
  local lock_file="/opt/laragis/features/${feature_name}.installed"
  
  metadata_get_field "$lock_file" ".version"
}
