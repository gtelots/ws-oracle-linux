#!/bin/bash
# Oracle Linux 9 Container Functionality Test Script
# Comprehensive testing of development tools and container functionality
# Following enterprise testing patterns and validation best practices

set -euo pipefail

# =============================================================================
# Configuration and Constants
# =============================================================================

readonly SCRIPT_NAME="$(basename "${0}")"
readonly LOG_PREFIX="[FUNCTIONALITY-TEST]"
readonly TEST_REPORT="/tmp/functionality-test-report.json"
readonly TEST_WORKSPACE="/tmp/functionality-test-workspace"

# Test configuration
readonly TIMEOUT=30
readonly MAX_RETRIES=3

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

setup_test_environment() {
    log "Setting up test environment..."
    mkdir -p "${TEST_WORKSPACE}"
    cd "${TEST_WORKSPACE}"
    
    # Cleanup on exit
    trap 'rm -rf "${TEST_WORKSPACE}"' EXIT
}

# =============================================================================
# Core System Tests
# =============================================================================

test_basic_commands() {
    log "Testing basic system commands..."
    
    local failed_tests=0
    local basic_commands=("ls" "cat" "grep" "awk" "sed" "find" "sort" "uniq" "wc" "head" "tail")
    
    for cmd in "${basic_commands[@]}"; do
        if command -v "${cmd}" &> /dev/null; then
            # Test basic functionality
            if echo "test" | ${cmd} --help &> /dev/null || ${cmd} --version &> /dev/null || ${cmd} /dev/null &> /dev/null; then
                log_success "Command '${cmd}' is working"
            else
                log_error "Command '${cmd}' exists but not functioning properly"
                ((failed_tests++))
            fi
        else
            log_error "Command '${cmd}' is missing"
            ((failed_tests++))
        fi
    done
    
    return $((failed_tests > 0 ? EXIT_CRITICAL : EXIT_SUCCESS))
}

test_modern_cli_tools() {
    log "Testing modern CLI tools..."
    
    local failed_tests=0
    local modern_tools=("bat" "exa" "fd" "rg" "delta")
    
    for tool in "${modern_tools[@]}"; do
        if command -v "${tool}" &> /dev/null; then
            case "${tool}" in
                "bat")
                    echo "test content" | bat --style=plain > /dev/null 2>&1 && \
                        log_success "bat is working" || { log_error "bat functionality test failed"; ((failed_tests++)); }
                    ;;
                "exa")
                    exa /tmp > /dev/null 2>&1 && \
                        log_success "exa is working" || { log_error "exa functionality test failed"; ((failed_tests++)); }
                    ;;
                "fd")
                    fd --version > /dev/null 2>&1 && \
                        log_success "fd is working" || { log_error "fd functionality test failed"; ((failed_tests++)); }
                    ;;
                "rg")
                    echo "test" | rg "test" > /dev/null 2>&1 && \
                        log_success "ripgrep is working" || { log_error "ripgrep functionality test failed"; ((failed_tests++)); }
                    ;;
                "delta")
                    delta --version > /dev/null 2>&1 && \
                        log_success "delta is working" || { log_error "delta functionality test failed"; ((failed_tests++)); }
                    ;;
            esac
        else
            log_warning "Modern tool '${tool}' is not installed"
        fi
    done
    
    return $((failed_tests > 0 ? EXIT_WARNING : EXIT_SUCCESS))
}

# =============================================================================
# Development Language Tests
# =============================================================================

test_python_functionality() {
    log "Testing Python functionality..."
    
    local failed_tests=0
    
    # Test Python interpreter
    if python3 --version &> /dev/null; then
        local python_version
        python_version=$(python3 --version 2>&1 | awk '{print $2}')
        log_success "Python ${python_version} is available"
        
        # Test basic Python functionality
        if python3 -c "print('Hello, Python!')" &> /dev/null; then
            log_success "Python basic functionality works"
        else
            log_error "Python basic functionality failed"
            ((failed_tests++))
        fi
        
        # Test pip
        if pip3 --version &> /dev/null; then
            log_success "pip3 is available"
            
            # Test pip list
            if pip3 list &> /dev/null; then
                log_success "pip3 list functionality works"
            else
                log_warning "pip3 list functionality has issues"
            fi
        else
            log_error "pip3 is not available"
            ((failed_tests++))
        fi
        
        # Test virtual environment creation
        if python3 -m venv test_venv &> /dev/null; then
            log_success "Python virtual environment creation works"
            rm -rf test_venv
        else
            log_warning "Python virtual environment creation failed"
        fi
        
    else
        log_error "Python3 is not available"
        ((failed_tests++))
    fi
    
    return $((failed_tests > 0 ? EXIT_CRITICAL : EXIT_SUCCESS))
}

