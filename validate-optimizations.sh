#!/bin/bash
# =============================================================================
# Dockerfile Optimization Validation Script
# =============================================================================
# DESCRIPTION: Validates the optimizations and improvements made to the
#              Oracle Linux 9 development container Dockerfile
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# VERSION: 1.0.0
# =============================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly DOCKERFILE_PATH="./Dockerfile"
readonly IMAGE_NAME="ws-oracle-linux"
readonly TEST_TAG="validation-test"
readonly FULL_IMAGE_NAME="${IMAGE_NAME}:${TEST_TAG}"

# Validation results
declare -a VALIDATION_RESULTS=()
declare -i TOTAL_TESTS=0
declare -i PASSED_TESTS=0

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

add_test_result() {
    local test_name="$1"
    local result="$2"
    local details="${3:-}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [[ "$result" == "PASS" ]]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "✓ $test_name"
        [[ -n "$details" ]] && echo "  $details"
    else
        log_error "✗ $test_name"
        [[ -n "$details" ]] && echo "  $details"
    fi
    
    VALIDATION_RESULTS+=("$test_name: $result")
}

# =============================================================================
# DOCKERFILE VALIDATION FUNCTIONS
# =============================================================================

validate_dockerfile_structure() {
    log_info "Validating Dockerfile structure..."
    
    # Check if Dockerfile exists
    if [[ ! -f "$DOCKERFILE_PATH" ]]; then
        add_test_result "Dockerfile exists" "FAIL" "Dockerfile not found at $DOCKERFILE_PATH"
        return 1
    fi
    add_test_result "Dockerfile exists" "PASS"
    
    # Check for syntax version
    if grep -q "syntax=docker/dockerfile:1.7-labs" "$DOCKERFILE_PATH"; then
        add_test_result "Modern Dockerfile syntax" "PASS" "Using BuildKit syntax"
    else
        add_test_result "Modern Dockerfile syntax" "FAIL" "Missing or outdated syntax directive"
    fi
    
    # Check for comprehensive comments
    local comment_lines=$(grep -c "^#" "$DOCKERFILE_PATH" || true)
    if [[ $comment_lines -gt 100 ]]; then
        add_test_result "Comprehensive documentation" "PASS" "$comment_lines comment lines found"
    else
        add_test_result "Comprehensive documentation" "FAIL" "Only $comment_lines comment lines found"
    fi
    
    # Check for section headers
    local section_headers=$(grep -c "^# =====" "$DOCKERFILE_PATH" || true)
    if [[ $section_headers -ge 5 ]]; then
        add_test_result "Section organization" "PASS" "$section_headers major sections found"
    else
        add_test_result "Section organization" "FAIL" "Only $section_headers major sections found"
    fi
}

validate_build_optimization() {
    log_info "Validating build optimizations..."
    
    # Check for cache mounts
    if grep -q "mount=type=cache" "$DOCKERFILE_PATH"; then
        add_test_result "Build cache mounts" "PASS" "Cache mounts implemented"
    else
        add_test_result "Build cache mounts" "FAIL" "No cache mounts found"
    fi
    
    # Check for consolidated RUN commands
    local run_commands=$(grep -c "^RUN" "$DOCKERFILE_PATH" || true)
    if [[ $run_commands -le 20 ]]; then
        add_test_result "Layer optimization" "PASS" "$run_commands RUN commands (optimized)"
    else
        add_test_result "Layer optimization" "FAIL" "$run_commands RUN commands (too many)"
    fi
    
    # Check for build arguments
    local build_args=$(grep -c "^ARG" "$DOCKERFILE_PATH" || true)
    if [[ $build_args -ge 10 ]]; then
        add_test_result "Build flexibility" "PASS" "$build_args build arguments defined"
    else
        add_test_result "Build flexibility" "FAIL" "Only $build_args build arguments found"
    fi
}

validate_security_features() {
    log_info "Validating security features..."
    
    # Check for non-root user
    if grep -q "USER \${USER_NAME}" "$DOCKERFILE_PATH"; then
        add_test_result "Non-root user" "PASS" "Container runs as non-root user"
    else
        add_test_result "Non-root user" "FAIL" "Container may run as root"
    fi
    
    # Check for SSH security configuration
    if grep -q "Port 2222" "$DOCKERFILE_PATH" || grep -q "SSH_PORT.*2222" "$DOCKERFILE_PATH"; then
        add_test_result "SSH security port" "PASS" "SSH configured on non-standard port"
    else
        add_test_result "SSH security port" "WARNING" "SSH port configuration not found"
    fi
    
    # Check for security updates
    if grep -q "update-minimal --security" "$DOCKERFILE_PATH"; then
        add_test_result "Security updates" "PASS" "Security updates prioritized"
    else
        add_test_result "Security updates" "FAIL" "Security updates not prioritized"
    fi
}

validate_ssh_deployment() {
    log_info "Validating SSH deployment script..."
    
    local ssh_script="resources/prebuildfs/opt/laragis/tools/ssh-deployment.sh"
    
    # Check if SSH deployment script exists
    if [[ -f "$ssh_script" ]]; then
        add_test_result "SSH deployment script exists" "PASS"
        
        # Check if script is executable
        if [[ -x "$ssh_script" ]]; then
            add_test_result "SSH script executable" "PASS"
        else
            add_test_result "SSH script executable" "FAIL" "Script is not executable"
        fi
        
        # Check for key functions
        if grep -q "configure_ssh_server" "$ssh_script"; then
            add_test_result "SSH server configuration" "PASS"
        else
            add_test_result "SSH server configuration" "FAIL"
        fi
        
        if grep -q "configure_ssh_client" "$ssh_script"; then
            add_test_result "SSH client configuration" "PASS"
        else
            add_test_result "SSH client configuration" "FAIL"
        fi
        
        if grep -q "generate_user_ssh_keys" "$ssh_script"; then
            add_test_result "SSH key management" "PASS"
        else
            add_test_result "SSH key management" "FAIL"
        fi
    else
        add_test_result "SSH deployment script exists" "FAIL" "Script not found at $ssh_script"
    fi
}

