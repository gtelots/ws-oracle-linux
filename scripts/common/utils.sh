#!/bin/bash
# =============================================================================
# Utility Functions - Core utility functions for scripts
# =============================================================================

set -euo pipefail

# Ensure logging is available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

# Lock file management
create_lock_file() {
    local lock_file="$1"
    local process_name="$2"
    
    if [[ -f "$lock_file" ]]; then
        local pid
        pid=$(cat "$lock_file" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            log_error "$process_name is already running (PID: $pid)"
            return 1
        else
            log_warning "Removing stale lock file: $lock_file"
            rm -f "$lock_file"
        fi
    fi
    
    echo $$ > "$lock_file"
    log_debug "Created lock file: $lock_file (PID: $$)"
}

remove_lock_file() {
    local lock_file="$1"
    if [[ -f "$lock_file" ]]; then
        rm -f "$lock_file"
        log_debug "Removed lock file: $lock_file"
    fi
}

cleanup_on_exit() {
    local lock_file="${1:-}"
    if [[ -n "$lock_file" && -f "$lock_file" ]]; then
        remove_lock_file "$lock_file"
    fi
}

# Tool installation checks
is_tool_installed() {
    local tool_name="$1"
    local version_flag="${2:---version}"
    
    if command -v "$tool_name" >/dev/null 2>&1; then
        local version
        version=$("$tool_name" "$version_flag" 2>/dev/null | head -1 || echo "unknown")
        log_install_skip "$tool_name" "already installed: $version"
        return 0
    fi
    return 1
}

# Download utilities
download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-Downloading file}"
    
    if command -v gum >/dev/null 2>&1; then
        log_info "$description from $url"
        if ! curl -fsSL "$url" -o "$output"; then
            log_error "Failed to download: $url"
            return 1
        fi
    else
        log_info "$description..."
        if ! curl -fsSL "$url" -o "$output"; then
            log_error "Failed to download: $url"
            return 1
        fi
    fi
    
    log_success "Downloaded: $(basename "$output")"
}

# Archive extraction
extract_archive() {
    local archive="$1"
    local destination="${2:-.}"
    local description="${3:-Extracting archive}"
    
    log_info "$description: $(basename "$archive")"
    
    case "$archive" in
        *.tar.gz|*.tgz)
            tar -xzf "$archive" -C "$destination"
            ;;
        *.tar.bz2|*.tbz2)
            tar -xjf "$archive" -C "$destination"
            ;;
        *.tar.xz|*.txz)
            tar -xJf "$archive" -C "$destination"
            ;;
        *.tar)
            tar -xf "$archive" -C "$destination"
            ;;
        *.zip)
            unzip -q "$archive" -d "$destination"
            ;;
        *.gz)
            gunzip -c "$archive" > "$destination/$(basename "$archive" .gz)"
            ;;
        *)
            log_error "Unsupported archive format: $archive"
            return 1
            ;;
    esac
    
    log_success "Extracted: $(basename "$archive")"
}

# Architecture detection
get_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l|armhf) echo "arm" ;;
        i386|i686) echo "386" ;;
        *)
            log_error "Unsupported architecture: $arch"
            return 1
            ;;
    esac
}

# Container detection
is_container() {
    [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]] || grep -q 'container=\|docker=\|lxc=' /proc/1/environ 2>/dev/null
}

# Version comparison
version_ge() {
    local version1="$1"
    local version2="$2"
    printf '%s\n%s\n' "$version1" "$version2" | sort -V -C
}

# Retry mechanism
retry() {
    local max_attempts="$1"
    local delay="$2"
    shift 2
    local command=("$@")
    
    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        log_debug "Attempt $attempt/$max_attempts: ${command[*]}"
        
        if "${command[@]}"; then
            log_debug "Command succeeded on attempt $attempt"
            return 0
        else
            local exit_code=$?
            if [[ $attempt -eq $max_attempts ]]; then
                log_error "Command failed after $max_attempts attempts: ${command[*]}"
                return $exit_code
            fi
            
            log_warning "Attempt $attempt failed, retrying in ${delay}s..."
            sleep "$delay"
            ((attempt++))
        fi
    done
}

# Timeout wrapper
timeout_run() {
    local timeout_duration="$1"
    shift
    local command=("$@")
    
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout_duration" "${command[@]}"
    else
        # Fallback for systems without timeout command
        "${command[@]}"
    fi
}

# Check if URL is reachable
check_url() {
    local url="$1"
    local timeout="${2:-10}"
    
    if curl -fsSL --max-time "$timeout" --head "$url" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Generate random string
generate_random_string() {
    local length="${1:-16}"
    local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 32 | tr -d "=+/" | cut -c1-"$length"
    else
        # Fallback method
        for i in $(seq 1 "$length"); do
            echo -n "${chars:RANDOM % ${#chars}:1}"
        done
        echo
    fi
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Export utility functions
export -f create_lock_file remove_lock_file cleanup_on_exit
export -f is_tool_installed download_file extract_archive
export -f get_arch is_container version_ge
export -f retry timeout_run check_url generate_random_string
export -f is_root command_exists
