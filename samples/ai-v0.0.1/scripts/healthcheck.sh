#!/bin/bash
# Oracle Linux 9 Container Health Check Script
# Comprehensive health monitoring following enterprise best practices
# Implements structured logging and detailed system validation

set -euo pipefail

# =============================================================================
# Configuration and Constants
# =============================================================================

readonly SCRIPT_NAME="$(basename "${0}")"
readonly LOG_PREFIX="[HEALTHCHECK]"
readonly TIMEOUT=10
readonly CRITICAL_SERVICES=("sshd")
readonly REQUIRED_COMMANDS=("curl" "git" "python3" "node" "npm")
readonly HEALTH_CHECK_FILE="/tmp/.container-health"

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
# Health Check Functions
# =============================================================================

check_system_resources() {
    log "Checking system resources..."
    
    local warnings=0
    
    # Check memory usage
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    
    if [[ ${mem_usage} -gt 90 ]]; then
        log_error "Memory usage critical: ${mem_usage}%"
        return ${EXIT_CRITICAL}
    elif [[ ${mem_usage} -gt 80 ]]; then
        log_warning "Memory usage high: ${mem_usage}%"
        ((warnings++))
    else
        log_success "Memory usage normal: ${mem_usage}%"
    fi
    
    # Check disk usage
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [[ ${disk_usage} -gt 95 ]]; then
        log_error "Disk usage critical: ${disk_usage}%"
        return ${EXIT_CRITICAL}
    elif [[ ${disk_usage} -gt 85 ]]; then
        log_warning "Disk usage high: ${disk_usage}%"
        ((warnings++))
    else
        log_success "Disk usage normal: ${disk_usage}%"
    fi
    
    # Check CPU load
    local cpu_load
    cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_cores
    cpu_cores=$(nproc)
    local cpu_usage
    cpu_usage=$(echo "${cpu_load} ${cpu_cores}" | awk '{printf "%.0f", ($1/$2)*100}')
    
    if [[ ${cpu_usage} -gt 200 ]]; then
        log_error "CPU load critical: ${cpu_usage}% (load: ${cpu_load})"
        return ${EXIT_CRITICAL}
    elif [[ ${cpu_usage} -gt 150 ]]; then
        log_warning "CPU load high: ${cpu_usage}% (load: ${cpu_load})"
        ((warnings++))
    else
        log_success "CPU load normal: ${cpu_usage}% (load: ${cpu_load})"
    fi
    
    return $((warnings > 0 ? EXIT_WARNING : EXIT_SUCCESS))
}

check_required_commands() {
    log "Checking required commands availability..."
    
    local missing_commands=()
    
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if command -v "${cmd}" &> /dev/null; then
            log_success "Command '${cmd}' is available"
        else
            log_error "Command '${cmd}' is missing"
            missing_commands+=("${cmd}")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing critical commands: ${missing_commands[*]}"
        return ${EXIT_CRITICAL}
    fi
    
    return ${EXIT_SUCCESS}
}

check_services() {
    log "Checking critical services..."
    
    local failed_services=()
    
    for service in "${CRITICAL_SERVICES[@]}"; do
        if systemctl is-active --quiet "${service}" 2>/dev/null; then
            log_success "Service '${service}' is running"
        elif pgrep -f "${service}" &> /dev/null; then
            log_success "Process '${service}' is running"
        else
            log_warning "Service/Process '${service}' is not running"
            failed_services+=("${service}")
        fi
    done
    
    # For container environments, some services might not be running via systemd
    # This is often acceptable, so we return warning instead of critical
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        log_warning "Some services are not running: ${failed_services[*]}"
        return ${EXIT_WARNING}
    fi
    
    return ${EXIT_SUCCESS}
}

check_network_connectivity() {
    log "Checking network connectivity..."
    
    # Check localhost connectivity
    if curl -s --connect-timeout 5 http://localhost:8080/health 2>/dev/null | grep -q "ok" 2>/dev/null; then
        log_success "Application health endpoint responding"
    else
        log_warning "Application health endpoint not responding (this may be normal if no app is running)"
    fi
    
    # Check external connectivity (if internet is available)
    if curl -s --connect-timeout 5 --max-time 10 https://www.google.com &> /dev/null; then
        log_success "External network connectivity available"
    else
        log_warning "External network connectivity limited or unavailable"
    fi
    
    return ${EXIT_SUCCESS}
}

