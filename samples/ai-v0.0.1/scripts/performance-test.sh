#!/bin/bash
# Oracle Linux 9 Container Performance Test Script
# Comprehensive performance benchmarking and resource monitoring
# Following enterprise performance testing patterns and best practices

set -euo pipefail

# =============================================================================
# Configuration and Constants
# =============================================================================

readonly SCRIPT_NAME="$(basename "${0}")"
readonly LOG_PREFIX="[PERFORMANCE-TEST]"
readonly PERF_REPORT="/tmp/performance-test-report.json"
readonly BENCHMARK_DIR="/tmp/performance-benchmarks"

# Performance test configuration
readonly CPU_TEST_DURATION=10
readonly MEMORY_TEST_SIZE="100M"
readonly DISK_TEST_SIZE="100M"
readonly NETWORK_TEST_DURATION=5

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

setup_benchmark_environment() {
    log "Setting up performance benchmark environment..."
    mkdir -p "${BENCHMARK_DIR}"
    cd "${BENCHMARK_DIR}"
    
    # Cleanup on exit
    trap 'rm -rf "${BENCHMARK_DIR}"' EXIT
}

# =============================================================================
# System Resource Tests
# =============================================================================

test_cpu_performance() {
    log "Testing CPU performance..."
    
    local cpu_cores
    cpu_cores=$(nproc)
    log "CPU cores available: ${cpu_cores}"
    
    # CPU stress test using dd and compression
    local start_time
    start_time=$(date +%s.%N)
    
    # Generate CPU load
    timeout ${CPU_TEST_DURATION} bash -c '
        for i in {1..4}; do
            dd if=/dev/zero bs=1M count=100 2>/dev/null | gzip > /dev/null &
        done
        wait
    ' 2>/dev/null || true
    
    local end_time
    end_time=$(date +%s.%N)
    local cpu_test_duration
    cpu_test_duration=$(echo "${end_time} - ${start_time}" | bc -l 2>/dev/null || echo "10")
    
    # Get CPU usage during test
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' || echo "unknown")
    
    log_success "CPU performance test completed in ${cpu_test_duration}s"
    log "CPU usage during test: ${cpu_usage}%"
    
    # Store results
    echo "{\"cpu_cores\": ${cpu_cores}, \"test_duration\": ${cpu_test_duration}, \"cpu_usage\": \"${cpu_usage}\"}" > cpu_results.json
    
    return ${EXIT_SUCCESS}
}

test_memory_performance() {
    log "Testing memory performance..."
    
    # Get memory information
    local total_memory
    total_memory=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    local available_memory
    available_memory=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    
    log "Total memory: ${total_memory}MB, Available: ${available_memory}MB"
    
    # Memory allocation test
    local start_time
    start_time=$(date +%s.%N)
    
    # Allocate and write to memory
    if command -v python3 &> /dev/null; then
        python3 -c "
import time
start = time.time()
# Allocate 100MB of memory
data = bytearray(100 * 1024 * 1024)
# Write pattern to memory
for i in range(0, len(data), 4096):
    data[i:i+10] = b'benchmark!'
end = time.time()
print(f'Memory allocation and write: {end - start:.3f}s')
" > memory_test_output.txt 2>&1
        
        local memory_test_result
        memory_test_result=$(grep "Memory allocation" memory_test_output.txt | awk '{print $5}' || echo "unknown")
        log_success "Memory performance test completed: ${memory_test_result}"
    else
        # Fallback memory test using dd
        dd if=/dev/zero of=memory_test bs=1M count=100 2>/dev/null
        sync
        rm -f memory_test
        log_success "Memory performance test completed (fallback method)"
        memory_test_result="fallback"
    fi
    
    local end_time
    end_time=$(date +%s.%N)
    local memory_test_duration
    memory_test_duration=$(echo "${end_time} - ${start_time}" | bc -l 2>/dev/null || echo "unknown")
    
    # Store results
    echo "{\"total_memory_mb\": ${total_memory}, \"available_memory_mb\": ${available_memory}, \"test_duration\": \"${memory_test_duration}\", \"allocation_time\": \"${memory_test_result}\"}" > memory_results.json
    
    return ${EXIT_SUCCESS}
}

