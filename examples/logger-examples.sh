#!/bin/bash
# =============================================================================
# Logger Examples - Demonstration Scripts
# =============================================================================
# 
# DESCRIPTION:
#   Collection of example scripts showing how to use the professional
#   logger utility in different scenarios.
#
# USAGE:
#   ./examples/logger-examples.sh [example_name]
#
# EXAMPLES:
#   ./examples/logger-examples.sh basic
#   ./examples/logger-examples.sh deployment
#   ./examples/logger-examples.sh monitoring
#   ./examples/logger-examples.sh error_handling
# =============================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source the logger
source "${PROJECT_ROOT}/scripts/logger.sh"

# =============================================================================
# Example 1: Basic Logging
# =============================================================================

example_basic() {
    echo "=== Basic Logging Example ==="
    
    # Configure logger
    set_log_level "DEBUG"
    set_colors true
    
    log_info "Starting basic logging example"
    log_debug "This is debug information"
    log_success "Operation completed successfully"
    log_warning "This is a warning message"
    log_error "This is an error message" || true
    
    echo
    log_info "Example completed"
}

# =============================================================================
# Example 2: File Logging
# =============================================================================

example_file_logging() {
    echo "=== File Logging Example ==="
    
    local log_file="/tmp/example-app.log"
    
    # Configure file logging
    set_log_file "$log_file"
    set_log_level "INFO"
    
    log_info "Starting file logging example"
    log_info "Log file: $log_file"
    
    # Simulate application workflow
    log_info "Initializing application..."
    sleep 1
    
    log_success "Configuration loaded"
    log_info "Connecting to services..."
    sleep 1
    
    log_warning "Service response slow"
    log_info "Processing data..."
    sleep 1
    
    log_success "Data processing completed"
    log_info "Application finished"
    
    echo
    echo "Log file contents:"
    echo "=================="
    cat "$log_file"
    echo "=================="
    
    # Cleanup
    rm -f "$log_file"
}

# =============================================================================
# Example 3: Deployment Script
# =============================================================================

example_deployment() {
    echo "=== Deployment Script Example ==="
    
    # Configure for deployment logging
    set_log_file "/tmp/deployment.log"
    set_log_level "INFO"
    set_verbose_mode false
    
    deploy_application() {
        log_info "🚀 Starting application deployment"
        
        # Check prerequisites
        log_info "Checking prerequisites..."
        if ! command -v docker >/dev/null 2>&1; then
            log_error "Docker is not installed"
            return 1
        fi
        log_success "✅ Docker is available"
        
        # Build application
        log_info "Building application..."
        sleep 2  # Simulate build time
        if [[ $((RANDOM % 10)) -lt 8 ]]; then  # 80% success rate
            log_success "✅ Application built successfully"
        else
            log_error "❌ Build failed"
            return 1
        fi
        
        # Deploy to staging
        log_info "Deploying to staging environment..."
        sleep 1
        log_success "✅ Deployed to staging"
        
        # Run tests
        log_info "Running integration tests..."
        sleep 2
        if [[ $((RANDOM % 10)) -lt 9 ]]; then  # 90% success rate
            log_success "✅ All tests passed"
        else
            log_warning "⚠️  Some tests failed, but deployment continues"
        fi
        
        # Deploy to production
        log_info "Deploying to production environment..."
        sleep 1
        log_success "✅ Deployed to production"
        
        log_success "🎉 Deployment completed successfully"
        return 0
    }
    
    # Run deployment
    if deploy_application; then
        log_success "Deployment script finished successfully"
    else
        log_error "Deployment script failed"
    fi
    
    echo
    echo "Deployment log:"
    echo "==============="
    cat "/tmp/deployment.log"
    echo "==============="
    
    # Cleanup
    rm -f "/tmp/deployment.log"
}

# =============================================================================
# Example 4: System Monitoring
# =============================================================================

example_monitoring() {
    echo "=== System Monitoring Example ==="
    
    # Configure for monitoring (warnings and errors only to console)
    set_log_file "/tmp/monitoring.log"
    set_log_level "WARNING"
    set_silent_mode false
    
    monitor_system() {
        log_info "Starting system monitoring check"
        
        # Check CPU usage
        local cpu_usage
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' || echo "50")
        cpu_usage=${cpu_usage%.*}  # Remove decimal part
        
        log_debug "CPU usage: ${cpu_usage}%"
        
        if [[ $cpu_usage -gt 80 ]]; then
            log_error "🔥 Critical CPU usage: ${cpu_usage}%"
        elif [[ $cpu_usage -gt 60 ]]; then
            log_warning "⚠️  High CPU usage: ${cpu_usage}%"
        else
            log_info "✅ CPU usage normal: ${cpu_usage}%"
        fi
        
        # Check memory usage
        local mem_usage
        mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}' || echo "30")
        
        log_debug "Memory usage: ${mem_usage}%"
        
        if [[ $mem_usage -gt 90 ]]; then
            log_error "🔥 Critical memory usage: ${mem_usage}%"
        elif [[ $mem_usage -gt 75 ]]; then
            log_warning "⚠️  High memory usage: ${mem_usage}%"
        else
            log_info "✅ Memory usage normal: ${mem_usage}%"
        fi
        
        # Check disk usage
        local disk_usage
        disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' || echo "25")
        
        log_debug "Disk usage: ${disk_usage}%"
        
        if [[ $disk_usage -gt 95 ]]; then
            log_error "🔥 Critical disk usage: ${disk_usage}%"
        elif [[ $disk_usage -gt 85 ]]; then
            log_warning "⚠️  High disk usage: ${disk_usage}%"
        else
            log_info "✅ Disk usage normal: ${disk_usage}%"
        fi
        
        # Simulate some random issues
        if [[ $((RANDOM % 10)) -lt 2 ]]; then  # 20% chance
            log_warning "⚠️  High network latency detected"
        fi
        
        if [[ $((RANDOM % 20)) -lt 1 ]]; then  # 5% chance
            log_error "🔥 Service health check failed"
        fi
        
        log_info "System monitoring check completed"
    }
    
    # Run monitoring for a few cycles
    for i in {1..3}; do
        echo "--- Monitoring cycle $i ---"
        monitor_system
        echo
        sleep 1
    done
    
    echo "Monitoring log (all entries):"
    echo "============================="
    # Show all log entries by temporarily changing level
    set_log_level "DEBUG"
    cat "/tmp/monitoring.log"
    echo "============================="
    
    # Cleanup
    rm -f "/tmp/monitoring.log"
}

