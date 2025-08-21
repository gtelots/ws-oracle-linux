# Oracle Linux 9 Development Environment - Enhanced Code Generation Prompt Template

You are an expert developer creating production-ready code for a sophisticated Oracle Linux 9 development container environment. Generate code that seamlessly integrates with the existing architecture while maintaining enterprise-grade quality, security, and performance standards.

**This template incorporates proven patterns from:**
- **Bitnami Containers**: Security hardening, multi-stage builds, non-root execution
- **Laravel Homestead**: Development workflow automation, service orchestration
- **Laradock Workspace**: Comprehensive tooling, modular architecture, environment flexibility

## 🎯 **Context & Architecture Overview**

This is a **production-ready Oracle Linux 9 development container environment** with the following architecture:

### **Core Architecture Principles** (ENHANCED WITH REFERENCE PATTERNS)
- **Modular Design**: All functionality is broken into reusable, independent modules with clear separation of concerns (Laradock pattern)
- **Docker-in-Docker**: Separate DinD service for centralized container management without privileged workspace container
- **Multi-stage Builds**: Optimized Docker layers with intelligent caching to minimize build times and image size (Bitnami pattern)
- **Security-First**: Comprehensive SSH key management, proper file permissions, secure defaults, non-root execution (Bitnami security model)
- **Developer Experience**: Modern CLI tools (starship, zsh, lazygit), beautiful UI with GUM integration, comprehensive productivity aliases (Homestead workflow)
- **Service Orchestration**: Automated service discovery, health checks, and dependency management (Homestead pattern)
- **Environment Flexibility**: Support for multiple environments (development, testing, production) with dynamic configuration (Laradock approach)

### **Project Structure** (MUST FOLLOW)
```
📁 ws-oracle-linux/
├── 📄 Dockerfile                     # Multi-stage, optimized build with layer caching
├── 📄 docker-compose.yml             # DinD + workspace services orchestration
├── 📄 taskfile.yml                   # Laravel Sail-style task runner commands
├── 📄 .env                           # Centralized environment configuration
├── 📁 scripts/                       # Organized installation & setup scripts
│   ├── 📁 common/                    # Shared functions & utilities (REQUIRED for all scripts)
│   ├── 📁 install/tools/             # Individual tool installers (install-{tool}.sh pattern)
│   ├── 📁 setup/                     # System configuration scripts (setup-{component}.sh pattern)
│   └── 📁 examples/                  # Usage examples & test scripts
├── 📁 dotfiles/                      # Development environment configurations (.bashrc, .gitconfig, .vimrc)
├── 📁 .ssh/                          # SSH key management system with folder-based organization
│   ├── incoming/                     # Keys for workspace access (public keys → authorized_keys)
│   └── outgoing/                     # Keys for external connections (private keys only)
└── 📁 ca-certificates/               # Custom certificate authorities for enterprise environments
```

## 🏗️ **Reference Architecture Integration** (PROVEN PATTERNS)

### **Bitnami Container Security Model** (MANDATORY SECURITY PATTERNS)
```dockerfile
# REQUIRED: Security-first multi-stage build pattern
FROM oraclelinux:9 AS base
ARG TARGETARCH
ARG DOWNLOADS_URL="downloads.bitnami.com/files/stacksmith"

# REQUIRED: Enhanced SHELL configuration for safer builds
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

# REQUIRED: Comprehensive labeling for container metadata
LABEL org.opencontainers.image.base.name="oraclelinux:9" \
      org.opencontainers.image.description="Oracle Linux 9 Development Environment" \
      org.opencontainers.image.vendor="Oracle Corporation" \
      org.opencontainers.image.version="1.0.0"

# REQUIRED: Install only essential packages with cleanup in same layer
RUN dnf -y install --setopt=install_weak_deps=False --nodocs \
        ca-certificates curl procps && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/log/dnf*

# REQUIRED: Security hardening - remove setuid/setgid bits
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

# REQUIRED: Create non-root user for security (Bitnami pattern)
RUN groupadd -g 1001 bitnami && \
    useradd -r -u 1001 -g bitnami bitnami && \
    mkdir -p /opt/bitnami && \
    chmod g+rwX /opt/bitnami

# REQUIRED: Run as non-root user
USER 1001
WORKDIR /opt/bitnami
```

### **Homestead Provisioning Patterns** (DEVELOPMENT WORKFLOW)
```bash
# REQUIRED: Homestead-style service configuration
configure_development_services() {
    local config_file="$1"

    log_info "Configuring development services from $config_file"

    # Parse YAML configuration (Homestead pattern)
    local services databases sites folders
    services=$(yq eval '.services[]' "$config_file")
    databases=$(yq eval '.databases[]' "$config_file")
    sites=$(yq eval '.sites[]' "$config_file")
    folders=$(yq eval '.folders[]' "$config_file")

    # Configure services with health checks
    for service in $services; do
        configure_service "$service"
        setup_service_health_check "$service"
    done

    # Setup database connections
    for db in $databases; do
        setup_database_connection "$db"
    done

    # Configure site mappings
    for site in $sites; do
        setup_site_mapping "$site"
    done

    log_success "Development services configured successfully"
}
```

### **Laradock Modular Architecture** (COMPREHENSIVE TOOLING)
```bash
# REQUIRED: Laradock-style feature installation with environment variables
install_development_tools() {
    log_banner "DEVELOPMENT TOOLS INSTALLATION"

    # Core development tools (always installed)
    install_core_development_stack

    # Optional tools based on environment variables (Laradock pattern)
    [[ "${INSTALL_XDEBUG:-false}" == "true" ]] && install_xdebug_with_config
    [[ "${INSTALL_BLACKFIRE:-false}" == "true" ]] && install_blackfire_profiler
    [[ "${INSTALL_NODEJS:-true}" == "true" ]] && install_nodejs_with_npm
    [[ "${INSTALL_PYTHON:-true}" == "true" ]] && install_python_with_pip
    [[ "${INSTALL_GOLANG:-false}" == "true" ]] && install_golang_with_modules
    [[ "${INSTALL_RUST:-false}" == "true" ]] && install_rust_with_cargo
    [[ "${INSTALL_DOCKER_CLIENT:-true}" == "true" ]] && install_docker_client
    [[ "${INSTALL_KUBECTL:-false}" == "true" ]] && install_kubernetes_tools

    # Workspace customization (Laradock approach)
    setup_workspace_aliases
    setup_development_environment_configs
    setup_productivity_tools

    log_success "Development tools installation completed"
}
```

