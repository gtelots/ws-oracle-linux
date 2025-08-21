#!/bin/bash
# =============================================================================
# System Functions - Reusable system operations
# =============================================================================

# Validate environment variables
validate_env_vars() {
    local required_vars=("$@")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        return 1
    fi
    
    log_success "All required environment variables are set"
    return 0
}

# Validate numeric values
validate_numeric() {
    local var_name="$1"
    local var_value="$2"
    
    if ! [[ "$var_value" =~ ^[0-9]+$ ]]; then
        log_error "$var_name must be numeric, got: $var_value"
        return 1
    fi
    
    return 0
}

# Check if running in container
is_running_in_container() {
    if [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]] || grep -q 'container=\|docker=\|lxc=' /proc/1/environ 2>/dev/null; then
        return 0
    fi
    return 1
}

# Get system information
get_system_info() {
    local info_type="$1"
    
    case "$info_type" in
        "os")
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                echo "$ID $VERSION_ID"
            else
                echo "unknown"
            fi
            ;;
        "arch")
            uname -m
            ;;
        "kernel")
            uname -r
            ;;
        "hostname")
            hostname
            ;;
        "uptime")
            uptime -p 2>/dev/null || uptime
            ;;
        *)
            log_error "Unknown system info type: $info_type"
            return 1
            ;;
    esac
}

# Check if package manager is available
get_package_manager() {
    if command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        log_error "No supported package manager found"
        return 1
    fi
}

# Install packages using detected package manager
install_packages() {
    local packages=("$@")
    local pkg_manager
    
    pkg_manager=$(get_package_manager) || return 1
    
    log_info "Installing packages with $pkg_manager: ${packages[*]}"
    
    case "$pkg_manager" in
        "dnf"|"yum")
            "$pkg_manager" -y install --setopt=install_weak_deps=False --nodocs "${packages[@]}" >/dev/null 2>&1
            ;;
        "apt")
            apt-get update >/dev/null 2>&1 && apt-get install -y "${packages[@]}" >/dev/null 2>&1
            ;;
        "apk")
            apk add --no-cache "${packages[@]}" >/dev/null 2>&1
            ;;
        "zypper")
            zypper install -y "${packages[@]}" >/dev/null 2>&1
            ;;
        *)
            log_error "Unsupported package manager: $pkg_manager"
            return 1
            ;;
    esac
    
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        log_success "Packages installed successfully"
    else
        log_error "Failed to install packages (exit code: $exit_code)"
    fi
    
    return $exit_code
}

# Check if service is available
is_service_available() {
    local service_name="$1"
    
    if command -v systemctl >/dev/null 2>&1; then
        systemctl list-unit-files "$service_name.service" >/dev/null 2>&1
    elif command -v service >/dev/null 2>&1; then
        service --status-all 2>/dev/null | grep -q "$service_name"
    else
        # Fallback: check if service binary exists
        command -v "$service_name" >/dev/null 2>&1
    fi
}

# Start/enable service
manage_service() {
    local action="$1"
    local service_name="$2"
    
    case "$action" in
        "start"|"stop"|"restart"|"enable"|"disable")
            if command -v systemctl >/dev/null 2>&1; then
                systemctl "$action" "$service_name" >/dev/null 2>&1
                log_success "Service $service_name $action completed"
            elif command -v service >/dev/null 2>&1; then
                case "$action" in
                    "enable"|"disable")
                        log_warning "Service $action not supported with legacy service command"
                        ;;
                    *)
                        service "$service_name" "$action" >/dev/null 2>&1
                        log_success "Service $service_name $action completed"
                        ;;
                esac
            else
                log_error "No service management system found"
                return 1
            fi
            ;;
        *)
            log_error "Unknown service action: $action"
            return 1
            ;;
    esac
}

# Create directory with proper permissions
create_directory() {
    local dir_path="$1"
    local permissions="${2:-755}"
    local owner="${3:-}"
    local group="${4:-}"
    
    mkdir -p "$dir_path"
    chmod "$permissions" "$dir_path"
    
    if [[ -n "$owner" && -n "$group" ]]; then
        chown "$owner:$group" "$dir_path"
    elif [[ -n "$owner" ]]; then
        chown "$owner" "$dir_path"
    fi
    
    log_success "Created directory: $dir_path (permissions: $permissions)"
}

# Backup file before modification
backup_file() {
    local file_path="$1"
    local backup_suffix="${2:-.backup}"
    
    if [[ -f "$file_path" ]]; then
        cp "$file_path" "${file_path}${backup_suffix}"
        log_info "Backed up $file_path to ${file_path}${backup_suffix}"
    else
        log_warning "File not found for backup: $file_path"
    fi
}

# Safe file modification with backup
modify_file_safe() {
    local file_path="$1"
    local modification_function="$2"
    
    # Create backup
    backup_file "$file_path"
    
    # Apply modification
    if "$modification_function" "$file_path"; then
        log_success "File modified successfully: $file_path"
        return 0
    else
        # Restore backup on failure
        if [[ -f "${file_path}.backup" ]]; then
            mv "${file_path}.backup" "$file_path"
            log_warning "Restored backup due to modification failure"
        fi
        log_error "Failed to modify file: $file_path"
        return 1
    fi
}

# Print system environment for debugging
print_debug_environment() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        log_debug "=== System Environment Debug Info ==="
        log_debug "OS: $(get_system_info os)"
        log_debug "Architecture: $(get_system_info arch)"
        log_debug "Kernel: $(get_system_info kernel)"
        log_debug "Hostname: $(get_system_info hostname)"
        log_debug "Container: $(is_running_in_container && echo "yes" || echo "no")"
        log_debug "Package Manager: $(get_package_manager 2>/dev/null || echo "none")"
        log_debug "User: $(whoami)"
        log_debug "Groups: $(groups 2>/dev/null || echo "unknown")"
        log_debug "Working Directory: $(pwd)"
        log_debug "===================================="
    fi
}

# Export functions for use in other scripts
export -f validate_env_vars validate_numeric
export -f is_running_in_container get_system_info get_package_manager
export -f install_packages is_service_available manage_service
export -f create_directory backup_file modify_file_safe
export -f print_debug_environment