validate_package_strategy() {
    log_info "Validating package installation strategy..."
    
    # Check for fallback mechanism
    if grep -q "USE_PACKAGE_SCRIPTS" "$DOCKERFILE_PATH"; then
        add_test_result "Package fallback strategy" "PASS" "Fallback mechanism implemented"
    else
        add_test_result "Package fallback strategy" "FAIL" "No fallback mechanism found"
    fi
    
    # Check for conditional tool installation
    if grep -q "INSTALL_.*==.*true" "$DOCKERFILE_PATH"; then
        add_test_result "Conditional tool installation" "PASS" "Conditional logic implemented"
    else
        add_test_result "Conditional tool installation" "FAIL" "No conditional installation found"
    fi
    
    # Check for comprehensive cleanup
    if grep -q "dnf clean all" "$DOCKERFILE_PATH" && grep -q "/usr/share/doc" "$DOCKERFILE_PATH"; then
        add_test_result "Comprehensive cleanup" "PASS" "Cleanup includes documentation removal"
    else
        add_test_result "Comprehensive cleanup" "FAIL" "Cleanup may be incomplete"
    fi
}

# =============================================================================
# BUILD VALIDATION FUNCTIONS
# =============================================================================

validate_build_process() {
    log_info "Validating build process..."
    
    # Test basic build
    log_info "Testing basic build (this may take several minutes)..."
    if docker build -t "$FULL_IMAGE_NAME" . >/dev/null 2>&1; then
        add_test_result "Basic build success" "PASS" "Image built successfully"
        
        # Test image size
        local image_size=$(docker images "$FULL_IMAGE_NAME" --format "{{.Size}}" | head -1)
        add_test_result "Image created" "PASS" "Image size: $image_size"
        
        # Test image layers
        local layer_count=$(docker history "$FULL_IMAGE_NAME" --format "{{.ID}}" | wc -l)
        if [[ $layer_count -le 25 ]]; then
            add_test_result "Layer count optimization" "PASS" "$layer_count layers (optimized)"
        else
            add_test_result "Layer count optimization" "WARNING" "$layer_count layers (could be optimized)"
        fi
        
    else
        add_test_result "Basic build success" "FAIL" "Build failed"
        return 1
    fi
}

validate_runtime_functionality() {
    log_info "Validating runtime functionality..."
    
    # Test container startup
    local container_id
    if container_id=$(docker run -d "$FULL_IMAGE_NAME" sleep 30 2>/dev/null); then
        add_test_result "Container startup" "PASS" "Container started successfully"
        
        # Test user configuration
        local user_info
        if user_info=$(docker exec "$container_id" id 2>/dev/null); then
            if echo "$user_info" | grep -q "uid=1000"; then
                add_test_result "Non-root user runtime" "PASS" "Running as UID 1000"
            else
                add_test_result "Non-root user runtime" "FAIL" "Not running as expected user"
            fi
        fi
        
        # Test workspace directory
        if docker exec "$container_id" test -d /workspace 2>/dev/null; then
            add_test_result "Workspace directory" "PASS" "Workspace directory exists"
        else
            add_test_result "Workspace directory" "FAIL" "Workspace directory missing"
        fi
        
        # Cleanup
        docker stop "$container_id" >/dev/null 2>&1 || true
        docker rm "$container_id" >/dev/null 2>&1 || true
    else
        add_test_result "Container startup" "FAIL" "Container failed to start"
    fi
}

# =============================================================================
# MAIN VALIDATION FUNCTION
# =============================================================================

cleanup() {
    log_info "Cleaning up test resources..."
    docker rmi "$FULL_IMAGE_NAME" >/dev/null 2>&1 || true
}

main() {
    log_info "Starting Dockerfile optimization validation..."
    echo "========================================================"
    
    # Dockerfile validation
    validate_dockerfile_structure
    validate_build_optimization
    validate_security_features
    validate_ssh_deployment
    validate_package_strategy
    
    # Build and runtime validation
    if command -v docker >/dev/null 2>&1; then
        validate_build_process
        validate_runtime_functionality
    else
        log_warning "Docker not available, skipping build validation"
    fi
    
    # Summary
    echo "========================================================"
    log_info "Validation Summary:"
    echo "  Total Tests: $TOTAL_TESTS"
    echo "  Passed: $PASSED_TESTS"
    echo "  Failed: $((TOTAL_TESTS - PASSED_TESTS))"
    echo "  Success Rate: $(( (PASSED_TESTS * 100) / TOTAL_TESTS ))%"
    
    if [[ $PASSED_TESTS -eq $TOTAL_TESTS ]]; then
        log_success "🎉 All validations passed! Dockerfile optimization is successful."
        return 0
    elif [[ $PASSED_TESTS -ge $((TOTAL_TESTS * 80 / 100)) ]]; then
        log_warning "⚠️  Most validations passed. Minor issues may need attention."
        return 0
    else
        log_error "❌ Validation failed. Significant issues need to be addressed."
        return 1
    fi
}

# Trap cleanup on exit
trap cleanup EXIT

# Execute main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
