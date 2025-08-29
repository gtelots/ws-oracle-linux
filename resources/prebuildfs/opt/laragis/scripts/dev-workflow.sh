#!/usr/bin/env bash
# =============================================================================
# Development Workflow Automation Script
# =============================================================================
# DESCRIPTION: Automate common development workflows and project setup
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly SCRIPT_NAME="dev-workflow"
readonly WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
readonly PROJECTS_DIR="${WORKSPACE_DIR}/projects"

show_help() {
    cat << EOF
Development Workflow Automation Script

USAGE:
    $SCRIPT_NAME <command> [options]

COMMANDS:
    init <type> <name>     Initialize a new project
    setup-git <name>       Setup Git configuration
    install-deps <type>    Install project dependencies
    run-tests <type>       Run tests for project type
    format-code <type>     Format code using language-specific tools
    lint-code <type>       Lint code using language-specific tools
    build <type>           Build project
    deploy <type>          Deploy project (development)
    status                 Show development environment status
    cleanup                Clean up temporary files and caches

PROJECT TYPES:
    java, rust, go, nodejs, php, ruby, python

OPTIONS:
    -h, --help            Show this help message
    -v, --verbose         Enable verbose output
    -d, --directory DIR   Specify project directory

EXAMPLES:
    $SCRIPT_NAME init nodejs my-app
    $SCRIPT_NAME setup-git "John Doe"
    $SCRIPT_NAME install-deps nodejs
    $SCRIPT_NAME run-tests python
    $SCRIPT_NAME format-code rust
    $SCRIPT_NAME status
EOF
}

init_project() {
    local project_type="$1"
    local project_name="$2"
    local project_dir="${PROJECTS_DIR}/${project_name}"
    
    log_info "Initializing ${project_type} project: ${project_name}"
    
    # Create project directory
    mkdir -p "$project_dir"
    cd "$project_dir"
    
    case "$project_type" in
        "java")
            if command -v mvn >/dev/null 2>&1; then
                mvn archetype:generate -DgroupId=com.example -DartifactId="$project_name" \
                    -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
            else
                log_error "Maven not available for Java project initialization"
                return 1
            fi
            ;;
        "rust")
            if command -v cargo >/dev/null 2>&1; then
                cargo init --name "$project_name"
            else
                log_error "Cargo not available for Rust project initialization"
                return 1
            fi
            ;;
        "go")
            if command -v go >/dev/null 2>&1; then
                go mod init "$project_name"
                cat > main.go << 'EOF'
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
EOF
            else
                log_error "Go not available for Go project initialization"
                return 1
            fi
            ;;
        "nodejs")
            if command -v npm >/dev/null 2>&1; then
                npm init -y
                npm install --save-dev eslint prettier jest
            else
                log_error "npm not available for Node.js project initialization"
                return 1
            fi
            ;;
        "php")
            if command -v composer >/dev/null 2>&1; then
                composer init --no-interaction --name="vendor/$project_name"
            else
                log_error "Composer not available for PHP project initialization"
                return 1
            fi
            ;;
        "ruby")
            if command -v bundle >/dev/null 2>&1; then
                /usr/local/bin/init-ruby-project "$project_name" gem
            else
                log_error "Bundler not available for Ruby project initialization"
                return 1
            fi
            ;;
        "python")
            if command -v python3 >/dev/null 2>&1; then
                /usr/local/bin/init-python-project "$project_name"
            else
                log_error "Python not available for Python project initialization"
                return 1
            fi
            ;;
        *)
            log_error "Unsupported project type: $project_type"
            return 1
            ;;
    esac
    
    log_success "Project ${project_name} initialized successfully"
}

setup_git() {
    local user_name="$1"
    local user_email="$2"
    
    log_info "Setting up Git configuration..."
    
    if [[ -n "$user_name" ]]; then
        git config --global user.name "$user_name"
    fi
    
    if [[ -n "$user_email" ]]; then
        git config --global user.email "$user_email"
    fi
    
    # Set up common Git configurations
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf input
    git config --global core.editor vim
    
    # Initialize git in current directory if not already initialized
    if [[ ! -d ".git" ]]; then
        git init
        echo "# $(basename "$PWD")" > README.md
        git add README.md
        git commit -m "Initial commit"
    fi
    
    log_success "Git configuration completed"
}

install_dependencies() {
    local project_type="$1"
    
    log_info "Installing dependencies for ${project_type} project..."
    
    case "$project_type" in
        "java")
            [[ -f "pom.xml" ]] && mvn clean install
            [[ -f "build.gradle" ]] && gradle build
            ;;
        "rust")
            [[ -f "Cargo.toml" ]] && cargo build
            ;;
        "go")
            [[ -f "go.mod" ]] && go mod tidy && go mod download
            ;;
        "nodejs")
            [[ -f "package.json" ]] && npm install
            ;;
        "php")
            [[ -f "composer.json" ]] && composer install
            ;;
        "ruby")
            [[ -f "Gemfile" ]] && bundle install
            ;;
        "python")
            [[ -f "requirements.txt" ]] && pip install -r requirements.txt
            [[ -f "pyproject.toml" ]] && pip install -e .
            ;;
        *)
            log_error "Unsupported project type: $project_type"
            return 1
            ;;
    esac
    
    log_success "Dependencies installed successfully"
}

