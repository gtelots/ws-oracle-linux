#!/usr/bin/env bash
# =============================================================================
# Container Health Check Script
# =============================================================================
# DESCRIPTION: Comprehensive health check for the development container
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly HEALTH_CHECK_TIMEOUT=30
readonly HEALTH_CHECK_LOG="/var/log/health-check.log"

# Health check functions
check_system_resources() {
    log_info "Checking system resources..."
    
    # Check memory usage (fail if > 95%)
    local memory_usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
    if [[ $memory_usage -gt 95 ]]; then
        log_error "Memory usage too high: ${memory_usage}%"
        return 1
    fi
    
    # Check disk usage (fail if > 90%)
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 90 ]]; then
        log_error "Disk usage too high: ${disk_usage}%"
        return 1
    fi
    
    log_success "System resources OK (Memory: ${memory_usage}%, Disk: ${disk_usage}%)"
    return 0
}

check_essential_services() {
    log_info "Checking essential services..."
    
    # Check if SSH server is running (essential service)
    if ! pgrep -f sshd >/dev/null; then
        log_error "SSH server is not running"
        return 1
    fi
    log_success "SSH server is running"
    
    # Check if Supervisor is running
    if ! pgrep -f supervisord >/dev/null; then
        log_warn "Supervisor is not running"
    else
        log_success "Supervisor is running"
    fi
    
    return 0
}

check_development_tools() {
    log_info "Checking development tools..."
    
    # Essential tools that should always be available
    local essential_tools=(
        "bash" "curl" "wget" "git" "vim" "python3" "pip3"
    )
    
    local missing_tools=()
    for tool in "${essential_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing essential tools: ${missing_tools[*]}"
        return 1
    fi
    
    log_success "Essential development tools are available"
    return 0
}

check_language_runtimes() {
    log_info "Checking language runtimes..."
    
    local runtime_status=0
    
    # Check Python
    if command -v python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version 2>&1)
        log_success "Python: $python_version"
    else
        log_error "Python is not available"
        runtime_status=1
    fi
    
    # Check Node.js (if available)
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version 2>&1)
        log_success "Node.js: $node_version"
    else
        log_info "Node.js: Not installed"
    fi

    # Check Java (if available)
    if command -v java >/dev/null 2>&1; then
        local java_version=$(java -version 2>&1 | head -n1)
        log_success "Java: $java_version"
    else
        log_info "Java: Not installed"
    fi

    # Check Go (if available)
    if command -v go >/dev/null 2>&1; then
        local go_version=$(go version 2>&1)
        log_success "Go: $go_version"
    else
        log_info "Go: Not installed"
    fi

    # Check Rust (if available)
    if command -v rustc >/dev/null 2>&1; then
        local rust_version=$(rustc --version 2>&1)
        log_success "Rust: $rust_version"
    else
        log_info "Rust: Not installed"
    fi

    # Check PHP (if available)
    if command -v php >/dev/null 2>&1; then
        local php_version=$(php --version 2>&1 | head -n1)
        log_success "PHP: $php_version"
    else
        log_info "PHP: Not installed"
    fi

    # Check Ruby (if available)
    if command -v ruby >/dev/null 2>&1; then
        local ruby_version=$(ruby --version 2>&1)
        log_success "Ruby: $ruby_version"
    else
        log_info "Ruby: Not installed"
    fi
    
    return $runtime_status
}

check_network_connectivity() {
    log_info "Checking network connectivity..."
    
    # Check if we can resolve DNS
    if ! nslookup google.com >/dev/null 2>&1; then
        log_error "DNS resolution failed"
        return 1
    fi
    
    # Check if we can reach the internet
    if ! curl -s --max-time 10 https://google.com >/dev/null; then
        log_error "Internet connectivity failed"
        return 1
    fi
    
    log_success "Network connectivity OK"
    return 0
}

check_file_permissions() {
    log_info "Checking file permissions..."
    
    # Check if user can write to workspace
    if [[ -d "/workspace" ]]; then
        if ! touch /workspace/.health-check-test 2>/dev/null; then
            log_error "Cannot write to workspace directory"
            return 1
        fi
        rm -f /workspace/.health-check-test
    fi
    
    # Check if user can write to home directory
    if ! touch ~/.health-check-test 2>/dev/null; then
        log_error "Cannot write to home directory"
        return 1
    fi
    rm -f ~/.health-check-test
    
    log_success "File permissions OK"
    return 0
}

generate_health_report() {
    local overall_status=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > /tmp/health-report.json << EOF
{
    "timestamp": "$timestamp",
    "status": "$([[ $overall_status -eq 0 ]] && echo "healthy" || echo "unhealthy")",
    "checks": {
        "system_resources": "$([[ $system_check -eq 0 ]] && echo "pass" || echo "fail")",
        "essential_services": "$([[ $services_check -eq 0 ]] && echo "pass" || echo "fail")",
        "development_tools": "$([[ $tools_check -eq 0 ]] && echo "pass" || echo "fail")",
        "language_runtimes": "$([[ $runtimes_check -eq 0 ]] && echo "pass" || echo "fail")",
        "network_connectivity": "$([[ $network_check -eq 0 ]] && echo "pass" || echo "fail")",
        "file_permissions": "$([[ $permissions_check -eq 0 ]] && echo "pass" || echo "fail")"
    }
}
EOF
    
    # Also log to health check log
    echo "[$timestamp] Health check status: $([[ $overall_status -eq 0 ]] && echo "HEALTHY" || echo "UNHEALTHY")" >> "$HEALTH_CHECK_LOG"
}

# Main health check function
main() {
    log_info "Starting container health check..."
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$HEALTH_CHECK_LOG")"
    
    # Run all health checks
    check_system_resources
    local system_check=$?
    
    check_essential_services
    local services_check=$?
    
    check_development_tools
    local tools_check=$?
    
    check_language_runtimes
    local runtimes_check=$?
    
    check_network_connectivity
    local network_check=$?
    
    check_file_permissions
    local permissions_check=$?
    
    # Calculate overall status
    local overall_status=0
    if [[ $system_check -ne 0 ]] || [[ $services_check -ne 0 ]] || [[ $tools_check -ne 0 ]] || 
       [[ $runtimes_check -ne 0 ]] || [[ $network_check -ne 0 ]] || [[ $permissions_check -ne 0 ]]; then
        overall_status=1
    fi
    
    # Generate health report
    generate_health_report $overall_status
    
    if [[ $overall_status -eq 0 ]]; then
        log_success "Container health check passed"
        exit 0
    else
        log_error "Container health check failed"
        exit 1
    fi
}

# Handle timeout
timeout $HEALTH_CHECK_TIMEOUT bash -c "$(declare -f main); main" || {
    log_error "Health check timed out after ${HEALTH_CHECK_TIMEOUT} seconds"
    exit 1
}