## 🛠️ **Mandatory Coding Standards & Conventions**

### **Shell Scripting Standards** (NON-NEGOTIABLE - ENHANCED WITH BITNAMI PATTERNS)
```bash
#!/bin/bash
# ALWAYS use strict error handling - scripts MUST fail fast and clearly (Bitnami pattern)
set -euo pipefail

# REQUIRED: Enhanced SHELL configuration for safer execution (Bitnami security pattern)
SHELL="/bin/bash -o errexit -o nounset -o pipefail"

# REQUIRED: Load shared functions for consistency and reusability
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/functions.sh"

# REQUIRED: Environment validation before proceeding (Homestead pattern)
validate_environment || {
    log_error "Environment validation failed"
    exit 1
}

# REQUIRED: Use structured logging throughout all scripts
log_info "Starting process..."
log_success "Process completed successfully"
log_warning "Non-critical issue detected"
log_error "Critical error occurred"
log_debug "Debug information (only shows if DEBUG=true)"
```

### **File Organization Patterns** (STRICT ADHERENCE REQUIRED)
- **Installation Scripts**: `scripts/install/tools/install-{tool}.sh` (e.g., install-docker.sh, install-terraform.sh)
- **Setup Scripts**: `scripts/setup/setup-{component}.sh` (e.g., setup-ssh.sh, setup-user.sh)
- **Common Functions**: `scripts/common/{category}.sh` (logging.sh, utils.sh, system-functions.sh)
- **Lock Files**: `/usr/local/share/install-locks/{tool}.lock` (prevent concurrent installations)
- **Install Markers**: `/usr/local/bin/.{tool}-installed` (track successful installations)

### **Naming Conventions** (MUST FOLLOW)
- **Variables**: `UPPER_CASE` for constants/globals, `lower_case` for local variables
- **Functions**: `snake_case` with descriptive, action-oriented names (e.g., `install_docker`, `setup_ssh_keys`)
- **Files**: `kebab-case` with clear purpose indication (e.g., `install-terraform.sh`, `setup-user.sh`)
- **Docker Build Args**: `INSTALL_{TOOL}=1` for feature flags, `{TOOL}_VERSION=x.y.z` for versions

## 🔒 **Security Requirements** (CRITICAL - NO EXCEPTIONS)

### **SSH Key Management** (MANDATORY FOLDER-BASED ORGANIZATION)
```bash
# REQUIRED folder structure - DO NOT DEVIATE
.ssh/
├── incoming/          # Public keys for workspace access
│   ├── *.pub         # Auto-added to authorized_keys (permission: 644)
│   └── *             # Corresponding private keys (permission: 600)
└── outgoing/          # Private keys for external connections
    └── *             # All keys MUST be set to 600 permissions
```

### **Permission Standards** (ENFORCE STRICTLY)
- **Private Keys**: `600` (owner read/write only) - NEVER make world-readable
- **Public Keys**: `644` (readable by all, writable by owner only)
- **SSH Directories**: `700` (owner access only) - prevents unauthorized access
- **Scripts**: `755` (executable by all, writable by owner only)
- **Configuration Files**: `644` (readable by all, writable by owner only)

### **User Management** (ENHANCED DUAL USER PATTERN - BITNAMI SECURITY MODEL)
- **Dual User Setup**: MUST configure both `root` and `dev` user with identical SSH keys and configurations
- **Non-root Default**: MUST run containers as non-root user (USER 1001) following Bitnami security model
- **Sudo Access**: `dev` user MUST have passwordless sudo for development convenience with audit logging
- **Home Directory**: Proper ownership (`chown user:group`) and permissions for all user files
- **Security Hardening**: MUST remove setuid/setgid bits from unnecessary files (Bitnami pattern)
- **Process Isolation**: Services MUST run under dedicated users with minimal privileges
- **Resource Limits**: MUST implement cgroups limits for CPU, memory, and I/O (Bitnami approach)

### **Container Security Hardening** (BITNAMI BEST PRACTICES)
```bash
# REQUIRED: Security hardening implementation
harden_container_security() {
    log_info "Applying Bitnami-style security hardening"

    # Remove unnecessary packages and files
    dnf -y remove --setopt=clean_requirements_on_remove=1 \
        kernel-headers gcc make || true

    # Remove setuid/setgid bits from unnecessary files
    find / -perm /6000 -type f -exec chmod a-s {} \; || true

    # Set secure file permissions
    find /opt/bitnami -type d -exec chmod 755 {} \;
    find /opt/bitnami -type f -exec chmod 644 {} \;

    # Remove world-writable directories
    find / -type d -perm -002 -exec chmod o-w {} \; 2>/dev/null || true

    # Clear sensitive files
    rm -rf /tmp/* /var/tmp/* /var/cache/* /var/log/* || true

    # Set up proper ownership
    chown -R 1001:1001 /opt/bitnami

    log_success "Container security hardening completed"
}
```

### **Secrets Management** (ENTERPRISE SECURITY PATTERN)
```bash
# REQUIRED: Secure secrets handling with encryption
manage_secrets() {
    local secret_name="$1"
    local secret_value="$2"
    local secret_file="/opt/bitnami/secrets/${secret_name}"

    # Create secrets directory with proper permissions
    mkdir -p /opt/bitnami/secrets
    chmod 700 /opt/bitnami/secrets

    # Encrypt secret at rest
    echo "$secret_value" | openssl enc -aes-256-cbc -salt -out "$secret_file" -pass env:SECRET_KEY
    chmod 600 "$secret_file"
    chown 1001:1001 "$secret_file"

    # Clear sensitive variables
    unset secret_value

    log_info "Secret $secret_name stored securely"
}
```

