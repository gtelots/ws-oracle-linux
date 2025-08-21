#!/bin/bash
# =============================================================================
# User Management Functions - Reusable user/group operations
# =============================================================================

# Validate user-related arguments
validate_user_args() {
    local required_vars=("USERNAME" "USER_UID" "USER_GID")
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Required argument $var is not set"
            return 1
        fi
    done
    
    # Validate UID/GID are numeric
    if ! [[ "${USER_UID}" =~ ^[0-9]+$ ]] || ! [[ "${USER_GID}" =~ ^[0-9]+$ ]]; then
        log_error "USER_UID and USER_GID must be numeric"
        return 1
    fi
    
    log_success "User arguments validated: USERNAME=$USERNAME, USER_UID=$USER_UID, USER_GID=$USER_GID"
    return 0
}

# Install sudo package if not present
ensure_sudo_installed() {
    if ! command -v sudo >/dev/null 2>&1; then
        log_info "Installing sudo package"
        if command -v dnf >/dev/null 2>&1; then
            dnf -y install --setopt=install_weak_deps=False --nodocs sudo >/dev/null 2>&1
        elif command -v apt >/dev/null 2>&1; then
            apt-get update >/dev/null 2>&1 && apt-get install -y sudo >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then
            yum -y install sudo >/dev/null 2>&1
        else
            log_error "No supported package manager found (dnf/apt/yum)"
            return 1
        fi
        log_success "sudo package installed"
    else
        log_info "sudo already installed"
    fi
    return 0
}

# Create group idempotently
create_group_if_not_exists() {
    local group_name="$1"
    local group_gid="$2"
    
    if ! getent group "${group_gid}" >/dev/null 2>&1; then
        groupadd -g "${group_gid}" "${group_name}"
        log_success "Created group ${group_name} with GID ${group_gid}"
    else
        local existing_group
        existing_group=$(getent group "${group_gid}" | cut -d: -f1)
        log_info "Group with GID ${group_gid} already exists: $existing_group"
    fi
    return 0
}

# Create user idempotently
create_user_if_not_exists() {
    local username="$1"
    local user_uid="$2"
    local user_gid="$3"
    local shell="${4:-/bin/bash}"
    
    if ! id -u "${username}" >/dev/null 2>&1; then
        useradd -u "${user_uid}" -g "${user_gid}" -m -s "${shell}" "${username}"
        log_success "Created user ${username} with UID ${user_uid}"
    else
        local existing_uid
        existing_uid=$(id -u "${username}")
        log_info "User ${username} already exists with UID ${existing_uid}"
        
        # Verify UID matches if user exists
        if [[ "${existing_uid}" != "${user_uid}" ]]; then
            log_warning "Existing user UID (${existing_uid}) differs from requested UID (${user_uid})"
        fi
    fi
    return 0
}

# Set password for user (supports hashed and plaintext)
set_user_password() {
    local username="$1"
    local password="$2"
    
    # Skip if password is empty or not provided
    if [[ -z "${password:-}" ]]; then
        log_info "No password provided for user $username, skipping"
        return 0
    fi
    
    # Detect if password is already hashed (starts with $ and contains proper hash format)
    if [[ "$password" =~ ^\$[0-9]+\$ ]]; then
        # Hashed password
        echo "$username:$password" | chpasswd -e
        log_success "Set hashed password for $username"
    else
        # Plaintext password
        echo "$username:$password" | chpasswd
        log_success "Set plaintext password for $username"
    fi
    return 0
}

# Add user to group if not already a member
add_user_to_group() {
    local username="$1"
    local groupname="$2"
    
    # Ensure group exists
    if ! getent group "${groupname}" >/dev/null 2>&1; then
        groupadd "${groupname}"
        log_success "Created group ${groupname}"
    fi
    
    # Add user to group if not already a member
    if ! groups "${username}" | grep -q "\\b${groupname}\\b"; then
        usermod -aG "${groupname}" "${username}"
        log_success "Added ${username} to ${groupname} group"
    else
        log_info "${username} is already in ${groupname} group"
    fi
    return 0
}