check_file_permissions() {
    log "Checking critical file permissions..."
    
    local permission_issues=0
    
    # Check workspace directory permissions
    if [[ -d "/workspace" ]]; then
        if [[ -w "/workspace" ]]; then
            log_success "Workspace directory is writable"
        else
            log_error "Workspace directory is not writable"
            ((permission_issues++))
        fi
    else
        log_warning "Workspace directory does not exist"
    fi
    
    # Check home directory permissions
    if [[ -w "${HOME}" ]]; then
        log_success "Home directory is writable"
    else
        log_error "Home directory is not writable"
        ((permission_issues++))
    fi
    
    # Check SSH directory permissions (if exists)
    if [[ -d "${HOME}/.ssh" ]]; then
        local ssh_perms
        ssh_perms=$(stat -c "%a" "${HOME}/.ssh")
        if [[ "${ssh_perms}" == "700" ]]; then
            log_success "SSH directory permissions are correct (700)"
        else
            log_warning "SSH directory permissions are not optimal: ${ssh_perms} (should be 700)"
        fi
    fi
    
    return $((permission_issues > 0 ? EXIT_CRITICAL : EXIT_SUCCESS))
}

check_development_tools() {
    log "Checking development tools functionality..."
    
    local tool_issues=0
    
    # Check Git configuration
    if git config --global user.name &> /dev/null && git config --global user.email &> /dev/null; then
        log_success "Git is configured with user information"
    else
        log_warning "Git user information not configured"
    fi
    
    # Check Python
    if python3 -c "import sys; print(f'Python {sys.version}')" &> /dev/null; then
        local python_version
        python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        log_success "Python ${python_version} is working"
    else
        log_error "Python is not working correctly"
        ((tool_issues++))
    fi
    
    # Check Node.js
    if node --version &> /dev/null; then
        local node_version
        node_version=$(node --version)
        log_success "Node.js ${node_version} is working"
    else
        log_error "Node.js is not working correctly"
        ((tool_issues++))
    fi
    
    # Check npm
    if npm --version &> /dev/null; then
        local npm_version
        npm_version=$(npm --version)
        log_success "npm ${npm_version} is working"
    else
        log_error "npm is not working correctly"
        ((tool_issues++))
    fi
    
    return $((tool_issues > 0 ? EXIT_CRITICAL : EXIT_SUCCESS))
}

# =============================================================================
# Main Health Check Process
# =============================================================================

run_health_checks() {
    log "Starting comprehensive health check..."
    
    local overall_status=${EXIT_SUCCESS}
    local check_results=()
    
    # Run all health checks
    local checks=(
        "check_system_resources"
        "check_required_commands"
        "check_services"
        "check_network_connectivity"
        "check_file_permissions"
        "check_development_tools"
    )
    
    for check in "${checks[@]}"; do
        log "Running ${check}..."
        if ${check}; then
            check_results+=("${check}:SUCCESS")
        else
            local exit_code=$?
            check_results+=("${check}:FAILED:${exit_code}")
            if [[ ${exit_code} -eq ${EXIT_CRITICAL} ]]; then
                overall_status=${EXIT_CRITICAL}
            elif [[ ${exit_code} -eq ${EXIT_WARNING} && ${overall_status} -eq ${EXIT_SUCCESS} ]]; then
                overall_status=${EXIT_WARNING}
            fi
        fi
    done
    
    # Write health check results to file
    {
        echo "timestamp=$(date -Iseconds)"
        echo "status=${overall_status}"
        echo "checks=${#checks[@]}"
        for result in "${check_results[@]}"; do
            echo "result=${result}"
        done
    } > "${HEALTH_CHECK_FILE}"
    
    # Log final status
    case ${overall_status} in
        ${EXIT_SUCCESS})
            log_success "All health checks passed successfully"
            ;;
        ${EXIT_WARNING})
            log_warning "Health checks completed with warnings"
            ;;
        ${EXIT_CRITICAL})
            log_error "Health checks failed with critical issues"
            ;;
    esac
    
    return ${overall_status}
}

# =============================================================================
# Script Entry Point
# =============================================================================

main() {
    # Set timeout for the entire health check
    timeout ${TIMEOUT} bash -c 'run_health_checks' || {
        local exit_code=$?
        if [[ ${exit_code} -eq 124 ]]; then
            log_error "Health check timed out after ${TIMEOUT} seconds"
            exit ${EXIT_CRITICAL}
        else
            exit ${exit_code}
        fi
    }
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