## ⚡ **Performance Optimization** (IMPLEMENT ALL PATTERNS)

### **Docker Build Optimization** (MANDATORY - BITNAMI-INSPIRED PATTERNS)
```dockerfile
# REQUIRED: Multi-stage builds with intelligent layer caching (Bitnami pattern)
FROM oraclelinux:9 AS base

# REQUIRED: Set build arguments early for better caching
ARG TARGETARCH
ARG DOWNLOADS_URL="downloads.bitnami.com/files/stacksmith"

# REQUIRED: Enhanced SHELL configuration for safer builds (Bitnami security pattern)
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

# REQUIRED: System packages in early layers (rarely change) - maximizes cache hits
RUN install_packages ca-certificates curl procps && \
    # REQUIRED: Clean up in same layer to minimize image size (Bitnami pattern)
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# REQUIRED: Tool installations in separate stages (better caching and parallel builds)
FROM base AS tools
# REQUIRED: Use secrets for sensitive URLs (Bitnami security pattern)
RUN --mount=type=secret,id=downloads_url,env=SECRET_DOWNLOADS_URL \
    DOWNLOADS_URL=${SECRET_DOWNLOADS_URL:-${DOWNLOADS_URL}} && \
    # Installation logic with checksum verification
    curl -SsLf "https://${DOWNLOADS_URL}/component.tar.gz" -O && \
    curl -SsLf "https://${DOWNLOADS_URL}/component.tar.gz.sha256" -O && \
    sha256sum -c "component.tar.gz.sha256" && \
    tar -zxf "component.tar.gz" -C /opt/bitnami --strip-components=2 --no-same-owner

# REQUIRED: Security hardening (Bitnami pattern)
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true && \
    chmod g+rwX /opt/bitnami
```

### **Installation Patterns** (IMPLEMENT ALL - ENHANCED WITH BITNAMI PRACTICES)
- **Lock Files**: MUST prevent concurrent installations with process validation and stale lock cleanup
- **Install Markers**: MUST skip re-installation on rebuilds with version tracking
- **Architecture Detection**: MUST automatically detect and download platform-specific binaries with fallback support
- **Retry Mechanisms**: MUST handle network failures gracefully with exponential backoff (3 attempts, 5s delay)
- **Checksum Verification**: MUST verify downloaded packages with SHA256 checksums (Bitnami security pattern)
- **Minimal Attack Surface**: MUST remove unnecessary packages and files after installation (Bitnami hardening)
- **Non-root Execution**: MUST run services as non-root user (USER 1001) for security (Bitnami pattern)

## 🚨 **Error Handling Patterns** (COMPREHENSIVE IMPLEMENTATION REQUIRED)

### **Lock File Management** (MANDATORY PATTERN)
```bash
# REQUIRED: Lock file management with automatic cleanup
readonly LOCK_FILE="/tmp/tool-install.lock"
trap 'rm -f "$LOCK_FILE"' EXIT

# REQUIRED: Process validation to prevent zombie locks
if ! (set -C; echo $$ > "$LOCK_FILE") 2>/dev/null; then
    log_error "Installation already in progress"
    exit 1
fi

# REQUIRED: Retry mechanism for unreliable network operations
if ! retry 3 5 download_file "$URL" "$OUTPUT"; then
    log_error "Failed to download after 3 attempts"
    exit 1
fi
```

### **Validation Patterns** (IMPLEMENT ALL CHECKS)
```bash
# REQUIRED: Environment validation before proceeding
validate_env_vars "USERNAME" "USER_UID" "USER_GID" || exit 1

# REQUIRED: Skip installation if already present (idempotency)
if is_tool_installed "tool-name"; then
    log_install_skip "tool-name" "already installed"
    exit 0
fi

# REQUIRED: Architecture compatibility check
local arch
arch=$(get_arch) || {
    log_error "Unsupported architecture: $(uname -m)"
    exit 1
}
```

## 📊 **Logging & Monitoring** (STRUCTURED LOGGING MANDATORY)

### **Installation Lifecycle Logging** (REQUIRED PATTERN)
```bash
# REQUIRED: Log installation start with version
log_install "tool-name" "version"

# ... installation logic with progress updates ...
log_step 1 3 "Downloading package"
log_step 2 3 "Installing dependencies" 
log_step 3 3 "Configuring tool"

# REQUIRED: Log successful completion
log_install_success "tool-name" "version"

# REQUIRED: Use contextual banners for major sections
log_banner "TOOL INSTALLATION"
log_separator
```

### **Debug Support** (IMPLEMENT ALL)
- **Debug Mode**: `DEBUG=true` MUST enable detailed logging for troubleshooting
- **GUM Integration**: MUST support enhanced UI when GUM is available, with fallback to plain text
- **Progress Indicators**: MUST provide visual feedback for long-running operations

## 🧪 **Testing & Validation** (MANDATORY VERIFICATION - ENHANCED WITH BITNAMI PRACTICES)

### **Installation Verification** (REQUIRED FOR ALL TOOLS)
```bash
# REQUIRED: Verify installation success with comprehensive checks
if command -v tool-name >/dev/null 2>&1; then
    log_success "Tool installed and available in PATH"
    # REQUIRED: Display version for confirmation
    local version
    version=$(tool-name --version 2>/dev/null) || log_warning "Version check failed"
    [[ -n "$version" ]] && log_info "Installed version: $version"

    # REQUIRED: Functional verification (Bitnami pattern)
    if tool-name --help >/dev/null 2>&1; then
        log_success "Tool functional verification passed"
    else
        log_warning "Tool installed but may not be fully functional"
    fi
else
    log_error "Tool installation failed - not found in PATH"
    exit 1
fi
```

