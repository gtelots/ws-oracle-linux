# Oracle Linux 9 Development Environment - Optimized Code Generation Template

You are an expert developer creating production-ready code for Oracle Linux 9 development containers. Generate code following enterprise-grade quality, security, and performance standards.

## 🔗 **Reference Architectures & Download Links**

### **Bitnami Containers** (Security & Optimization)
- **Repository**: https://github.com/bitnami/containers
- **Downloads**: https://downloads.bitnami.com/files/stacksmith
- **Patterns**: Security hardening, multi-stage builds, non-root execution
- **Documentation**: https://docs.bitnami.com/tutorials/

### **Laravel Homestead** (Development Workflow)
- **Repository**: https://github.com/laravel/homestead
- **Box Downloads**: https://app.vagrantup.com/laravel/boxes/homestead
- **Patterns**: Service orchestration, automated provisioning, development workflow
- **Documentation**: https://laravel.com/docs/homestead

### **Laradock Workspace** (Comprehensive Tooling)
- **Repository**: https://github.com/laradock/laradock
- **Docker Hub**: https://hub.docker.com/u/laradock
- **Patterns**: Modular architecture, feature flags, comprehensive development tools
- **Documentation**: https://laradock.io/

## 🎯 **Architecture Overview**

Production-ready Oracle Linux 9 development container with proven patterns:

### **Core Principles**
- **Modular Design**: Reusable components with clear separation (Laradock)
- **Security-First**: Non-root execution, proper permissions (Bitnami)
- **Developer Experience**: Modern CLI tools, productivity aliases (Homestead)
- **Service Orchestration**: Health checks, dependency management (Homestead)
- **Multi-stage Builds**: Optimized layers, intelligent caching (Bitnami)

### **Project Structure**
```
ws-oracle-linux/
├── Dockerfile                        # Multi-stage optimized build
├── docker-compose.yml                # Service orchestration
├── taskfile.yml                      # Task runner commands
├── .env                              # Environment configuration
├── scripts/
│   ├── common/                       # Shared functions (REQUIRED)
│   ├── install/tools/                # Tool installers (install-{tool}.sh)
│   ├── setup/                        # System configuration
│   └── examples/                     # Usage examples
├── dotfiles/                         # Dev environment configs
├── .ssh/
│   ├── incoming/                     # Workspace access keys
│   └── outgoing/                     # External connection keys
└── ca-certificates/                  # Custom CAs
```

## 🏗️ **Reference Patterns**

### **Bitnami Security Model**
```dockerfile
FROM oraclelinux:9 AS base
ARG TARGETARCH
ARG DOWNLOADS_URL="downloads.bitnami.com/files/stacksmith"

SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

LABEL org.opencontainers.image.base.name="oraclelinux:9" \
      org.opencontainers.image.description="Oracle Linux 9 Development Environment"

# Install essential packages with cleanup
RUN dnf -y install --setopt=install_weak_deps=False --nodocs \
        ca-certificates curl procps && \
    dnf clean all && rm -rf /var/cache/dnf

# Security hardening
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

# Non-root user
RUN groupadd -g 1001 bitnami && \
    useradd -r -u 1001 -g bitnami bitnami && \
    mkdir -p /opt/bitnami && chmod g+rwX /opt/bitnami

USER 1001
WORKDIR /opt/bitnami
```

### **Homestead Workflow Pattern**
```bash
configure_development_services() {
    local config_file="$1"
    log_info "Configuring services from $config_file"

    # Parse YAML configuration
    local services databases sites
    services=$(yq eval '.services[]' "$config_file")
    databases=$(yq eval '.databases[]' "$config_file")
    sites=$(yq eval '.sites[]' "$config_file")

    # Configure services with health checks
    for service in $services; do
        configure_service "$service"
        setup_service_health_check "$service"
    done

    # Setup connections
    for db in $databases; do
        setup_database_connection "$db"
    done

    log_success "Services configured successfully"
}
```