test_nodejs_functionality() {
    log "Testing Node.js functionality..."
    
    local failed_tests=0
    
    # Test Node.js
    if node --version &> /dev/null; then
        local node_version
        node_version=$(node --version)
        log_success "Node.js ${node_version} is available"
        
        # Test basic Node.js functionality
        if node -e "console.log('Hello, Node.js!')" &> /dev/null; then
            log_success "Node.js basic functionality works"
        else
            log_error "Node.js basic functionality failed"
            ((failed_tests++))
        fi
    else
        log_error "Node.js is not available"
        ((failed_tests++))
    fi
    
    # Test npm
    if npm --version &> /dev/null; then
        local npm_version
        npm_version=$(npm --version)
        log_success "npm ${npm_version} is available"
        
        # Test npm functionality
        if npm list -g --depth=0 &> /dev/null; then
            log_success "npm list functionality works"
        else
            log_warning "npm list functionality has issues"
        fi
    else
        log_error "npm is not available"
        ((failed_tests++))
    fi
    
    return $((failed_tests > 0 ? EXIT_CRITICAL : EXIT_SUCCESS))
}

test_git_functionality() {
    log "Testing Git functionality..."
    
    local failed_tests=0
    
    # Test Git availability
    if git --version &> /dev/null; then
        local git_version
        git_version=$(git --version | awk '{print $3}')
        log_success "Git ${git_version} is available"
        
        # Test Git basic functionality
        if git init test_repo &> /dev/null; then
            cd test_repo
            
            # Configure Git for testing
            git config user.name "Test User" &> /dev/null
            git config user.email "test@example.com" &> /dev/null
            
            # Test basic Git operations
            echo "test file" > test.txt
            if git add test.txt &> /dev/null && \
               git commit -m "Initial commit" &> /dev/null; then
                log_success "Git basic operations work"
            else
                log_error "Git basic operations failed"
                ((failed_tests++))
            fi
            
            cd ..
            rm -rf test_repo
        else
            log_error "Git repository initialization failed"
            ((failed_tests++))
        fi
    else
        log_error "Git is not available"
        ((failed_tests++))
    fi
    
    return $((failed_tests > 0 ? EXIT_CRITICAL : EXIT_SUCCESS))
}

# =============================================================================
# Container and System Tests
# =============================================================================

test_file_system_functionality() {
    log "Testing file system functionality..."
    
    local failed_tests=0
    
    # Test workspace directory
    if [[ -d "${WORKSPACE_DIR:-/workspace}" ]]; then
        if [[ -w "${WORKSPACE_DIR:-/workspace}" ]]; then
            log_success "Workspace directory is writable"
        else
            log_error "Workspace directory is not writable"
            ((failed_tests++))
        fi
    else
        log_warning "Workspace directory does not exist"
    fi
    
    # Test home directory
    if [[ -w "${HOME}" ]]; then
        log_success "Home directory is writable"
    else
        log_error "Home directory is not writable"
        ((failed_tests++))
    fi
    
    # Test temporary directory
    if [[ -w "/tmp" ]]; then
        # Test file creation and manipulation
        local test_file="/tmp/functionality_test_$$"
        if echo "test content" > "${test_file}" && \
           [[ -f "${test_file}" ]] && \
           grep -q "test content" "${test_file}" && \
           rm "${test_file}"; then
            log_success "File system operations work correctly"
        else
            log_error "File system operations failed"
            ((failed_tests++))
        fi
    else
        log_error "Temporary directory is not writable"
        ((failed_tests++))
    fi
    
    return $((failed_tests > 0 ? EXIT_CRITICAL : EXIT_SUCCESS))
}

test_network_functionality() {
    log "Testing network functionality..."
    
    local failed_tests=0
    
    # Test DNS resolution
    if nslookup google.com &> /dev/null; then
        log_success "DNS resolution works"
    else
        log_warning "DNS resolution failed (may be expected in restricted environments)"
    fi
    
    # Test network connectivity (if available)
    if ping -c 1 -W 5 8.8.8.8 &> /dev/null; then
        log_success "Network connectivity available"
    else
        log_warning "Network connectivity limited (may be expected in container environments)"
    fi
    
    # Test localhost connectivity
    if ping -c 1 -W 1 localhost &> /dev/null; then
        log_success "Localhost connectivity works"
    else
        log_error "Localhost connectivity failed"
        ((failed_tests++))
    fi
    
    return $((failed_tests > 0 ? EXIT_WARNING : EXIT_SUCCESS))
}