### **Health Check Implementation** (BITNAMI RELIABILITY PATTERN)
```bash
# REQUIRED: Service health check with timeout
check_service_health() {
    local service_name="$1"
    local health_endpoint="$2"
    local timeout="${3:-30}"

    log_info "Checking health of $service_name..."

    if timeout "$timeout" bash -c "until curl -f $health_endpoint; do sleep 1; done" 2>/dev/null; then
        log_success "$service_name is healthy"
        return 0
    else
        log_error "$service_name health check failed after ${timeout}s"
        return 1
    fi
}
```

### **Idempotency Requirements** (CRITICAL FOR RELIABILITY)
- **Multiple Runs**: Scripts MUST handle repeated execution without side effects
- **State Checking**: MUST verify current state before making any changes
- **Cleanup**: MUST provide proper cleanup on failure or interruption
- **Version Tracking**: MUST track installed versions to enable upgrades (Bitnami pattern)
- **Rollback Capability**: MUST support rollback on failed installations

## 🎨 **UI/UX Standards** (ENHANCE DEVELOPER EXPERIENCE)

### **Modern Shell Experience** (IMPLEMENT ALL)
- **Starship Prompt**: Beautiful, informative command prompt with git integration
- **Zsh + Zinit**: Modern shell with plugin management for enhanced productivity
- **Enhanced Aliases**: Productivity-focused shortcuts for common development tasks
- **Color Coding**: Consistent color scheme across all tools and outputs

### **Developer Aliases** (STANDARD SET REQUIRED - LARADOCK COMPREHENSIVE APPROACH)
```bash
# Modern CLI replacements (MUST install these tools first)
alias ls="eza --group-directories-first"
alias cat="bat --paging=never"
alias vi="nvim"
alias vim="nvim"

# Development shortcuts (REQUIRED for productivity)
alias lg="lazygit"
alias ld="lazydocker"
alias k="kubectl"
alias tf="terraform"
alias dc="docker-compose"

# Git productivity aliases (ESSENTIAL for development workflow)
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"

# Laravel/PHP development (Laradock pattern)
alias art="php artisan"
alias tinker="php artisan tinker"
alias migrate="php artisan migrate"
alias serve="php artisan serve"

# Database shortcuts (Homestead pattern)
alias mysql-connect="mysql -h mysql -u homestead -psecret"
alias psql-connect="psql -h postgresql -U homestead"
alias redis-cli="redis-cli -h redis"
```

## 🔧 **Advanced Configuration Management** (HOMESTEAD/LARADOCK PATTERNS)

### **Environment-Based Configuration** (HOMESTEAD PATTERN)
```bash
# REQUIRED: Support multiple environment configurations
setup_environment_config() {
    local env_type="${1:-development}"
    local config_dir="/opt/app/config"

    log_info "Setting up $env_type environment configuration"

    case "$env_type" in
        "development")
            setup_development_config
            enable_debug_tools
            configure_hot_reload
            ;;
        "testing")
            setup_testing_config
            enable_test_databases
            configure_test_runners
            ;;
        "production")
            setup_production_config
            enable_monitoring
            configure_security_hardening
            ;;
    esac
}
```

### **Configuration Templating** (LARADOCK DYNAMIC APPROACH)
```bash
# REQUIRED: Dynamic configuration generation
generate_config_from_template() {
    local template_file="$1"
    local output_file="$2"
    local env_file="${3:-.env}"

    log_info "Generating configuration from template: $template_file"

    # Load environment variables
    set -a
    source "$env_file"
    set +a

    # Process template with environment variable substitution
    envsubst < "$template_file" > "$output_file"

    # Validate generated configuration
    validate_config_file "$output_file" || {
        log_error "Generated configuration is invalid"
        return 1
    }

    log_success "Configuration generated successfully: $output_file"
}
```

## 📝 **Documentation Standards** (COMPREHENSIVE DOCUMENTATION REQUIRED)

### **Script Headers** (MANDATORY FORMAT)
```bash
#!/bin/bash
# -----------------------------------------------------------------------------
# Tool Installation Script - Brief Description
# -----------------------------------------------------------------------------
# Detailed description of what this script does, including:
# - Main functionality and purpose
# - Dependencies and prerequisites
# - Configuration options and environment variables
# - Usage examples and common scenarios
# - Troubleshooting information
# -----------------------------------------------------------------------------
```

### **Function Documentation** (REQUIRED FOR ALL FUNCTIONS)
```bash
# Function description explaining purpose and behavior
# Arguments:
#   $1 - parameter description with type and constraints
#   $2 - optional parameter (default: value) with explanation
# Returns:
#   0 - success with description of success condition
#   1 - error with description of error conditions
# Example:
#   function_name "required_param" "optional_param"
function_name() {
    local param1="$1"
    local param2="${2:-default_value}"
    # Implementation with clear logic flow
}
```

## 🔄 **Integration Patterns** (FOLLOW ESTABLISHED CONVENTIONS)

### **Environment Variables** (CENTRALIZED CONFIGURATION - HOMESTEAD/LARADOCK PATTERN)
- **Feature Flags**: `INSTALL_{TOOL}=1` to enable/disable tool installation (Laradock pattern)
- **Version Control**: `{TOOL}_VERSION=x.y.z` for specific version pinning with latest fallback
- **Configuration**: Centralized in `.env` file with clear documentation and examples
- **Service Configuration**: Database hosts, cache endpoints, queue connections (Homestead pattern)
- **Development Settings**: Debug flags, profiling options, testing configurations

### **Service Integration** (ENHANCED HOMESTEAD ORCHESTRATION PATTERN)
- **Supervisor**: Service management for long-running processes with auto-restart and logging
- **Docker Context**: Automatic DinD context setup for seamless Docker usage
- **SSH Services**: Automatic SSH daemon configuration with security hardening
- **Database Services**: Auto-configuration of MySQL, PostgreSQL, Redis connections (Homestead pattern)
- **Development Services**: Mailpit, Minio, monitoring tools with automatic setup
- **Networking**: Automatic host resolution, port forwarding, service discovery (Homestead pattern)
- **Health Monitoring**: Comprehensive service health checks with automatic recovery
- **Load Balancing**: Automatic load balancer configuration for multi-instance services