### **Laradock Modular Pattern**
```bash
install_development_tools() {
    log_banner "DEVELOPMENT TOOLS INSTALLATION"

    # Core tools (always installed)
    install_core_development_stack

    # Optional tools via environment variables
    [[ "${INSTALL_XDEBUG:-false}" == "true" ]] && install_xdebug
    [[ "${INSTALL_NODEJS:-true}" == "true" ]] && install_nodejs
    [[ "${INSTALL_PYTHON:-true}" == "true" ]] && install_python
    [[ "${INSTALL_GOLANG:-false}" == "true" ]] && install_golang
    [[ "${INSTALL_DOCKER_CLIENT:-true}" == "true" ]] && install_docker_client
    [[ "${INSTALL_KUBECTL:-false}" == "true" ]] && install_kubernetes_tools

    # Workspace customization
    setup_workspace_aliases
    setup_development_environment_configs

    log_success "Development tools installation completed"
}
```

## 🛠️ **Coding Standards**

### **Shell Script Template**
```bash
#!/bin/bash
set -euo pipefail

# Load shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/functions.sh"

# Environment validation
validate_environment || {
    log_error "Environment validation failed"
    exit 1
}

# Structured logging
log_info "Starting process..."
log_success "Process completed successfully"
log_warning "Non-critical issue detected"
log_error "Critical error occurred"
```

### **File Organization**
- **Installation**: `scripts/install/tools/install-{tool}.sh`
- **Setup**: `scripts/setup/setup-{component}.sh`
- **Common**: `scripts/common/{category}.sh`
- **Lock Files**: `/usr/local/share/install-locks/{tool}.lock`
- **Markers**: `/usr/local/bin/.{tool}-installed`

### **Naming Conventions**
- **Variables**: `UPPER_CASE` (constants), `lower_case` (local)
- **Functions**: `snake_case` (e.g., `install_docker`)
- **Files**: `kebab-case` (e.g., `install-terraform.sh`)
- **Build Args**: `INSTALL_{TOOL}=1`, `{TOOL}_VERSION=x.y.z`

## 🔒 **Security Requirements**

### **SSH Key Management**
```bash
.ssh/
├── incoming/          # Workspace access keys
│   ├── *.pub         # Public keys (644)
│   └── *             # Private keys (600)
└── outgoing/          # External connection keys (600)
```

### **Permission Standards**
- **Private Keys**: `600` (owner only)
- **Public Keys**: `644` (readable by all)
- **SSH Directories**: `700` (owner access only)
- **Scripts**: `755` (executable)
- **Config Files**: `644` (readable)

### **User Management**
- **Dual Setup**: Configure both `root` and `dev` users
- **Non-root Default**: Run as USER 1001 (Bitnami pattern)
- **Sudo Access**: Passwordless sudo for `dev` user
- **Security Hardening**: Remove setuid/setgid bits
- **Resource Limits**: Implement cgroups limits

### **Security Hardening**
```bash
harden_container_security() {
    log_info "Applying security hardening"

    # Remove unnecessary packages
    dnf -y remove --setopt=clean_requirements_on_remove=1 \
        kernel-headers gcc make || true

    # Remove setuid/setgid bits
    find / -perm /6000 -type f -exec chmod a-s {} \; || true

    # Set secure permissions
    find /opt/bitnami -type d -exec chmod 755 {} \;
    find /opt/bitnami -type f -exec chmod 644 {} \;

    # Clear sensitive files
    rm -rf /tmp/* /var/tmp/* /var/cache/* /var/log/* || true

    # Set ownership
    chown -R 1001:1001 /opt/bitnami

    log_success "Security hardening completed"
}
```

## ⚡ **Performance Optimization**

### **Docker Build Optimization**
```dockerfile
FROM oraclelinux:9 AS base
ARG TARGETARCH
ARG DOWNLOADS_URL="downloads.bitnami.com/files/stacksmith"

SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

# System packages in early layers (better caching)
RUN dnf -y install --setopt=install_weak_deps=False --nodocs \
        ca-certificates curl procps && \
    dnf clean all && rm -rf /var/cache/dnf

# Tool installations with checksum verification
FROM base AS tools
RUN curl -SsLf "https://${DOWNLOADS_URL}/component.tar.gz" -O && \
    curl -SsLf "https://${DOWNLOADS_URL}/component.tar.gz.sha256" -O && \
    sha256sum -c "component.tar.gz.sha256" && \
    tar -zxf "component.tar.gz" -C /opt/bitnami --strip-components=2
```

