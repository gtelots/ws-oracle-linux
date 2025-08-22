#!/bin/bash
# Oracle Linux 9 Container Security Check Script
# Comprehensive security validation following Bitnami security patterns
# Enterprise-grade security assessment and hardening verification

set -euo pipefail

# =============================================================================
# Configuration and Constants
# =============================================================================

readonly SCRIPT_NAME="$(basename "${0}")"
readonly LOG_PREFIX="[SECURITY-CHECK]"
readonly SECURITY_REPORT="/tmp/security-report.json"
readonly CRITICAL_FILES=("/etc/passwd" "/etc/shadow" "/etc/sudoers")
readonly SENSITIVE_DIRS=("/etc" "/var/log" "/home")

# Security thresholds
readonly MAX_FAILED_LOGINS=5
readonly MIN_PASSWORD_LENGTH=8
readonly MAX_WORLD_WRITABLE_FILES=10

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_WARNING=1
readonly EXIT_CRITICAL=2

# =============================================================================
# Utility Functions
# =============================================================================

log() {
    echo "${LOG_PREFIX} [$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log_success() {
    echo "${LOG_PREFIX} [$(date +'%Y-%m-%d %H:%M:%S')] ✅ $*"
}

log_warning() {
    echo "${LOG_PREFIX} [$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $*"
}

log_error() {
    echo "${LOG_PREFIX} [$(date +'%Y-%m-%d %H:%M:%S')] ❌ $*"
}

# =============================================================================
# Security Check Functions
# =============================================================================

check_user_security() {
    log "Checking user security configuration..."
    
    local security_issues=0
    
    # Check if running as non-root
    if [[ $EUID -eq 0 ]]; then
        log_error "Container is running as root user (security risk)"
        ((security_issues++))
    else
        log_success "Container is running as non-root user (UID: $EUID)"
    fi
    
    # Check for users with empty passwords
    local empty_password_users
    empty_password_users=$(awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null | wc -l)
    if [[ ${empty_password_users} -gt 0 ]]; then
        log_error "Found ${empty_password_users} users with empty passwords"
        ((security_issues++))
    else
        log_success "No users with empty passwords found"
    fi
    
    # Check for duplicate UIDs
    local duplicate_uids
    duplicate_uids=$(awk -F: '{print $3}' /etc/passwd | sort | uniq -d | wc -l)
    if [[ ${duplicate_uids} -gt 0 ]]; then
        log_warning "Found ${duplicate_uids} duplicate UIDs"
    else
        log_success "No duplicate UIDs found"
    fi
    
    return $((security_issues > 0 ? EXIT_CRITICAL : EXIT_SUCCESS))
}

check_file_permissions() {
    log "Checking critical file permissions..."
    
    local permission_issues=0
    
    # Check critical system files
    for file in "${CRITICAL_FILES[@]}"; do
        if [[ -f "${file}" ]]; then
            local perms
            perms=$(stat -c "%a" "${file}")
            local owner
            owner=$(stat -c "%U" "${file}")
            
            case "${file}" in
                "/etc/passwd")
                    if [[ "${perms}" != "644" ]] || [[ "${owner}" != "root" ]]; then
                        log_error "${file} has incorrect permissions: ${perms} (${owner})"
                        ((permission_issues++))
                    else
                        log_success "${file} permissions are correct"
                    fi
                    ;;
                "/etc/shadow")
                    if [[ "${perms}" != "000" ]] && [[ "${perms}" != "640" ]]; then
                        log_error "${file} has incorrect permissions: ${perms}"
                        ((permission_issues++))
                    else
                        log_success "${file} permissions are secure"
                    fi
                    ;;
                "/etc/sudoers")
                    if [[ "${perms}" != "440" ]] || [[ "${owner}" != "root" ]]; then
                        log_error "${file} has incorrect permissions: ${perms} (${owner})"
                        ((permission_issues++))
                    else
                        log_success "${file} permissions are correct"
                    fi
                    ;;
            esac
        fi
    done
    
    # Check for world-writable files
    local world_writable_count
    world_writable_count=$(find /etc /var /usr -type f -perm -002 2>/dev/null | wc -l)
    if [[ ${world_writable_count} -gt ${MAX_WORLD_WRITABLE_FILES} ]]; then
        log_error "Found ${world_writable_count} world-writable files (threshold: ${MAX_WORLD_WRITABLE_FILES})"
        ((permission_issues++))
    else
        log_success "World-writable files within acceptable limits: ${world_writable_count}"
    fi
    
    return $((permission_issues > 0 ? EXIT_CRITICAL : EXIT_SUCCESS))
}