## 🌐 **Service Orchestration & Networking** (HOMESTEAD/LARADOCK PATTERNS)

### **Service Discovery & Communication** (HOMESTEAD PATTERN)
```yaml
# REQUIRED: Service orchestration with automatic networking
version: '3.8'
services:
  workspace:
    build: .
    networks:
      - dev-network
    environment:
      - DB_HOST=mysql
      - REDIS_HOST=redis
      - MAIL_HOST=mailpit
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  mysql:
    image: mysql:8.0
    networks:
      - dev-network
    environment:
      MYSQL_DATABASE: homestead
      MYSQL_USER: homestead
      MYSQL_PASSWORD: secret
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
    volumes:
      - mysql_data:/var/lib/mysql

networks:
  dev-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  mysql_data:
    driver: local
```

### **Port Management & Forwarding** (HOMESTEAD PATTERN)
```bash
# REQUIRED: Automatic port forwarding configuration
setup_port_forwarding() {
    local service_name="$1"
    local internal_port="$2"
    local external_port="$3"

    log_info "Setting up port forwarding for $service_name: $external_port -> $internal_port"

    # Add to docker-compose ports configuration
    add_port_mapping "$service_name" "$external_port:$internal_port"

    # Update hosts file for local development
    add_host_entry "$service_name.test" "127.0.0.1"

    # Configure nginx proxy if needed
    setup_nginx_proxy "$service_name" "$internal_port"

    log_success "Port forwarding configured for $service_name"
}

# REQUIRED: Standard port mappings (Homestead pattern)
configure_standard_ports() {
    setup_port_forwarding "nginx" 80 8000
    setup_port_forwarding "nginx-ssl" 443 44300
    setup_port_forwarding "mysql" 3306 33060
    setup_port_forwarding "postgresql" 5432 54320
    setup_port_forwarding "redis" 6379 63790
    setup_port_forwarding "mailpit" 8025 8025
    setup_port_forwarding "minio" 9000 9000
    setup_port_forwarding "grafana" 3000 3000
}
```

### **Development Workflow Integration** (LARADOCK COMPREHENSIVE APPROACH)
```bash
# REQUIRED: Integrated development workflow setup
setup_development_workflow() {
    log_banner "DEVELOPMENT WORKFLOW SETUP"

    # File watching and hot reload
    setup_file_watching_with_inotify

    # Code quality tools
    setup_code_quality_tools_suite

    # Testing environment
    setup_comprehensive_testing_environment

    # Debugging tools
    setup_debugging_tools_with_xdebug

    # Performance monitoring
    setup_performance_monitoring_stack

    # Development databases
    setup_development_databases

    # Queue workers
    setup_queue_workers_with_supervisor

    log_success "Development workflow configured successfully"
}
```

## 🌐 **Service Orchestration & Networking** (HOMESTEAD/LARADOCK PATTERNS)

### **Service Discovery & Communication** (HOMESTEAD PATTERN)
```yaml
# REQUIRED: Service orchestration with automatic networking
version: '3.8'
services:
  workspace:
    build: .
    networks:
      - dev-network
    environment:
      - DB_HOST=mysql
      - REDIS_HOST=redis
      - MAIL_HOST=mailpit
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_started

  mysql:
    image: mysql:8.0
    networks:
      - dev-network
    environment:
      MYSQL_DATABASE: homestead
      MYSQL_USER: homestead
      MYSQL_PASSWORD: secret
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

networks:
  dev-network:
    driver: bridge
```

### **Port Management & Forwarding** (HOMESTEAD PATTERN)
```bash
# REQUIRED: Automatic port forwarding configuration
setup_port_forwarding() {
    local service_name="$1"
    local internal_port="$2"
    local external_port="$3"

    log_info "Setting up port forwarding for $service_name: $external_port -> $internal_port"

    # Add to docker-compose ports configuration
    add_port_mapping "$service_name" "$external_port:$internal_port"

    # Update hosts file for local development
    add_host_entry "$service_name.test" "127.0.0.1"

    log_success "Port forwarding configured for $service_name"
}

# REQUIRED: Standard port mappings (Homestead pattern)
configure_standard_ports() {
    setup_port_forwarding "nginx" 80 8000
    setup_port_forwarding "nginx-ssl" 443 44300
    setup_port_forwarding "mysql" 3306 33060
    setup_port_forwarding "postgresql" 5432 54320
    setup_port_forwarding "redis" 6379 63790
    setup_port_forwarding "mailpit" 8025 8025
}
```

### **Development Workflow Integration** (LARADOCK COMPREHENSIVE APPROACH)
```bash
# REQUIRED: Integrated development workflow setup
setup_development_workflow() {
    log_banner "DEVELOPMENT WORKFLOW SETUP"

    # File watching and hot reload
    setup_file_watching

    # Code quality tools
    setup_code_quality_tools

    # Testing environment
    setup_testing_environment

    # Debugging tools
    setup_debugging_tools

    # Performance monitoring
    setup_performance_monitoring

    log_success "Development workflow configured successfully"
}
```

---

## 🎯 **Code Generation Instructions** (FOLLOW PRECISELY)

When generating code for this environment, you MUST:

1. **Follow the modular architecture** - Create reusable, independent components that can be tested and maintained separately
2. **Use the established patterns** - Implement logging, error handling, and file organization exactly as specified
3. **Implement comprehensive error handling** - Include lock files, retry mechanisms, and thorough validation
4. **Ensure security best practices** - Apply proper permissions, user management, and secure defaults
5. **Optimize for performance** - Use caching strategies, architecture detection, and minimal Docker layers
6. **Provide excellent developer experience** - Include clear logging, helpful aliases, and intuitive interfaces
7. **Test for idempotency** - Ensure scripts handle repeated execution gracefully without side effects
8. **Document thoroughly** - Provide clear headers, function documentation, and usage examples

