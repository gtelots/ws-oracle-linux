#!/usr/bin/env bash
# =============================================================================
# Validation Utilities Library
# =============================================================================
# DESCRIPTION: Common validation patterns and utilities
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load dependencies
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# =============================================================================
# VERSION VALIDATION
# =============================================================================

# Validate semantic version format
# Usage: validate_semver <version>
validate_semver() {
  local version="$1"
  
  if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$ ]]; then
    return 0
  else
    log_error "Invalid semantic version format: $version"
    return 1
  fi
}

# Validate version string (more flexible than semver)
# Usage: validate_version <version>
validate_version() {
  local version="$1"
  
  if [[ "$version" =~ ^[0-9]+(\.[0-9]+)*(-[a-zA-Z0-9.-]+)?$ ]]; then
    return 0
  else
    log_error "Invalid version format: $version"
    return 1
  fi
}

# Compare versions (returns 0 if v1 >= v2, 1 otherwise)
# Usage: version_gte <version1> <version2>
version_gte() {
  local v1="$1"
  local v2="$2"
  
  # Simple string comparison for now - could be enhanced with proper version parsing
  if [[ "$(printf '%s\n' "$v1" "$v2" | sort -V | head -n1)" == "$v2" ]]; then
    return 0
  else
    return 1
  fi
}

# =============================================================================
# URL VALIDATION
# =============================================================================

# Validate URL format
# Usage: validate_url <url>
validate_url() {
  local url="$1"
  
  if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$ ]]; then
    return 0
  else
    log_error "Invalid URL format: $url"
    return 1
  fi
}

# Check if URL is accessible
# Usage: check_url_accessible <url> [timeout]
check_url_accessible() {
  local url="$1"
  local timeout="${2:-10}"
  
  if curl --connect-timeout "$timeout" --max-time "$timeout" -s --head "$url" >/dev/null 2>&1; then
    return 0
  else
    log_error "URL not accessible: $url"
    return 1
  fi
}

# =============================================================================
# FILE AND DIRECTORY VALIDATION
# =============================================================================

# Validate file exists and is readable
# Usage: validate_file_readable <file_path>
validate_file_readable() {
  local file_path="$1"
  
  if [[ -f "$file_path" && -r "$file_path" ]]; then
    return 0
  else
    log_error "File not found or not readable: $file_path"
    return 1
  fi
}

# Validate directory exists and is writable
# Usage: validate_dir_writable <dir_path>
validate_dir_writable() {
  local dir_path="$1"
  
  if [[ -d "$dir_path" && -w "$dir_path" ]]; then
    return 0
  else
    log_error "Directory not found or not writable: $dir_path"
    return 1
  fi
}

# Validate file has expected permissions
# Usage: validate_file_permissions <file_path> <expected_permissions>
validate_file_permissions() {
  local file_path="$1"
  local expected_permissions="$2"
  
  if [[ ! -f "$file_path" ]]; then
    log_error "File not found: $file_path"
    return 1
  fi
  
  local actual_permissions="$(stat -c '%a' "$file_path" 2>/dev/null)"
  
  if [[ "$actual_permissions" == "$expected_permissions" ]]; then
    return 0
  else
    log_error "File permissions mismatch: expected $expected_permissions, got $actual_permissions for $file_path"
    return 1
  fi
}

# =============================================================================
# SYSTEM VALIDATION
# =============================================================================

# Validate system has minimum free disk space
# Usage: validate_disk_space <path> <min_space_mb>
validate_disk_space() {
  local path="$1"
  local min_space_mb="$2"
  
  local available_mb="$(df -m "$path" | tail -1 | awk '{print $4}')"
  
  if [[ "$available_mb" -ge "$min_space_mb" ]]; then
    return 0
  else
    log_error "Insufficient disk space: ${available_mb}MB available, ${min_space_mb}MB required"
    return 1
  fi
}

# Validate system has minimum free memory
# Usage: validate_memory <min_memory_mb>
validate_memory() {
  local min_memory_mb="$1"
  
  local available_mb="$(free -m | grep '^Mem:' | awk '{print $7}')"
  
  if [[ "$available_mb" -ge "$min_memory_mb" ]]; then
    return 0
  else
    log_error "Insufficient memory: ${available_mb}MB available, ${min_memory_mb}MB required"
    return 1
  fi
}

# Validate user has required permissions
# Usage: validate_user_permissions <required_user>
validate_user_permissions() {
  local required_user="$1"
  local current_user="$(whoami)"
  
  if [[ "$current_user" == "$required_user" ]] || [[ "$current_user" == "root" ]]; then
    return 0
  else
    log_error "Insufficient permissions: running as $current_user, required: $required_user or root"
    return 1
  fi
}