test_disk_performance() {
    log "Testing disk I/O performance..."
    
    # Get disk space information
    local disk_total
    disk_total=$(df -BM . | tail -1 | awk '{print $2}' | sed 's/M//')
    local disk_available
    disk_available=$(df -BM . | tail -1 | awk '{print $4}' | sed 's/M//')
    
    log "Disk space - Total: ${disk_total}MB, Available: ${disk_available}MB"
    
    # Sequential write test
    log "Running sequential write test..."
    local write_start
    write_start=$(date +%s.%N)
    
    dd if=/dev/zero of=write_test bs=1M count=100 conv=fsync 2>/dev/null
    
    local write_end
    write_end=$(date +%s.%N)
    local write_duration
    write_duration=$(echo "${write_end} - ${write_start}" | bc -l 2>/dev/null || echo "unknown")
    local write_speed
    write_speed=$(echo "scale=2; 100 / ${write_duration}" | bc -l 2>/dev/null || echo "unknown")
    
    log_success "Sequential write: ${write_speed} MB/s"
    
    # Sequential read test
    log "Running sequential read test..."
    local read_start
    read_start=$(date +%s.%N)
    
    dd if=write_test of=/dev/null bs=1M 2>/dev/null
    
    local read_end
    read_end=$(date +%s.%N)
    local read_duration
    read_duration=$(echo "${read_end} - ${read_start}" | bc -l 2>/dev/null || echo "unknown")
    local read_speed
    read_speed=$(echo "scale=2; 100 / ${read_duration}" | bc -l 2>/dev/null || echo "unknown")
    
    log_success "Sequential read: ${read_speed} MB/s"
    
    # Random I/O test (if available)
    local random_iops="unknown"
    if command -v fio &> /dev/null; then
        log "Running random I/O test with fio..."
        fio --name=random-rw --ioengine=posix_aio --rw=randrw --bs=4k --size=50M --numjobs=1 --runtime=10 --group_reporting --output-format=json > fio_results.json 2>/dev/null || true
        if [[ -f fio_results.json ]]; then
            random_iops=$(jq -r '.jobs[0].read.iops + .jobs[0].write.iops' fio_results.json 2>/dev/null || echo "unknown")
            log_success "Random I/O: ${random_iops} IOPS"
        fi
    fi
    
    # Cleanup
    rm -f write_test fio_results.json
    
    # Store results
    echo "{\"disk_total_mb\": ${disk_total}, \"disk_available_mb\": ${disk_available}, \"write_speed_mbps\": \"${write_speed}\", \"read_speed_mbps\": \"${read_speed}\", \"random_iops\": \"${random_iops}\"}" > disk_results.json
    
    return ${EXIT_SUCCESS}
}

# =============================================================================
# Application Performance Tests
# =============================================================================