**CRITICAL: Always prioritize reliability, security, and maintainability over brevity. Code should be self-documenting and production-ready.**

## 📋 **Mandatory Implementation Checklist**

### **For Installation Scripts** (ALL ITEMS REQUIRED)
- [ ] Use `set -euo pipefail` for strict error handling
- [ ] Load common functions: `source "$SCRIPT_DIR/../common/functions.sh"`
- [ ] Implement lock file mechanism with cleanup trap
- [ ] Check for existing installation with markers before proceeding
- [ ] Use architecture detection for platform-specific downloads
- [ ] Implement retry mechanism for network operations (3 attempts, 5-second delay)
- [ ] Validate required environment variables and dependencies
- [ ] Use structured logging throughout (log_install, log_success, etc.)
- [ ] Test installation success and create completion markers
- [ ] Handle both enabled/disabled states via environment variables

### **For Setup Scripts** (ALL ITEMS REQUIRED)
- [ ] Validate user arguments (USERNAME, USER_UID, USER_GID) with numeric checks
- [ ] Create directories with proper permissions (700 for .ssh, 755 for others)
- [ ] Copy configurations to both root and dev users with correct ownership
- [ ] Set appropriate file permissions (600 for private, 644 for public)
- [ ] Use helper functions for repetitive operations to reduce code duplication
- [ ] Log all significant actions with appropriate log levels
- [ ] Handle missing files/directories gracefully with informative messages

### **For Docker Integration** (ALL ITEMS REQUIRED)
- [ ] Use multi-stage builds for better caching and smaller final images
- [ ] Group related operations in single RUN commands to minimize layers
- [ ] Use `--setopt=install_weak_deps=False --nodocs` for dnf installations
- [ ] Clean up package caches and temporary files in same layer
- [ ] Copy scripts before execution, remove after if not needed in final image
- [ ] Use ARG for configurable build options with sensible defaults
- [ ] Set proper SHELL with error handling options (`-o errexit -o pipefail`)

### **For SSH Key Management** (ALL ITEMS REQUIRED)
- [ ] Support folder-based organization (incoming/outgoing) as primary method
- [ ] Process .pub files for authorized_keys with duplicate prevention
- [ ] Set correct permissions (700 for dirs, 600/644 for files) consistently
- [ ] Copy keys to both root and dev users with proper ownership
- [ ] Maintain backward compatibility with legacy naming conventions
- [ ] Log key processing summary with counts and types
- [ ] Handle missing directories gracefully by creating them with correct permissions

### **For Common Functions** (ALL ITEMS REQUIRED)
- [ ] Use consistent parameter validation with clear error messages
- [ ] Implement proper error codes and messages for different failure scenarios
- [ ] Support both GUM and fallback UI modes for broad compatibility
- [ ] Include debug logging with DEBUG flag for troubleshooting
- [ ] Use readonly for constants to prevent accidental modification
- [ ] Export functions for use in other scripts with proper namespacing
- [ ] Document function parameters and return codes comprehensively
- [ ] Test functions independently with example usage scripts

### **For Health Checks & Monitoring** (BITNAMI-INSPIRED RELIABILITY)
- [ ] Implement health check endpoints for all services
- [ ] Add service readiness probes with appropriate timeouts
- [ ] Monitor resource usage and set appropriate limits
- [ ] Implement graceful shutdown handling for all services
- [ ] Add logging aggregation and structured log output
- [ ] Include performance metrics collection for optimization

### **For Configuration Management** (HOMESTEAD/LARADOCK PATTERNS)
- [ ] Support environment-based configuration switching
- [ ] Implement configuration validation with clear error messages
- [ ] Add configuration templating for dynamic environments
- [ ] Support per-project and global configuration patterns
- [ ] Include configuration backup and restore functionality
- [ ] Add configuration migration tools for version upgrades

## 🏗️ **Reference Architecture Patterns** (PROVEN APPROACHES)

### **Bitnami Container Patterns** (SECURITY & OPTIMIZATION FOCUS)
```dockerfile
# Security-first approach with minimal attack surface
FROM oraclelinux:9 AS base
ARG TARGETARCH
LABEL org.opencontainers.image.base.name="oraclelinux:9" \
      org.opencontainers.image.description="Application packaged by Oracle" \
      org.opencontainers.image.vendor="Oracle Corporation"

# Enhanced shell configuration for safer builds
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

# Install only essential packages with cleanup in same layer
RUN install_packages ca-certificates curl procps && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Security hardening - remove setuid/setgid bits
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

# Run as non-root user for security
USER 1001
WORKDIR /opt/app
```

### **Homestead Provisioning Patterns** (DEVELOPMENT WORKFLOW FOCUS)
```yaml
# Homestead-style configuration management
services:
  - enabled:
      - "postgresql"
      - "redis"
      - "mailpit"
  - disabled:
      - "mysql"

sites:
  - map: app.test
    to: /home/vagrant/app/public
    php: "8.3"
    schedule: true

folders:
  - map: ~/code/app
    to: /home/vagrant/app
    type: "nfs"

variables:
  - key: APP_ENV
    value: local
  - key: DB_HOST
    value: postgresql
```

### **Laradock Modular Patterns** (COMPREHENSIVE TOOLING FOCUS)
```bash
# Laradock-style feature installation with environment variables
install_development_tools() {
    # Core development tools (always installed)
    install_core_tools

    # Optional tools based on environment variables
    [[ "${INSTALL_XDEBUG:-false}" == "true" ]] && install_xdebug
    [[ "${INSTALL_BLACKFIRE:-false}" == "true" ]] && install_blackfire
    [[ "${INSTALL_NODEJS:-true}" == "true" ]] && install_nodejs
    [[ "${INSTALL_PYTHON:-true}" == "true" ]] && install_python
    [[ "${INSTALL_GOLANG:-false}" == "true" ]] && install_golang

    # Workspace customization
    setup_workspace_aliases
    setup_development_environment
}
```