# =============================================================================
# NETWORK VALIDATION
# =============================================================================

# Validate network connectivity
# Usage: validate_network_connectivity [test_host]
validate_network_connectivity() {
  local test_host="${1:-8.8.8.8}"
  
  if ping -c 1 -W 5 "$test_host" >/dev/null 2>&1; then
    return 0
  else
    log_error "Network connectivity test failed (host: $test_host)"
    return 1
  fi
}

# Validate DNS resolution
# Usage: validate_dns_resolution [test_domain]
validate_dns_resolution() {
  local test_domain="${1:-google.com}"
  
  if nslookup "$test_domain" >/dev/null 2>&1; then
    return 0
  else
    log_error "DNS resolution test failed (domain: $test_domain)"
    return 1
  fi
}

# =============================================================================
# DEPENDENCY VALIDATION
# =============================================================================

# Validate required commands are available
# Usage: validate_required_commands <command1> [command2] [...]
validate_required_commands() {
  local missing_commands=()
  
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_commands+=("$cmd")
    fi
  done
  
  if [[ ${#missing_commands[@]} -eq 0 ]]; then
    return 0
  else
    log_error "Missing required commands: ${missing_commands[*]}"
    return 1
  fi
}

# Validate environment variables are set
# Usage: validate_env_vars <var1> [var2] [...]
validate_env_vars() {
  local missing_vars=()
  
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      missing_vars+=("$var")
    fi
  done
  
  if [[ ${#missing_vars[@]} -eq 0 ]]; then
    return 0
  else
    log_error "Missing required environment variables: ${missing_vars[*]}"
    return 1
  fi
}

# =============================================================================
# ARCHITECTURE AND OS VALIDATION
# =============================================================================

# Validate supported architecture
# Usage: validate_architecture <arch1> [arch2] [...]
validate_architecture() {
  local supported_archs=("$@")
  local current_arch="$(uname -m)"
  
  for arch in "${supported_archs[@]}"; do
    if [[ "$current_arch" == "$arch" ]]; then
      return 0
    fi
  done
  
  log_error "Unsupported architecture: $current_arch (supported: ${supported_archs[*]})"
  return 1
}

# Validate supported operating system
# Usage: validate_os <os1> [os2] [...]
validate_os() {
  local supported_oses=("$@")
  local current_os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  
  for os in "${supported_oses[@]}"; do
    if [[ "$current_os" == "$os" ]]; then
      return 0
    fi
  done
  
  log_error "Unsupported operating system: $current_os (supported: ${supported_oses[*]})"
  return 1
}

# =============================================================================
# COMPREHENSIVE VALIDATION
# =============================================================================

# Run pre-installation validation checks
# Usage: validate_installation_prerequisites <tool_name> [min_disk_mb] [required_commands...]
validate_installation_prerequisites() {
  local tool_name="$1"
  local min_disk_mb="${2:-100}"
  shift 2
  local required_commands=("$@")
  
  log_info "Running pre-installation validation for $tool_name..."
  
  local validation_failed=false
  
  # Check disk space
  if ! validate_disk_space "/" "$min_disk_mb"; then
    validation_failed=true
  fi
  
  # Check network connectivity
  if ! validate_network_connectivity; then
    validation_failed=true
  fi
  
  # Check required commands
  if [[ ${#required_commands[@]} -gt 0 ]]; then
    if ! validate_required_commands "${required_commands[@]}"; then
      validation_failed=true
    fi
  fi
  
  # Check architecture support (common architectures)
  if ! validate_architecture "x86_64" "aarch64"; then
    validation_failed=true
  fi
  
  if [[ "$validation_failed" == "true" ]]; then
    log_error "Pre-installation validation failed for $tool_name"
    return 1
  else
    log_success "Pre-installation validation passed for $tool_name"
    return 0
  fi
}

# Export all functions for use in other scripts
export -f validate_semver
export -f validate_version
export -f version_gte
export -f validate_url
export -f check_url_accessible
export -f validate_file_readable
export -f validate_dir_writable
export -f validate_file_permissions
export -f validate_disk_space
export -f validate_memory
export -f validate_user_permissions
export -f validate_network_connectivity
export -f validate_dns_resolution
export -f validate_required_commands
export -f validate_env_vars
export -f validate_architecture
export -f validate_os
export -f validate_installation_prerequisites