test_development_tools_performance() {
    log "Testing development tools performance..."
    
    local tool_results=()
    
    # Git performance test
    if command -v git &> /dev/null; then
        local git_start
        git_start=$(date +%s.%N)
        
        git init test_repo &> /dev/null
        cd test_repo
        
        # Create multiple files and commits
        for i in {1..10}; do
            echo "File content ${i}" > "file${i}.txt"
            git add "file${i}.txt" &> /dev/null
            git -c user.name="Test" -c user.email="test@example.com" commit -m "Commit ${i}" &> /dev/null
        done
        
        local git_end
        git_end=$(date +%s.%N)
        local git_duration
        git_duration=$(echo "${git_end} - ${git_start}" | bc -l 2>/dev/null || echo "unknown")
        
        cd ..
        rm -rf test_repo
        
        log_success "Git operations (10 commits): ${git_duration}s"
        tool_results+=("\"git_10_commits\": \"${git_duration}\"")
    fi
    
    # Node.js performance test
    if command -v node &> /dev/null; then
        local node_start
        node_start=$(date +%s.%N)
        
        node -e "
        const start = Date.now();
        let sum = 0;
        for (let i = 0; i < 1000000; i++) {
            sum += Math.sqrt(i);
        }
        const end = Date.now();
        console.log(\`Node.js computation: \${end - start}ms\`);
        " > node_test_output.txt 2>&1
        
        local node_result
        node_result=$(grep "Node.js computation" node_test_output.txt | awk '{print $3}' || echo "unknown")
        
        local node_end
        node_end=$(date +%s.%N)
        local node_duration
        node_duration=$(echo "${node_end} - ${node_start}" | bc -l 2>/dev/null || echo "unknown")
        
        log_success "Node.js performance test: ${node_result}"
        tool_results+=("\"nodejs_computation\": \"${node_result}\"")
    fi
    
    # Python performance test
    if command -v python3 &> /dev/null; then
        local python_start
        python_start=$(date +%s.%N)
        
        python3 -c "
import time
import math
start = time.time()
sum_val = sum(math.sqrt(i) for i in range(1000000))
end = time.time()
print(f'Python computation: {(end - start) * 1000:.0f}ms')
" > python_test_output.txt 2>&1
        
        local python_result
        python_result=$(grep "Python computation" python_test_output.txt | awk '{print $3}' || echo "unknown")
        
        local python_end
        python_end=$(date +%s.%N)
        local python_duration
        python_duration=$(echo "${python_end} - ${python_start}" | bc -l 2>/dev/null || echo "unknown")
        
        log_success "Python performance test: ${python_result}"
        tool_results+=("\"python_computation\": \"${python_result}\"")
    fi
    
    # Combine results
    local tools_json
    tools_json=$(IFS=','; echo "{${tool_results[*]}}")
    echo "${tools_json}" > tools_results.json
    
    return ${EXIT_SUCCESS}
}

test_container_overhead() {
    log "Testing container overhead and resource usage..."
    
    # Get container resource limits (if available)
    local memory_limit="unlimited"
    local cpu_limit="unlimited"
    
    if [[ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]]; then
        local mem_limit_bytes
        mem_limit_bytes=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || echo "0")
        if [[ ${mem_limit_bytes} -lt 9223372036854775807 ]]; then
            memory_limit=$((mem_limit_bytes / 1024 / 1024))
        fi
    fi
    
    # Get current resource usage
    local current_memory_usage
    current_memory_usage=$(free -m | awk 'NR==2{printf "%.0f", $3}')
    
    local current_cpu_usage
    current_cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' || echo "0")
    
    # Get process count
    local process_count
    process_count=$(ps aux | wc -l)
    
    # Get load average
    local load_average
    load_average=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    log "Container resource usage:"
    log "  Memory limit: ${memory_limit}MB"
    log "  Memory usage: ${current_memory_usage}MB"
    log "  CPU usage: ${current_cpu_usage}%"
    log "  Process count: ${process_count}"
    log "  Load average: ${load_average}"
    
    # Store results
    echo "{\"memory_limit_mb\": \"${memory_limit}\", \"memory_usage_mb\": ${current_memory_usage}, \"cpu_usage_percent\": \"${current_cpu_usage}\", \"process_count\": ${process_count}, \"load_average\": \"${load_average}\"}" > container_results.json
    
    return ${EXIT_SUCCESS}
}

# =============================================================================
# Performance Report Generation
# =============================================================================

generate_performance_report() {
    log "Generating performance test report..."
    
    local timestamp
    timestamp=$(date -Iseconds)
    
    # Combine all results
    local cpu_results="{}"
    local memory_results="{}"
    local disk_results="{}"
    local tools_results="{}"
    local container_results="{}"
    
    [[ -f cpu_results.json ]] && cpu_results=$(cat cpu_results.json)
    [[ -f memory_results.json ]] && memory_results=$(cat memory_results.json)
    [[ -f disk_results.json ]] && disk_results=$(cat disk_results.json)
    [[ -f tools_results.json ]] && tools_results=$(cat tools_results.json)
    [[ -f container_results.json ]] && container_results=$(cat container_results.json)
    
    cat > "${PERF_REPORT}" <<EOF
{
  "timestamp": "${timestamp}",
  "hostname": "$(hostname)",
  "user": "$(whoami)",
  "system_info": {
    "os_release": "$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')",
    "kernel": "$(uname -r)",
    "architecture": "$(uname -m)",
    "uptime": "$(uptime -p)"
  },
  "performance_results": {
    "cpu": ${cpu_results},
    "memory": ${memory_results},
    "disk": ${disk_results},
    "development_tools": ${tools_results},
    "container_overhead": ${container_results}
  },
  "benchmark_summary": {
    "test_duration": "${CPU_TEST_DURATION}s",
    "memory_test_size": "${MEMORY_TEST_SIZE}",
    "disk_test_size": "${DISK_TEST_SIZE}",
    "timestamp_start": "$(date -Iseconds)"
  }
}
EOF
    
    log_success "Performance test report generated: ${PERF_REPORT}"
}

# =============================================================================
# Main Performance Test Process
# =============================================================================

main() {
    log "Starting comprehensive performance tests..."
    
    setup_benchmark_environment
    
    local overall_status=${EXIT_SUCCESS}
    
    # Run all performance tests
    local tests=(
        "test_cpu_performance"
        "test_memory_performance"
        "test_disk_performance"
        "test_development_tools_performance"
        "test_container_overhead"
    )
    
    for test in "${tests[@]}"; do
        log "Running ${test}..."
        if ! ${test}; then
            local exit_code=$?
            if [[ ${exit_code} -eq ${EXIT_CRITICAL} ]]; then
                overall_status=${EXIT_CRITICAL}
            elif [[ ${exit_code} -eq ${EXIT_WARNING} && ${overall_status} -eq ${EXIT_SUCCESS} ]]; then
                overall_status=${EXIT_WARNING}
            fi
        fi
    done
    
    # Generate performance report
    generate_performance_report
    
    # Log final status
    case ${overall_status} in
        ${EXIT_SUCCESS})
            log_success "All performance tests completed successfully"
            ;;
        ${EXIT_WARNING})
            log_warning "Performance tests completed with warnings"
            ;;
        ${EXIT_CRITICAL})
            log_error "Performance tests failed with critical issues"
            ;;
    esac
    
    return ${overall_status}
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