## 🔄 **Migration Guidance** (IMPLEMENTING ENHANCED PATTERNS)

### **Adopting Bitnami Security Patterns**
1. **Multi-stage Builds**: Refactor existing Dockerfiles to use multi-stage builds with security hardening
2. **Checksum Verification**: Add SHA256 verification for all downloaded packages
3. **Non-root Execution**: Migrate services to run as non-root user (1001)
4. **Minimal Packages**: Audit and remove unnecessary packages from base images

### **Implementing Homestead Workflow Patterns**
1. **Service Orchestration**: Enhance docker-compose.yml with Homestead-style service management
2. **Site Configuration**: Add support for multiple site configurations with PHP version switching
3. **Environment Variables**: Expand .env configuration with Homestead-style variable management
4. **Automatic Provisioning**: Implement automatic service configuration and site setup

### **Integrating Laradock Modularity**
1. **Feature Flags**: Expand environment variable system for granular tool control
2. **Workspace Customization**: Add comprehensive development tool installation options
3. **Configuration Templates**: Implement templating system for dynamic configuration generation
4. **Tool Integration**: Add support for comprehensive development tool ecosystem

## � **Migration Roadmap** (STEP-BY-STEP IMPLEMENTATION GUIDE)

### **Phase 1: Security Hardening (Bitnami Patterns) - IMMEDIATE PRIORITY**
```bash
# Step 1: Implement non-root user execution
migrate_to_nonroot_user() {
    log_info "Migrating to non-root user execution (Bitnami pattern)"

    # Create bitnami user and group
    groupadd -g 1001 bitnami 2>/dev/null || true
    useradd -r -u 1001 -g bitnami bitnami 2>/dev/null || true

    # Update Dockerfile to use non-root user
    sed -i '/^USER/d' Dockerfile
    echo "USER 1001" >> Dockerfile

    # Update file ownership
    find /opt -type f -exec chown 1001:1001 {} \;
    find /opt -type d -exec chown 1001:1001 {} \;

    log_success "Non-root user migration completed"
}

# Step 2: Implement security hardening
implement_security_hardening() {
    log_info "Implementing Bitnami security hardening"

    # Remove setuid/setgid bits
    find / -perm /6000 -type f -exec chmod a-s {} \; 2>/dev/null || true

    # Update package installation to use minimal packages
    update_dockerfile_package_installation

    # Implement secrets management
    setup_secrets_management_system

    log_success "Security hardening implemented"
}
```

### **Phase 2: Service Orchestration (Homestead Patterns) - HIGH PRIORITY**
```bash
# Step 1: Enhance docker-compose with health checks
enhance_docker_compose() {
    log_info "Enhancing docker-compose with Homestead patterns"

    # Add health checks to all services
    add_health_checks_to_services

    # Implement service dependencies
    configure_service_dependencies

    # Add networking configuration
    setup_custom_networks

    # Configure volume management
    setup_persistent_volumes

    log_success "Docker-compose enhancement completed"
}

# Step 2: Implement automatic service configuration
implement_service_automation() {
    log_info "Implementing Homestead-style service automation"

    # Create service configuration templates
    create_service_config_templates

    # Implement automatic port forwarding
    setup_automatic_port_forwarding

    # Configure host file management
    setup_host_file_automation

    log_success "Service automation implemented"
}
```

### **Phase 3: Modular Architecture (Laradock Patterns) - MEDIUM PRIORITY**
```bash
# Step 1: Implement feature flags system
implement_feature_flags() {
    log_info "Implementing Laradock-style feature flags"

    # Create comprehensive .env template
    create_comprehensive_env_template

    # Update installation scripts with feature flags
    update_scripts_with_feature_flags

    # Implement conditional tool installation
    setup_conditional_tool_installation

    log_success "Feature flags system implemented"
}

# Step 2: Enhance workspace customization
enhance_workspace_customization() {
    log_info "Enhancing workspace with Laradock patterns"

    # Add comprehensive tool installation options
    add_comprehensive_tool_options

    # Implement workspace templates
    create_workspace_templates

    # Setup development environment profiles
    setup_development_profiles

    log_success "Workspace customization enhanced"
}
```

### **Phase 4: Performance Optimization - ONGOING**
```bash
# Step 1: Implement build optimization
optimize_build_performance() {
    log_info "Implementing build optimization patterns"

    # Enhance multi-stage builds
    optimize_multistage_builds

    # Implement intelligent caching
    setup_intelligent_caching

    # Add build parallelization
    implement_parallel_builds

    log_success "Build optimization implemented"
}

# Step 2: Add monitoring and metrics
implement_monitoring() {
    log_info "Implementing comprehensive monitoring"

    # Setup resource monitoring
    setup_resource_monitoring

    # Implement health dashboards
    create_health_dashboards

    # Add performance metrics
    setup_performance_metrics

    log_success "Monitoring system implemented"
}
```

## �📊 **Performance Monitoring & Optimization** (PRODUCTION-READY PATTERNS)

### **Resource Monitoring** (BITNAMI RELIABILITY APPROACH)
```bash
# REQUIRED: Resource usage monitoring and alerting
monitor_resource_usage() {
    local service_name="$1"
    local cpu_threshold="${2:-80}"
    local memory_threshold="${3:-85}"

    log_info "Monitoring resource usage for $service_name"

    # CPU usage check
    local cpu_usage
    cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" "$service_name" | sed 's/%//')

    if (( $(echo "$cpu_usage > $cpu_threshold" | bc -l) )); then
        log_warning "High CPU usage detected: ${cpu_usage}% (threshold: ${cpu_threshold}%)"
        trigger_cpu_alert "$service_name" "$cpu_usage"
    fi

    # Memory usage check
    local memory_usage
    memory_usage=$(docker stats --no-stream --format "{{.MemPerc}}" "$service_name" | sed 's/%//')

    if (( $(echo "$memory_usage > $memory_threshold" | bc -l) )); then
        log_warning "High memory usage detected: ${memory_usage}% (threshold: ${memory_threshold}%)"
        trigger_memory_alert "$service_name" "$memory_usage"
    fi
}
```

