#!/bin/bash
# -----------------------------------------------------------------------------
# Hosts File Management Script
# -----------------------------------------------------------------------------
# This script provides utilities to manage /etc/hosts file:
# - Add new IP-host mappings
# - Remove existing mappings
# - Update existing mappings
# - Backup and restore functionality
# -----------------------------------------------------------------------------

set -euo pipefail

# Load shared functions
# shellcheck source=../common/functions.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common/functions.sh"

# Configuration
readonly HOSTS_FILE="/etc/hosts"
readonly BACKUP_DIR="/etc/hosts.d/backups"
readonly HOSTS_SCRIPT_MARKER="# Managed by hosts-manager script"

# Ensure backup directory exists
setup_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        sudo mkdir -p "$BACKUP_DIR"
        log_info "Created backup directory: $BACKUP_DIR"
    fi
}

# Create backup of hosts file
backup_hosts() {
    local backup_file="$BACKUP_DIR/hosts.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp "$HOSTS_FILE" "$backup_file"
    log_info "Hosts file backed up to: $backup_file"
    echo "$backup_file"
}

# Add IP-host mapping to /etc/hosts
add_host() {
    local ip="$1"
    local hostname="$2"
    local comment="${3:-}"
    
    # Validate IP address
    if ! [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && 
       ! [[ "$ip" =~ ^[0-9a-fA-F:]+$ ]]; then
        log_error "Invalid IP address: $ip"
        return 1
    fi
    
    # Validate hostname
    if ! [[ "$hostname" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        log_error "Invalid hostname: $hostname"
        return 1
    fi
    
    # Check if mapping already exists
    if grep -q "^$ip[[:space:]]\+$hostname" "$HOSTS_FILE"; then
        log_warn "Mapping already exists: $ip -> $hostname"
        return 0
    fi
    
    # Check if hostname exists with different IP
    if grep -q "[[:space:]]$hostname\([[:space:]]\|$\)" "$HOSTS_FILE"; then
        log_warn "Hostname '$hostname' already exists with different IP"
        log_info "Use update_host() to change the mapping"
        return 1
    fi
    
    # Create backup before modification
    local backup_file
    backup_file=$(backup_hosts)
    
    # Add new mapping
    local entry="$ip    $hostname"
    if [[ -n "$comment" ]]; then
        entry="$entry    # $comment"
    fi
    entry="$entry    $HOSTS_SCRIPT_MARKER"
    
    echo "$entry" | sudo tee -a "$HOSTS_FILE" > /dev/null
    log_info "Added mapping: $ip -> $hostname"
}

# Remove IP-host mapping from /etc/hosts
remove_host() {
    local hostname="$1"
    
    # Check if hostname exists
    if ! grep -q "[[:space:]]$hostname\([[:space:]]\|$\)" "$HOSTS_FILE"; then
        log_warn "Hostname '$hostname' not found in hosts file"
        return 0
    fi
    
    # Create backup before modification
    local backup_file
    backup_file=$(backup_hosts)
    
    # Remove the mapping
    sudo sed -i "/[[:space:]]$hostname\([[:space:]]\|$\)/d" "$HOSTS_FILE"
    log_info "Removed hostname: $hostname"
}

# Update existing IP-host mapping
update_host() {
    local ip="$1"
    local hostname="$2"
    local comment="${3:-}"
    
    # Remove existing mapping
    remove_host "$hostname"
    
    # Add new mapping
    add_host "$ip" "$hostname" "$comment"
    log_info "Updated mapping: $ip -> $hostname"
}

# List all custom mappings (added by this script)
list_custom_hosts() {
    log_info "Custom host mappings (managed by script):"
    grep "$HOSTS_SCRIPT_MARKER" "$HOSTS_FILE" || log_info "No custom mappings found"
}

# Show current hosts file content
show_hosts() {
    log_info "Current /etc/hosts content:"
    cat "$HOSTS_FILE"
}

# Restore hosts file from backup
restore_hosts() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    sudo cp "$backup_file" "$HOSTS_FILE"
    log_info "Hosts file restored from: $backup_file"
}

# List available backups
list_backups() {
    log_info "Available backup files:"
    ls -la "$BACKUP_DIR"/ 2>/dev/null || log_info "No backups found"
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $0 <command> [arguments]

Commands:
  add <ip> <hostname> [comment]     Add new IP-host mapping
  remove <hostname>                 Remove hostname mapping
  update <ip> <hostname> [comment]  Update existing mapping
  list                             List custom mappings
  show                             Show entire hosts file
  backup                           Create manual backup
  restore <backup_file>            Restore from backup
  list-backups                     List available backups

Examples:
  $0 add 192.168.1.100 myserver.local "Development server"
  $0 remove myserver.local
  $0 update 192.168.1.101 myserver.local "Updated IP"
  $0 list
  $0 restore /etc/hosts.d/backups/hosts.backup.20250119_143022

EOF
}

# Main function
main() {
    # Ensure running as root for hosts file modification
    if [[ $EUID -ne 0 ]] && [[ "$1" != "list" ]] && [[ "$1" != "show" ]] && [[ "$1" != "list-backups" ]]; then
        log_error "This script requires root privileges for hosts file modification"
        exit 1
    fi
    
    setup_backup_dir
    
    case "${1:-}" in
        "add")
            if [[ $# -lt 3 ]]; then
                log_error "Usage: $0 add <ip> <hostname> [comment]"
                exit 1
            fi
            add_host "$2" "$3" "${4:-}"
            ;;
        "remove")
            if [[ $# -lt 2 ]]; then
                log_error "Usage: $0 remove <hostname>"
                exit 1
            fi
            remove_host "$2"
            ;;
        "update")
            if [[ $# -lt 3 ]]; then
                log_error "Usage: $0 update <ip> <hostname> [comment]"
                exit 1
            fi
            update_host "$2" "$3" "${4:-}"
            ;;
        "list")
            list_custom_hosts
            ;;
        "show")
            show_hosts
            ;;
        "backup")
            backup_hosts
            ;;
        "restore")
            if [[ $# -lt 2 ]]; then
                log_error "Usage: $0 restore <backup_file>"
                exit 1
            fi
            restore_hosts "$2"
            ;;
        "list-backups")
            list_backups
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            log_error "Unknown command: ${1:-}"
            show_usage
            exit 1
            ;;
    esac
}

# Only run if called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