### **Installation Patterns**
- **Lock Files**: Prevent concurrent installations
- **Install Markers**: Skip re-installation on rebuilds
- **Architecture Detection**: Platform-specific binaries
- **Retry Mechanisms**: Handle network failures (3 attempts, 5s delay)
- **Checksum Verification**: SHA256 verification
- **Non-root Execution**: USER 1001 for security

## 🚨 **Error Handling**

### **Lock File Management**
```bash
readonly LOCK_FILE="/tmp/tool-install.lock"
trap 'rm -f "$LOCK_FILE"' EXIT

if ! (set -C; echo $$ > "$LOCK_FILE") 2>/dev/null; then
    log_error "Installation already in progress"
    exit 1
fi

# Retry mechanism
if ! retry 3 5 download_file "$URL" "$OUTPUT"; then
    log_error "Failed to download after 3 attempts"
    exit 1
fi
```

### **Validation Patterns**
```bash
# Environment validation
validate_env_vars "USERNAME" "USER_UID" "USER_GID" || exit 1

# Skip if already installed (idempotency)
if is_tool_installed "tool-name"; then
    log_install_skip "tool-name" "already installed"
    exit 0
fi

# Architecture check
arch=$(get_arch) || {
    log_error "Unsupported architecture: $(uname -m)"
    exit 1
}
```

## 📊 **Logging & Monitoring**

### **Installation Lifecycle**
```bash
log_install "tool-name" "version"

# Progress updates
log_step 1 3 "Downloading package"
log_step 2 3 "Installing dependencies"
log_step 3 3 "Configuring tool"

log_install_success "tool-name" "version"

# Contextual banners
log_banner "TOOL INSTALLATION"
log_separator
```

### **Debug Support**
- **Debug Mode**: `DEBUG=true` for detailed logging
- **GUM Integration**: Enhanced UI with fallback
- **Progress Indicators**: Visual feedback for long operations

## 🧪 **Testing & Validation**

### **Installation Verification**
```bash
if command -v tool-name >/dev/null 2>&1; then
    log_success "Tool installed and available in PATH"
    version=$(tool-name --version 2>/dev/null) || log_warning "Version check failed"
    [[ -n "$version" ]] && log_info "Installed version: $version"

    # Functional verification
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

### **Health Checks**
```bash
check_service_health() {
    local service_name="$1"
    local health_endpoint="$2"
    local timeout="${3:-30}"

    if timeout "$timeout" bash -c "until curl -f $health_endpoint; do sleep 1; done" 2>/dev/null; then
        log_success "$service_name is healthy"
        return 0
    else
        log_error "$service_name health check failed after ${timeout}s"
        return 1
    fi
}
```

## 🎨 **Developer Experience**

### **Modern Shell Setup**
- **Starship Prompt**: Git integration, beautiful prompt
- **Zsh + Zinit**: Plugin management, enhanced productivity
- **Enhanced Aliases**: Productivity shortcuts
- **Color Coding**: Consistent color scheme

### **Essential Aliases**
```bash
# Modern CLI replacements
alias ls="eza --group-directories-first"
alias cat="bat --paging=never"
alias vi="nvim"
alias vim="nvim"

# Development shortcuts
alias lg="lazygit"
alias ld="lazydocker"
alias k="kubectl"
alias tf="terraform"
alias dc="docker-compose"

# Git productivity
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"

# Laravel/PHP development
alias art="php artisan"
alias tinker="php artisan tinker"
alias migrate="php artisan migrate"
alias serve="php artisan serve"