### **Performance Optimization** (COMPREHENSIVE APPROACH)
```bash
# REQUIRED: Automatic performance tuning
optimize_container_performance() {
    local container_name="$1"

    log_info "Optimizing performance for $container_name"

    # Set resource limits based on available system resources
    local total_memory
    total_memory=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    local memory_limit=$((total_memory * 70 / 100))  # 70% of total memory

    # Apply optimizations
    docker update \
        --memory="${memory_limit}m" \
        --memory-swap="${memory_limit}m" \
        --cpus="$(nproc)" \
        "$container_name"

    log_success "Performance optimization applied to $container_name"
}
```

### **Health Monitoring Dashboard** (HOMESTEAD DEVELOPER EXPERIENCE)
```bash
# REQUIRED: Development environment health dashboard
show_environment_status() {
    log_banner "DEVELOPMENT ENVIRONMENT STATUS"

    echo "🔧 Services Status:"
    check_service_status "workspace" "http://localhost:8000/health"
    check_service_status "mysql" "mysql://homestead:secret@localhost:33060"
    check_service_status "redis" "redis://localhost:63790"
    check_service_status "mailpit" "http://localhost:8025"

    echo ""
    echo "📊 Resource Usage:"
    show_resource_summary

    echo ""
    echo "🌐 Network Configuration:"
    show_network_summary

    echo ""
    echo "🔑 SSH Key Status:"
    show_ssh_key_summary
}
```

## 📊 **Comparative Analysis & Best Practices Integration**

### **Architecture Pattern Comparison**

| Aspect | Bitnami Containers | Laravel Homestead | Laradock Workspace | Oracle Linux 9 Integration |
|--------|-------------------|-------------------|-------------------|---------------------------|
| **Security Model** | Non-root execution, minimal attack surface | VM-based isolation | Container-based isolation | **Hybrid**: Non-root + container isolation |
| **Build Strategy** | Multi-stage, optimized layers | Vagrant provisioning | Feature-flag driven builds | **Enhanced**: Multi-stage + feature flags |
| **Service Management** | Systemd + health checks | Vagrant + provisioning scripts | Docker Compose orchestration | **Comprehensive**: All three approaches |
| **Developer Experience** | Production-focused | Development-optimized | Comprehensive tooling | **Best of all**: Production + development + tooling |
| **Configuration** | Environment variables | YAML configuration | .env + templates | **Unified**: YAML + .env + templates |
| **Networking** | Container networking | Host networking | Bridge networking | **Flexible**: All networking modes |

### **Implementation Priority Matrix**

| Priority | Pattern | Source | Implementation Effort | Impact |
|----------|---------|--------|----------------------|--------|
| **CRITICAL** | Non-root execution | Bitnami | Low | High Security |
| **CRITICAL** | Security hardening | Bitnami | Medium | High Security |
| **HIGH** | Service orchestration | Homestead | Medium | High Developer Experience |
| **HIGH** | Health checks | Bitnami | Low | High Reliability |
| **MEDIUM** | Feature flags | Laradock | High | High Flexibility |
| **MEDIUM** | Configuration templates | Homestead | Medium | Medium Maintainability |
| **LOW** | Advanced monitoring | All | High | Medium Observability |

### **Code Generation Guidelines Summary**

When generating code for this enhanced Oracle Linux 9 development environment:

#### **MANDATORY Requirements (Non-Negotiable)**
1. **Security First**: Always implement Bitnami security patterns (non-root, hardening, secrets management)
2. **Modular Design**: Follow Laradock modular architecture with clear separation of concerns
3. **Service Orchestration**: Implement Homestead-style service management with health checks
4. **Error Handling**: Comprehensive error handling with proper logging and recovery mechanisms
5. **Documentation**: Thorough documentation with examples and migration guides

#### **RECOMMENDED Enhancements**
1. **Performance Optimization**: Multi-stage builds, intelligent caching, resource monitoring
2. **Developer Experience**: Modern tooling, comprehensive aliases, workflow automation
3. **Configuration Management**: Template-based configuration with environment flexibility
4. **Testing Integration**: Automated testing, validation, and quality assurance
5. **Monitoring & Observability**: Health dashboards, metrics collection, alerting

#### **INTEGRATION Patterns**
1. **Bitnami Security + Homestead Workflow**: Secure development environment with excellent UX
2. **Laradock Modularity + Bitnami Optimization**: Flexible architecture with production-ready performance
3. **Homestead Orchestration + Laradock Tooling**: Comprehensive development stack with service automation

This enhanced template ensures all generated code follows the established patterns and maintains the high quality, security, and reliability standards of the Oracle Linux 9 development environment, incorporating proven practices from Bitnami, Homestead, and Laradock. Code must be production-ready, well-documented, and thoroughly tested with comprehensive monitoring and optimization capabilities.

---

## 🎯 **Final Implementation Checklist**

### **Before Code Generation**
- [ ] Understand the specific requirements and context
- [ ] Identify which reference patterns apply to the task
- [ ] Plan the security implications and hardening requirements
- [ ] Consider the developer experience impact

### **During Code Generation**
- [ ] Apply appropriate security patterns from Bitnami
- [ ] Implement service orchestration patterns from Homestead
- [ ] Use modular architecture patterns from Laradock
- [ ] Include comprehensive error handling and logging
- [ ] Add proper documentation and examples

### **After Code Generation**
- [ ] Validate security implementation
- [ ] Test service integration and health checks
- [ ] Verify performance optimization
- [ ] Ensure documentation completeness
- [ ] Plan migration strategy if needed

**Remember**: This is not just a development environment—it's a production-ready, enterprise-grade platform that incorporates the best practices from three proven container and development environment architectures.