run_tests() {
    local project_type="$1"
    
    log_info "Running tests for ${project_type} project..."
    
    case "$project_type" in
        "java")
            [[ -f "pom.xml" ]] && mvn test
            [[ -f "build.gradle" ]] && gradle test
            ;;
        "rust")
            [[ -f "Cargo.toml" ]] && cargo test
            ;;
        "go")
            [[ -f "go.mod" ]] && go test ./...
            ;;
        "nodejs")
            [[ -f "package.json" ]] && npm test
            ;;
        "php")
            [[ -f "phpunit.xml" ]] && ./vendor/bin/phpunit
            ;;
        "ruby")
            [[ -f "Gemfile" ]] && bundle exec rspec
            ;;
        "python")
            [[ -f "pytest.ini" ]] && pytest
            [[ -f "setup.py" ]] && python -m unittest discover
            ;;
        *)
            log_error "Unsupported project type: $project_type"
            return 1
            ;;
    esac
    
    log_success "Tests completed"
}

format_code() {
    local project_type="$1"
    
    log_info "Formatting code for ${project_type} project..."
    
    case "$project_type" in
        "java")
            find . -name "*.java" -exec google-java-format -i {} \; 2>/dev/null || log_warn "google-java-format not available"
            ;;
        "rust")
            [[ -f "Cargo.toml" ]] && cargo fmt
            ;;
        "go")
            [[ -f "go.mod" ]] && go fmt ./...
            ;;
        "nodejs")
            [[ -f ".prettierrc" ]] && npx prettier --write .
            ;;
        "php")
            find . -name "*.php" -exec php-cs-fixer fix {} \; 2>/dev/null || log_warn "php-cs-fixer not available"
            ;;
        "ruby")
            [[ -f "Gemfile" ]] && bundle exec rubocop -a
            ;;
        "python")
            command -v black >/dev/null && black .
            command -v isort >/dev/null && isort .
            ;;
        *)
            log_error "Unsupported project type: $project_type"
            return 1
            ;;
    esac
    
    log_success "Code formatting completed"
}

show_status() {
    log_info "Development Environment Status"
    
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Uptime: $(uptime -p)"
    echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
    echo "Disk: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5" used)"}')"
    
    echo -e "\n=== Language Runtimes ==="
    command -v java >/dev/null && echo "Java: $(java -version 2>&1 | head -n1)"
    command -v rustc >/dev/null && echo "Rust: $(rustc --version)"
    command -v go >/dev/null && echo "Go: $(go version)"
    command -v node >/dev/null && echo "Node.js: $(node --version)"
    command -v php >/dev/null && echo "PHP: $(php --version | head -n1)"
    command -v ruby >/dev/null && echo "Ruby: $(ruby --version)"
    command -v python3 >/dev/null && echo "Python: $(python3 --version)"
    
    echo -e "\n=== Development Tools ==="
    command -v git >/dev/null && echo "Git: $(git --version)"
    command -v docker >/dev/null && echo "Docker: $(docker --version)"
    command -v vim >/dev/null && echo "Vim: $(vim --version | head -n1)"
    
    echo -e "\n=== Project Directories ==="
    [[ -d "$PROJECTS_DIR" ]] && echo "Projects: $(ls -1 "$PROJECTS_DIR" 2>/dev/null | wc -l) projects in $PROJECTS_DIR"
    [[ -d "$WORKSPACE_DIR" ]] && echo "Workspace: $WORKSPACE_DIR ($(du -sh "$WORKSPACE_DIR" 2>/dev/null | cut -f1))"
}

cleanup() {
    log_info "Cleaning up development environment..."
    
    # Clean package manager caches
    command -v dnf >/dev/null && dnf clean all
    command -v npm >/dev/null && npm cache clean --force
    command -v pip3 >/dev/null && pip3 cache purge
    command -v cargo >/dev/null && cargo clean
    
    # Clean temporary files
    find /tmp -name "*.tmp" -delete 2>/dev/null
    find "$HOME" -name ".DS_Store" -delete 2>/dev/null
    
    # Clean log files older than 7 days
    find /var/log -name "*.log" -mtime +7 -delete 2>/dev/null
    
    log_success "Cleanup completed"
}

# Main function
main() {
    local command="$1"
    shift
    
    case "$command" in
        "init")
            init_project "$@"
            ;;
        "setup-git")
            setup_git "$@"
            ;;
        "install-deps")
            install_dependencies "$@"
            ;;
        "run-tests")
            run_tests "$@"
            ;;
        "format-code")
            format_code "$@"
            ;;
        "status")
            show_status
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