# Database connections
alias mysql-connect="mysql -h mysql -u homestead -psecret"
alias psql-connect="psql -h postgresql -U homestead"
alias redis-cli="redis-cli -h redis"
```

## 🔧 **Configuration Management**

### **Environment-Based Configuration**
```bash
setup_environment_config() {
    local env_type="${1:-development}"
    log_info "Setting up $env_type environment configuration"

    case "$env_type" in
        "development")
            setup_development_config
            enable_debug_tools
            ;;
        "testing")
            setup_testing_config
            enable_test_databases
            ;;
        "production")
            setup_production_config
            enable_monitoring
            ;;
    esac
}
```

### **Configuration Templating**
```bash
generate_config_from_template() {
    local template_file="$1"
    local output_file="$2"
    local env_file="${3:-.env}"

    # Load environment variables
    set -a; source "$env_file"; set +a

    # Process template
    envsubst < "$template_file" > "$output_file"

    # Validate configuration
    validate_config_file "$output_file" || {
        log_error "Generated configuration is invalid"
        return 1
    }

    log_success "Configuration generated: $output_file"
}
```

## 📝 **Documentation Standards**

### **Script Headers**
```bash
#!/bin/bash
# -----------------------------------------------------------------------------
# Tool Installation Script - Brief Description
# -----------------------------------------------------------------------------
# Description: Main functionality and purpose
# Dependencies: Prerequisites and requirements
# Configuration: Environment variables and options
# Usage: Examples and common scenarios
# -----------------------------------------------------------------------------
```

### **Function Documentation**
```bash
# Function description explaining purpose and behavior
# Arguments:
#   $1 - parameter description with type
#   $2 - optional parameter (default: value)
# Returns:
#   0 - success condition
#   1 - error condition
# Example:
#   function_name "required_param" "optional_param"
function_name() {
    local param1="$1"
    local param2="${2:-default_value}"
    # Implementation
}
```

## 🔄 **Integration Patterns**

### **Environment Variables**
- **Feature Flags**: `INSTALL_{TOOL}=1` (enable/disable tools)
- **Version Control**: `{TOOL}_VERSION=x.y.z` (version pinning)
- **Configuration**: Centralized in `.env` file
- **Service Config**: Database hosts, cache endpoints
- **Development**: Debug flags, profiling options

### **Service Integration**
- **Supervisor**: Service management with auto-restart
- **Docker Context**: Automatic DinD setup
- **SSH Services**: Secure SSH daemon configuration
- **Database Services**: MySQL, PostgreSQL, Redis auto-config
- **Development Services**: Mailpit, Minio, monitoring
- **Networking**: Host resolution, port forwarding
- **Health Monitoring**: Service health checks

## 🌐 **Service Orchestration**

### **Docker Compose Pattern**
```yaml
version: '3.8'
services:
  workspace:
    build: .
    networks: [dev-network]
    environment:
      - DB_HOST=mysql
      - REDIS_HOST=redis
    depends_on:
      mysql: {condition: service_healthy}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  mysql:
    image: mysql:8.0
    networks: [dev-network]
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

### **Port Management**
```bash
setup_port_forwarding() {
    local service_name="$1"
    local internal_port="$2"
    local external_port="$3"

    log_info "Setting up port forwarding: $external_port -> $internal_port"
    add_port_mapping "$service_name" "$external_port:$internal_port"
    add_host_entry "$service_name.test" "127.0.0.1"
    log_success "Port forwarding configured for $service_name"
}

# Standard port mappings
configure_standard_ports() {
    setup_port_forwarding "nginx" 80 8000
    setup_port_forwarding "mysql" 3306 33060
    setup_port_forwarding "redis" 6379 63790
    setup_port_forwarding "mailpit" 8025 8025
}
```

### **Development Workflow**
```bash
setup_development_workflow() {
    log_banner "DEVELOPMENT WORKFLOW SETUP"
    setup_file_watching
    setup_code_quality_tools
    setup_testing_environment
    setup_debugging_tools
    setup_performance_monitoring
    log_success "Development workflow configured"
}
```

---

## 🎯 **Code Generation Instructions**

When generating code for this environment, you MUST:

1. **Follow modular architecture** - Create reusable, independent components
2. **Use established patterns** - Implement logging, error handling, file organization as specified
3. **Implement comprehensive error handling** - Include lock files, retry mechanisms, validation
4. **Ensure security best practices** - Apply proper permissions, user management, secure defaults
5. **Optimize for performance** - Use caching strategies, architecture detection, minimal Docker layers
6. **Provide excellent developer experience** - Include clear logging, helpful aliases, intuitive interfaces
7. **Test for idempotency** - Ensure scripts handle repeated execution gracefully
8. **Document thoroughly** - Provide clear headers, function documentation, usage examples

**CRITICAL: Always prioritize reliability, security, and maintainability. Code should be production-ready.**

## 📋 **Implementation Checklist**

