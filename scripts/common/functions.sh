#!/bin/bash

# =============================================================================
# Shared Functions for Oracle Linux Development Environment
# =============================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Check if gum is available for enhanced UI
GUM_AVAILABLE=false
if command -v gum >/dev/null 2>&1; then
    GUM_AVAILABLE=true
fi

# Logging functions with gum support
log_info() {
    local message="$1"
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum log --level info "$message"
    else
        echo -e "${BLUE}[INFO]${NC} $message"
    fi
}

log_success() {
    local message="$1"
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum log --level info "✅ $message"
    else
        echo -e "${GREEN}[SUCCESS]${NC} ✅ $message"
    fi
}

log_warning() {
    local message="$1"
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum log --level warn "$message"
    else
        echo -e "${YELLOW}[WARNING]${NC} ⚠️ $message"
    fi
}

log_error() {
    local message="$1"
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum log --level error "$message"
    else
        echo -e "${RED}[ERROR]${NC} ❌ $message"
    fi
}

log_debug() {
    local message="$1"
    if [[ "${DEBUG:-false}" == "true" ]]; then
        if [[ "$GUM_AVAILABLE" == "true" ]]; then
            gum log --level debug "$message"
        else
            echo -e "${PURPLE}[DEBUG]${NC} 🐛 $message"
        fi
    fi
}

# Progress indicator
show_progress() {
    local message="$1"
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum spin --spinner dot --title "$message" -- sleep 1
    else
        echo -e "${CYAN}⏳${NC} $message..."
    fi
}

# Confirmation prompt
confirm() {
    local message="$1"
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum confirm "$message"
    else
        echo -e "${YELLOW}❓${NC} $message (y/N)"
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# Input prompt
prompt_input() {
    local prompt="$1"
    local placeholder="${2:-}"
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        if [[ -n "$placeholder" ]]; then
            gum input --placeholder "$placeholder" --prompt "$prompt: "
        else
            gum input --prompt "$prompt: "
        fi
    else
        echo -e "${CYAN}❓${NC} $prompt: "
        read -r input
        echo "$input"
    fi
}

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

# Cleanup function for lock files
cleanup_on_exit() {
    local lock_file="${1:-}"
    if [[ -n "$lock_file" && -f "$lock_file" ]]; then
        remove_lock_file "$lock_file"
    fi
}

# Check if tool is already installed
is_tool_installed() {
    local tool_name="$1"
    local version_flag="${2:---version}"
    
    if command -v "$tool_name" >/dev/null 2>&1; then
        if [[ "$GUM_AVAILABLE" == "true" ]]; then
            local version
            version=$("$tool_name" "$version_flag" 2>/dev/null | head -1 || echo "unknown")
            gum log --level info "✅ $tool_name is already installed: $version"
        else
            log_success "$tool_name is already installed"
        fi
        return 0
    fi
    return 1
}

# Download with progress
download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-Downloading file}"
    
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        log_info "$description from $url"
        if ! curl -fsSL --progress-bar "$url" -o "$output"; then
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

# Extract archive with detection
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
        *.zip)
            unzip -q "$archive" -d "$destination"
            ;;
        *.tar)
            tar -xf "$archive" -C "$destination"
            ;;
        *)
            log_error "Unsupported archive format: $archive"
            return 1
            ;;
    esac
    
    log_success "Extracted: $(basename "$archive")"
}

# Check system architecture
get_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "x86_64" ;;
        aarch64) echo "arm64" ;;
        arm64) echo "arm64" ;;
        *) 
            log_error "Unsupported architecture: $arch"
            return 1
            ;;
    esac
}

# Check if running in container
is_container() {
    [[ -f /.dockerenv ]] || [[ -n "${container:-}" ]]
}

# Version comparison
version_ge() {
    local version1="$1"
    local version2="$2"
    printf '%s\n%s\n' "$version1" "$version2" | sort -V -C
}

# Export functions for use in other scripts
export -f log_info log_success log_warning log_error log_debug
export -f show_progress confirm prompt_input
export -f create_lock_file remove_lock_file cleanup_on_exit
export -f is_tool_installed download_file extract_archive
export -f get_arch is_container version_ge