# =============================================================================
# Example 5: Error Handling
# =============================================================================

example_error_handling() {
    echo "=== Error Handling Example ==="
    
    # Configure for error handling
    set_log_file "/tmp/error-handling.log"
    set_log_level "DEBUG"
    set_verbose_mode true
    
    # Function that might fail
    risky_operation() {
        local operation="$1"
        local success_rate="$2"
        
        log_debug "Attempting risky operation: $operation"
        
        if [[ $((RANDOM % 100)) -lt $success_rate ]]; then
            log_success "✅ $operation completed successfully"
            return 0
        else
            log_error "❌ $operation failed"
            return 1
        fi
    }
    
    # Error handling with retry logic
    retry_operation() {
        local operation="$1"
        local max_retries=3
        local retry_count=0
        
        log_info "Starting operation: $operation"
        
        while [[ $retry_count -lt $max_retries ]]; do
            if risky_operation "$operation" 60; then  # 60% success rate
                return 0
            else
                ((retry_count++))
                if [[ $retry_count -lt $max_retries ]]; then
                    log_warning "⚠️  Retry $retry_count/$max_retries for: $operation"
                    sleep 1
                else
                    log_error "❌ All retries exhausted for: $operation"
                    return 1
                fi
            fi
        done
    }
    
    # Simulate various operations
    operations=(
        "Database connection"
        "API call to external service"
        "File processing"
        "Cache update"
        "Email notification"
    )
    
    local success_count=0
    local total_count=${#operations[@]}
    
    for operation in "${operations[@]}"; do
        if retry_operation "$operation"; then
            ((success_count++))
        fi
        echo
    done
    
    # Summary
    log_info "Operation summary: $success_count/$total_count successful"
    
    if [[ $success_count -eq $total_count ]]; then
        log_success "🎉 All operations completed successfully"
    elif [[ $success_count -gt 0 ]]; then
        log_warning "⚠️  Some operations failed"
    else
        log_error "❌ All operations failed"
    fi
    
    echo
    echo "Error handling log:"
    echo "==================="
    cat "/tmp/error-handling.log"
    echo "==================="
    
    # Cleanup
    rm -f "/tmp/error-handling.log"
}

# =============================================================================
# Example 6: Custom Format
# =============================================================================

example_custom_format() {
    echo "=== Custom Format Example ==="
    
    # Test different formats
    formats=(
        "[%timestamp%] [%level%] %message%"
        "%level%: %message%"
        "%timestamp% | %level% | %message%"
        "<%level%> %message% (%timestamp%)"
        '{"time":"%timestamp%","level":"%level%","msg":"%message%"}'
    )
    
    for format in "${formats[@]}"; do
        echo "Format: $format"
        set_log_format "$format"
        log_info "This is a test message"
        echo
    done
    
    # Reset to default
    set_log_format "[%timestamp%] [%level%] %message%"
}

# =============================================================================
# Main Function
# =============================================================================

show_help() {
    cat << 'EOF'
Logger Examples

USAGE:
    ./examples/logger-examples.sh [EXAMPLE]

EXAMPLES:
    basic           Basic logging with all levels
    file            File logging demonstration
    deployment      Deployment script example
    monitoring      System monitoring example
    error_handling  Error handling with retries
    custom_format   Custom log format examples
    all             Run all examples

OPTIONS:
    -h, --help      Show this help

EOF
}

main() {
    local example="${1:-}"
    
    case "$example" in
        "basic")
            example_basic
            ;;
        "file"|"file_logging")
            example_file_logging
            ;;
        "deployment"|"deploy")
            example_deployment
            ;;
        "monitoring"|"monitor")
            example_monitoring
            ;;
        "error_handling"|"error"|"retry")
            example_error_handling
            ;;
        "custom_format"|"format")
            example_custom_format
            ;;
        "all")
            example_basic
            echo; echo
            example_file_logging
            echo; echo
            example_deployment
            echo; echo
            example_monitoring
            echo; echo
            example_error_handling
            echo; echo
            example_custom_format
            ;;
        "-h"|"--help"|"help"|"")
            show_help
            ;;
        *)
            echo "Unknown example: $example"
            echo "Use --help for available examples"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