### **Installation Scripts**
- [ ] Use `set -euo pipefail` for strict error handling
- [ ] Load common functions: `source "$SCRIPT_DIR/../common/functions.sh"`
- [ ] Implement lock file mechanism with cleanup trap
- [ ] Check for existing installation with markers
- [ ] Use architecture detection for platform-specific downloads
- [ ] Implement retry mechanism (3 attempts, 5s delay)
- [ ] Validate environment variables and dependencies
- [ ] Use structured logging (log_install, log_success, etc.)
- [ ] Test installation success and create completion markers

### **Setup Scripts**
- [ ] Validate user arguments (USERNAME, USER_UID, USER_GID)
- [ ] Create directories with proper permissions (700 for .ssh, 755 for others)
- [ ] Copy configurations to both root and dev users
- [ ] Set appropriate file permissions (600 private, 644 public)
- [ ] Use helper functions to reduce code duplication
- [ ] Log all significant actions with appropriate levels

### **Docker Integration**
- [ ] Use multi-stage builds for better caching
- [ ] Group operations in single RUN commands to minimize layers
- [ ] Use `--setopt=install_weak_deps=False --nodocs` for dnf
- [ ] Clean up package caches in same layer
- [ ] Use ARG for configurable build options
- [ ] Set proper SHELL with error handling options

### **SSH Key Management**
- [ ] Support folder-based organization (incoming/outgoing)
- [ ] Process .pub files for authorized_keys
- [ ] Set correct permissions (700 dirs, 600/644 files)
- [ ] Copy keys to both root and dev users
- [ ] Log key processing summary

### **Common Functions**
- [ ] Use consistent parameter validation
- [ ] Implement proper error codes and messages
- [ ] Support both GUM and fallback UI modes
- [ ] Include debug logging with DEBUG flag
- [ ] Use readonly for constants
- [ ] Document function parameters and return codes

## 🏗️ **Quick Reference Patterns**

### **Bitnami Security Pattern**
```dockerfile
FROM oraclelinux:9 AS base
SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]
RUN dnf -y install --setopt=install_weak_deps=False --nodocs \
        ca-certificates curl procps && \
    dnf clean all && rm -rf /var/cache/dnf
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true
USER 1001
```

### **Homestead Service Pattern**
```yaml
services:
  workspace:
    depends_on:
      mysql: {condition: service_healthy}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
```

### **Laradock Feature Pattern**
```bash
install_development_tools() {
    install_core_tools
    [[ "${INSTALL_NODEJS:-true}" == "true" ]] && install_nodejs
    [[ "${INSTALL_PYTHON:-true}" == "true" ]] && install_python
    setup_workspace_aliases
}
```

## 🔄 **Implementation Priority**

### **Phase 1: Security (Bitnami)**
1. Multi-stage builds with security hardening
2. SHA256 verification for downloads
3. Non-root execution (USER 1001)
4. Minimal package installation

### **Phase 2: Orchestration (Homestead)**
1. Service health checks and dependencies
2. Environment-based configuration
3. Automatic service provisioning
4. Development workflow automation

### **Phase 3: Modularity (Laradock)**
1. Feature flags for tool installation
2. Workspace customization options
3. Configuration templating system
4. Comprehensive development tooling

---

## 🎯 **Final Implementation Summary**

### **Core Requirements**
1. **Security First**: Non-root execution, security hardening, minimal attack surface
2. **Modular Design**: Reusable components, clear separation of concerns
3. **Service Orchestration**: Health checks, dependency management, service discovery
4. **Developer Experience**: Modern tooling, productivity aliases, comprehensive documentation
5. **Performance**: Multi-stage builds, intelligent caching, resource optimization

### **Reference Integration**
- **Bitnami**: Security patterns, multi-stage builds, non-root execution
- **Homestead**: Service orchestration, development workflow, environment management
- **Laradock**: Modular architecture, feature flags, comprehensive tooling

### **Quality Standards**
- Comprehensive error handling with lock files and retry mechanisms
- Structured logging with appropriate levels and GUM integration
- Thorough documentation with examples and usage instructions
- Idempotent operations that handle repeated execution gracefully
- Production-ready code with security and performance optimization

**Remember**: Generate production-ready, enterprise-grade code that incorporates proven patterns from Bitnami (security), Homestead (workflow), and Laradock (modularity) for the Oracle Linux 9 development environment.