# Setup user directories with proper permissions
setup_user_home_directories() {
    local username="$1"
    local user_uid="$2"
    local user_gid="$3"
    
    local user_home="/home/${username}"
    local directories=(
        "${user_home}/.local/bin"
        "${user_home}/.config"
        "${user_home}/.cache"
        "${user_home}/.ssh"
    )
    
    # Create directories
    for dir in "${directories[@]}"; do
        mkdir -p "${dir}"
    done
    
    # Set proper ownership and permissions
    chown -R "${user_uid}:${user_gid}" "${user_home}/.local" "${user_home}/.config" "${user_home}/.cache" "${user_home}/.ssh"
    chmod -R u+rwX "${user_home}/.local" "${user_home}/.config" "${user_home}/.cache"
    chmod 700 "${user_home}/.ssh"
    
    log_success "User directories configured for ${username}"
    log_info "  Home: ${user_home}"
    log_info "  Local bin: ${user_home}/.local/bin"
    log_info "  Config: ${user_home}/.config"
    log_info "  Cache: ${user_home}/.cache"
    log_info "  SSH: ${user_home}/.ssh"
    return 0
}

# Configure sudo access for user via wheel group
configure_user_sudo() {
    local username="$1"
    
    # Add user to wheel group
    add_user_to_group "${username}" "wheel"
    
    # Create sudoers.d directory if it doesn't exist
    install -d -m 0755 /etc/sudoers.d
    
    # Create wheel sudo rule (idempotent)
    local wheel_rule="/etc/sudoers.d/99-wheel"
    printf '%%wheel ALL=(ALL:ALL) NOPASSWD:ALL\n' > "${wheel_rule}"
    chmod 0440 "${wheel_rule}"
    log_success "Created sudo rule for wheel group"
    
    # Ensure sudoers includes sudoers.d directory
    if ! grep -q '^#includedir /etc/sudoers.d' /etc/sudoers; then
        printf '\n#includedir /etc/sudoers.d\n' >> /etc/sudoers
        log_success "Added includedir to /etc/sudoers"
    else
        log_info "sudoers already includes sudoers.d directory"
    fi
    
    # Disable requiretty for containers
    if ! grep -q '^Defaults !requiretty' /etc/sudoers; then
        sed -i '1i Defaults !requiretty' /etc/sudoers
        log_success "Disabled requiretty in sudoers"
    else
        log_info "requiretty already disabled"
    fi
    
    # Validate sudoers configuration if visudo is available
    if command -v visudo >/dev/null 2>&1; then
        if visudo -cf "${wheel_rule}" >/dev/null 2>&1; then
            log_success "Sudoers configuration validated successfully"
        else
            log_error "Sudoers validation failed for ${wheel_rule}"
            return 1
        fi
    else
        log_warning "visudo not available, skipping validation"
    fi
    
    return 0
}

# Complete user setup (high-level function)
setup_user_complete() {
    local username="$1"
    local user_uid="$2"
    local user_gid="$3"
    local user_password="${4:-}"
    local shell="${5:-/bin/bash}"
    
    log_info "Setting up user: $username (UID: $user_uid, GID: $user_gid)"
    
    # Ensure sudo is available
    ensure_sudo_installed || return 1
    
    # Create group and user
    create_group_if_not_exists "$username" "$user_gid" || return 1
    create_user_if_not_exists "$username" "$user_uid" "$user_gid" "$shell" || return 1
    
    # Set password if provided
    if [[ -n "$user_password" ]]; then
        set_user_password "$username" "$user_password" || return 1
    fi
    
    # Configure sudo access
    configure_user_sudo "$username" || return 1
    
    # Setup home directories
    setup_user_home_directories "$username" "$user_uid" "$user_gid" || return 1
    
    log_success "User setup completed for $username"
    return 0
}

# Export functions for use in other scripts
export -f validate_user_args ensure_sudo_installed 
export -f create_group_if_not_exists create_user_if_not_exists
export -f set_user_password add_user_to_group
export -f setup_user_home_directories configure_user_sudo
export -f setup_user_complete