# =============================================================================
# Integration Tests
# =============================================================================

test_development_workflow() {
    log "Testing complete development workflow..."
    
    local failed_tests=0
    
    # Create a test project
    local project_dir="test_project"
    mkdir -p "${project_dir}"
    cd "${project_dir}"
    
    # Initialize Git repository
    if git init &> /dev/null; then
        git config user.name "Test Developer" &> /dev/null
        git config user.email "dev@test.com" &> /dev/null
        log_success "Git repository initialized"
    else
        log_error "Git repository initialization failed"
        ((failed_tests++))
    fi
    
    # Create a simple Node.js project
    if command -v npm &> /dev/null; then
        cat > package.json <<EOF
{
  "name": "test-project",
  "version": "1.0.0",
  "description": "Test project for functionality testing",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Test passed\""
  }
}
EOF
        
        echo 'console.log("Hello from test project!");' > index.js
        
        if npm test &> /dev/null; then
            log_success "Node.js project workflow works"
        else
            log_warning "Node.js project workflow has issues"
        fi
    fi
    
    # Create a simple Python project
    if command -v python3 &> /dev/null; then
        echo 'print("Hello from Python test project!")' > test.py
        
        if python3 test.py &> /dev/null; then
            log_success "Python project workflow works"
        else
            log_warning "Python project workflow has issues"
        fi
    fi
    
    # Test Git workflow
    if git add . &> /dev/null && \
       git commit -m "Initial test project commit" &> /dev/null; then
        log_success "Git workflow completed successfully"
    else
        log_error "Git workflow failed"
        ((failed_tests++))
    fi
    
    cd ..
    rm -rf "${project_dir}"
    
    return $((failed_tests > 0 ? EXIT_WARNING : EXIT_SUCCESS))
}

# =============================================================================
# Test Report Generation
# =============================================================================

generate_test_report() {
    log "Generating functionality test report..."
    
    local timestamp
    timestamp=$(date -Iseconds)
    
    cat > "${TEST_REPORT}" <<EOF
{
  "timestamp": "${timestamp}",
  "hostname": "$(hostname)",
  "user": "$(whoami)",
  "test_results": {
    "basic_commands": "$(test_basic_commands >/dev/null 2>&1 && echo "PASS" || echo "FAIL")",
    "modern_cli_tools": "$(test_modern_cli_tools >/dev/null 2>&1 && echo "PASS" || echo "FAIL")",
    "python_functionality": "$(test_python_functionality >/dev/null 2>&1 && echo "PASS" || echo "FAIL")",
    "nodejs_functionality": "$(test_nodejs_functionality >/dev/null 2>&1 && echo "PASS" || echo "FAIL")",
    "git_functionality": "$(test_git_functionality >/dev/null 2>&1 && echo "PASS" || echo "FAIL")",
    "filesystem_functionality": "$(test_file_system_functionality >/dev/null 2>&1 && echo "PASS" || echo "FAIL")",
    "network_functionality": "$(test_network_functionality >/dev/null 2>&1 && echo "PASS" || echo "FAIL")",
    "development_workflow": "$(test_development_workflow >/dev/null 2>&1 && echo "PASS" || echo "FAIL")"
  },
  "system_info": {
    "os_release": "$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')",
    "kernel": "$(uname -r)",
    "shell": "${SHELL}",
    "workspace": "${WORKSPACE_DIR:-/workspace}"
  }
}
EOF
    
    log_success "Functionality test report generated: ${TEST_REPORT}"
}

# =============================================================================
# Main Test Process
# =============================================================================

main() {
    log "Starting comprehensive functionality tests..."
    
    setup_test_environment
    
    local overall_status=${EXIT_SUCCESS}
    
    # Run all functionality tests
    local tests=(
        "test_basic_commands"
        "test_modern_cli_tools"
        "test_python_functionality"
        "test_nodejs_functionality"
        "test_git_functionality"
        "test_file_system_functionality"
        "test_network_functionality"
        "test_development_workflow"
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
    
    # Generate test report
    generate_test_report
    
    # Log final status
    case ${overall_status} in
        ${EXIT_SUCCESS})
            log_success "All functionality tests passed successfully"
            ;;
        ${EXIT_WARNING})
            log_warning "Functionality tests completed with warnings"
            ;;
        ${EXIT_CRITICAL})
            log_error "Functionality tests failed with critical issues"
            ;;
    esac
    
    return ${overall_status}
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