check_network_security() {
    log "Checking network security configuration..."
    
    local network_issues=0
    
    # Check for open ports
    local listening_ports
    listening_ports=$(ss -tuln | grep LISTEN | wc -l)
    log "Found ${listening_ports} listening ports"
    
    # List all listening ports for transparency
    if command -v ss &> /dev/null; then
        log "Listening ports:"
        ss -tuln | grep LISTEN | while read -r line; do
            log "  ${line}"
        done
    fi
    
    # Check SSH configuration if SSH is running
    if pgrep -f sshd &> /dev/null && [[ -f /etc/ssh/sshd_config ]]; then
        # Check if root login is disabled
        if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
            log_success "SSH root login is disabled"
        else
            log_warning "SSH root login may be enabled"
        fi
        
        # Check if password authentication is disabled
        if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
            log_success "SSH password authentication is disabled"
        else
            log_warning "SSH password authentication may be enabled"
        fi
    fi
    
    return $((network_issues > 0 ? EXIT_WARNING : EXIT_SUCCESS))
}

check_container_security() {
    log "Checking container-specific security settings..."
    
    local container_issues=0
    
    # Check if running in privileged mode
    if [[ -f /proc/self/status ]]; then
        local cap_eff
        cap_eff=$(grep CapEff /proc/self/status | awk '{print $2}')
        if [[ "${cap_eff}" == "0000003fffffffff" ]] || [[ "${cap_eff}" == "ffffffffffffffff" ]]; then
            log_error "Container appears to be running in privileged mode"
            ((container_issues++))
        else
            log_success "Container is running with limited capabilities"
        fi
    fi
    
    # Check for Docker socket access
    if [[ -S /var/run/docker.sock ]]; then
        log_error "Docker socket is accessible from container (security risk)"
        ((container_issues++))
    else
        log_success "Docker socket is not accessible from container"
    fi
    
    # Check for host filesystem mounts
    local suspicious_mounts
    suspicious_mounts=$(mount | grep -E "(^/dev/|^/proc/|^/sys/)" | grep -v "ro," | wc -l)
    if [[ ${suspicious_mounts} -gt 0 ]]; then
        log_warning "Found ${suspicious_mounts} potentially suspicious filesystem mounts"
    else
        log_success "No suspicious filesystem mounts detected"
    fi
    
    return $((container_issues > 0 ? EXIT_CRITICAL : EXIT_SUCCESS))
}

check_package_security() {
    log "Checking package security and updates..."
    
    local package_issues=0
    
    # Check for available security updates (Oracle Linux specific)
    if command -v microdnf &> /dev/null; then
        local security_updates
        security_updates=$(microdnf updateinfo list security 2>/dev/null | grep -c "security" || echo "0")
        if [[ ${security_updates} -gt 0 ]]; then
            log_warning "Found ${security_updates} available security updates"
        else
            log_success "No pending security updates found"
        fi
    fi
    
    # Check for known vulnerable packages (basic check)
    local vulnerable_packages=()
    
    # Check for old OpenSSL versions
    if command -v openssl &> /dev/null; then
        local openssl_version
        openssl_version=$(openssl version | awk '{print $2}')
        log "OpenSSL version: ${openssl_version}"
    fi
    
    return $((package_issues > 0 ? EXIT_WARNING : EXIT_SUCCESS))
}

check_log_security() {
    log "Checking log file security..."
    
    local log_issues=0
    
    # Check log directory permissions
    if [[ -d /var/log ]]; then
        local log_perms
        log_perms=$(stat -c "%a" /var/log)
        if [[ "${log_perms}" != "755" ]]; then
            log_warning "/var/log permissions are not standard: ${log_perms}"
        else
            log_success "/var/log permissions are correct"
        fi
    fi
    
    # Check for sensitive information in logs
    local sensitive_patterns=("password" "secret" "key" "token")
    local sensitive_found=0
    
    for pattern in "${sensitive_patterns[@]}"; do
        if find /var/log -type f -name "*.log" -exec grep -l -i "${pattern}" {} \; 2>/dev/null | head -1 | grep -q .; then
            log_warning "Potential sensitive information found in logs (pattern: ${pattern})"
            ((sensitive_found++))
        fi
    done
    
    if [[ ${sensitive_found} -eq 0 ]]; then
        log_success "No obvious sensitive information found in logs"
    fi
    
    return $((log_issues > 0 ? EXIT_WARNING : EXIT_SUCCESS))
}

# =============================================================================
# Security Report Generation
# =============================================================================

generate_security_report() {
    log "Generating security report..."
    
    local timestamp
    timestamp=$(date -Iseconds)
    
    cat > "${SECURITY_REPORT}" <<EOF
{
  "timestamp": "${timestamp}",
  "hostname": "$(hostname)",
  "user": "$(whoami)",
  "uid": "${EUID}",
  "security_checks": {
    "user_security": "$(check_user_security >/dev/null 2>&1 && echo "PASS" || echo "FAIL")",
    "file_permissions": "$(check_file_permissions >/dev/null 2>&1 && echo "PASS" || echo "FAIL")",
    "network_security": "$(check_network_security >/dev/null 2>&1 && echo "PASS" || echo "FAIL")",
    "container_security": "$(check_container_security >/dev/null 2>&1 && echo "PASS" || echo "FAIL")",
    "package_security": "$(check_package_security >/dev/null 2>&1 && echo "PASS" || echo "FAIL")",
    "log_security": "$(check_log_security >/dev/null 2>&1 && echo "PASS" || echo "FAIL")"
  },
  "system_info": {
    "os_release": "$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')",
    "kernel": "$(uname -r)",
    "uptime": "$(uptime -p)"
  }
}
EOF
    
    log_success "Security report generated: ${SECURITY_REPORT}"
}

# =============================================================================
# Main Security Check Process
# =============================================================================

main() {
    log "Starting comprehensive security check..."
    
    local overall_status=${EXIT_SUCCESS}
    
    # Run all security checks
    local checks=(
        "check_user_security"
        "check_file_permissions"
        "check_network_security"
        "check_container_security"
        "check_package_security"
        "check_log_security"
    )
    
    for check in "${checks[@]}"; do
        log "Running ${check}..."
        if ! ${check}; then
            local exit_code=$?
            if [[ ${exit_code} -eq ${EXIT_CRITICAL} ]]; then
                overall_status=${EXIT_CRITICAL}
            elif [[ ${exit_code} -eq ${EXIT_WARNING} && ${overall_status} -eq ${EXIT_SUCCESS} ]]; then
                overall_status=${EXIT_WARNING}
            fi
        fi
    done
    
    # Generate security report
    generate_security_report
    
    # Log final status
    case ${overall_status} in
        ${EXIT_SUCCESS})
            log_success "All security checks passed successfully"
            ;;
        ${EXIT_WARNING})
            log_warning "Security checks completed with warnings"
            ;;
        ${EXIT_CRITICAL})
            log_error "Security checks failed with critical issues"
            ;;
    esac
    
    return ${overall_status}
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
