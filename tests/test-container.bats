#!/usr/bin/env bats
# =============================================================================
# Oracle Linux 9 Development Container - Test Suite
# =============================================================================
# Comprehensive test suite for validating container functionality
# Uses Bats (Bash Automated Testing System) for testing

# Setup function run before each test
setup() {
    # Ensure container is running
    docker compose up -d workspace
    
    # Wait for container to be ready
    timeout 30 bash -c 'until docker compose exec workspace echo "ready" 2>/dev/null; do sleep 1; done'
}

# =============================================================================
# BASIC CONTAINER TESTS
# =============================================================================

@test "Container is running and accessible" {
    run docker compose ps workspace
    [ "$status" -eq 0 ]
    [[ "$output" == *"Up"* ]]
}

@test "Container has correct user setup" {
    run docker compose exec workspace whoami
    [ "$status" -eq 0 ]
    [ "$output" = "dev" ]
}

@test "Container has correct working directory" {
    run docker compose exec workspace pwd
    [ "$status" -eq 0 ]
    [ "$output" = "/workspace" ]
}

@test "Container has proper environment variables" {
    run docker compose exec workspace bash -c 'echo $USER_NAME'
    [ "$status" -eq 0 ]
    [ "$output" = "dev" ]
}

# =============================================================================
# SYSTEM TOOLS TESTS
# =============================================================================

@test "Essential system tools are installed" {
    # Test core system utilities
    run docker compose exec workspace which curl
    [ "$status" -eq 0 ]
    
    run docker compose exec workspace which wget
    [ "$status" -eq 0 ]
    
    run docker compose exec workspace which git
    [ "$status" -eq 0 ]
    
    run docker compose exec workspace which vim
    [ "$status" -eq 0 ]
}

@test "Development tools are functional" {
    # Test Python
    run docker compose exec workspace python3 --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"Python 3"* ]]
    
    # Test Node.js
    run docker compose exec workspace node --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"v"* ]]
    
    # Test Git
    run docker compose exec workspace git --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"git version"* ]]
}

@test "Docker CLI is available and functional" {
    run docker compose exec workspace docker --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"Docker version"* ]]
}

# =============================================================================
# MODERN CLI TOOLS TESTS
# =============================================================================

@test "Modern CLI tools are installed" {
    # Test fd (find alternative)
    run docker compose exec workspace which fd
    [ "$status" -eq 0 ]

    # Test ripgrep
    run docker compose exec workspace which rg
    [ "$status" -eq 0 ]

    # Test bat (cat alternative)
    run docker compose exec workspace which bat
    [ "$status" -eq 0 ]

    # Test eza (ls alternative)
    run docker compose exec workspace which eza
    [ "$status" -eq 0 ]

    # Test fzf (fuzzy finder)
    run docker compose exec workspace which fzf
    [ "$status" -eq 0 ]

    # Test zoxide (directory jumper)
    run docker compose exec workspace which zoxide
    [ "$status" -eq 0 ]

    # Test duf (disk usage)
    run docker compose exec workspace which duf
    [ "$status" -eq 0 ]
}

@test "HTTPie is functional" {
    run docker compose exec workspace http --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"HTTPie"* ]]
}

@test "Neovim is installed and functional" {
    run docker compose exec workspace nvim --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"NVIM"* ]]
}

@test "Additional modern CLI tools are functional" {
    # Test jq
    run docker compose exec workspace jq --version
    [ "$status" -eq 0 ]

    # Test yq
    run docker compose exec workspace yq --version
    [ "$status" -eq 0 ]

    # Test btop
    run docker compose exec workspace btop --version
    [ "$status" -eq 0 ]
}

@test "Zsh shell with Zinit is available" {
    run docker compose exec workspace zsh --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"zsh"* ]]

    # Check if Zinit directory exists
    run docker compose exec workspace test -d /home/dev/.local/share/zinit
    [ "$status" -eq 0 ]
}

@test "SSH server is configured" {
    run docker compose exec workspace which sshd
    [ "$status" -eq 0 ]

    # Check SSH configuration exists
    run docker compose exec workspace test -f /etc/ssh/sshd_config
    [ "$status" -eq 0 ]
}

@test "Modern CLI tools from individual scripts are functional" {
    # Test additional modern CLI tools installed by default
    run docker compose exec workspace which just
    [ "$status" -eq 0 ]

    run docker compose exec workspace which hyperfine
    [ "$status" -eq 0 ]

    run docker compose exec workspace which choose
    [ "$status" -eq 0 ]

    run docker compose exec workspace which fastfetch
    [ "$status" -eq 0 ]

    run docker compose exec workspace which yazi
    [ "$status" -eq 0 ]
}

@test "Python tools installed via pipx" {
    # Test Python tools are installed via pipx
    run docker compose exec workspace which tldr
    [ "$status" -eq 0 ]

    run docker compose exec workspace which speedtest-cli
    [ "$status" -eq 0 ]

    run docker compose exec workspace which thefuck
    [ "$status" -eq 0 ]
}

@test "Shared aliases are available in both shells" {
    # Test shared aliases in bash
    run docker compose exec workspace bash -c "source /opt/laragis/dotfiles/aliases.sh && type ll"
    [ "$status" -eq 0 ]

    # Test shared aliases in zsh (if available)
    run docker compose exec workspace zsh -c "source /opt/laragis/dotfiles/aliases.sh && type ll"
    [ "$status" -eq 0 ]
}

@test "Enhanced bash configuration is active" {
    # Test enhanced bash configuration
    run docker compose exec workspace bash -c "echo \$HISTSIZE"
    [ "$status" -eq 0 ]
    [[ "$output" == "10000" ]]
}

@test "Language runtimes are installed and functional" {
    # Test Java
    run docker compose exec workspace java -version
    [ "$status" -eq 0 ]

    # Test Node.js
    run docker compose exec workspace node --version
    [ "$status" -eq 0 ]

    # Test Python 3.12 specifically
    run docker compose exec workspace python3.12 --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"3.12"* ]]

    # Test Python3 symlink
    run docker compose exec workspace python3 --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"3.12"* ]]

    # Test Go
    run docker compose exec workspace go version
    [ "$status" -eq 0 ]

    # Test Rust
    run docker compose exec workspace rustc --version
    [ "$status" -eq 0 ]

    # Test PHP
    run docker compose exec workspace php --version
    [ "$status" -eq 0 ]

    # Test Ruby
    run docker compose exec workspace ruby --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"3.3"* ]]
}

@test "Package managers are functional" {
    # Test Maven
    run docker compose exec workspace mvn --version
    [ "$status" -eq 0 ]

    # Test npm
    run docker compose exec workspace npm --version
    [ "$status" -eq 0 ]

    # Test Cargo
    run docker compose exec workspace cargo --version
    [ "$status" -eq 0 ]

    # Test Composer
    run docker compose exec workspace composer --version
    [ "$status" -eq 0 ]

    # Test Bundler
    run docker compose exec workspace bundle --version
    [ "$status" -eq 0 ]

    # Test pip 3.12 specifically
    run docker compose exec workspace pip3.12 --version
    [ "$status" -eq 0 ]

    # Test pip3 symlink
    run docker compose exec workspace pip3 --version
    [ "$status" -eq 0 ]
}

@test "Python 3.12 and pipx are properly configured" {
    # Test Python 3.12 is the default
    run docker compose exec workspace python3 --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"3.12"* ]]

    # Test pipx is installed and functional
    run docker compose exec workspace pipx --version
    [ "$status" -eq 0 ]

    # Test pipx can install packages
    run docker compose exec workspace pipx list
    [ "$status" -eq 0 ]
}

@test "Container health check is functional" {
    # Test health check script exists and is executable
    run docker compose exec workspace test -x /opt/laragis/scripts/health-check.sh
    [ "$status" -eq 0 ]

    # Test health check runs successfully
    run docker compose exec workspace /opt/laragis/scripts/health-check.sh
    [ "$status" -eq 0 ]
}

@test "Ruby development environment is complete" {
    # Test rbenv is available
    run docker compose exec workspace rbenv --version
    [ "$status" -eq 0 ]

    # Test Ruby version management
    run docker compose exec workspace rbenv versions
    [ "$status" -eq 0 ]
    [[ "$output" == *"3.3.6"* ]]

    # Test gem installation works
    run docker compose exec workspace gem list bundler
    [ "$status" -eq 0 ]
    [[ "$output" == *"bundler"* ]]
}

# =============================================================================
# INFRASTRUCTURE TOOLS TESTS
# =============================================================================

@test "Kubernetes tools are available" {
    # Test kubectl
    run docker compose exec workspace kubectl version --client
    [ "$status" -eq 0 ]
    
    # Test helm
    run docker compose exec workspace helm version
    [ "$status" -eq 0 ]
    
    # Test k9s
    run docker compose exec workspace k9s version
    [ "$status" -eq 0 ]
}

@test "Terraform is functional" {
    run docker compose exec workspace terraform version
    [ "$status" -eq 0 ]
    [[ "$output" == *"Terraform"* ]]
}

@test "Ansible is functional" {
    run docker compose exec workspace ansible --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"ansible"* ]]
}

# =============================================================================
# CLOUD TOOLS TESTS
# =============================================================================

@test "AWS CLI is functional" {
    run docker compose exec workspace aws --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"aws-cli"* ]]
}

@test "Cloud tunneling tools are available" {
    # Test cloudflared
    run docker compose exec workspace cloudflared --version
    [ "$status" -eq 0 ]
    
    # Test tailscale
    run docker compose exec workspace tailscale version
    [ "$status" -eq 0 ]
    
    # Test ngrok
    run docker compose exec workspace ngrok version
    [ "$status" -eq 0 ]
}

# =============================================================================
# SECURITY TOOLS TESTS
# =============================================================================

@test "Security scanning tools are available" {
    run docker compose exec workspace trivy --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"Version"* ]]
}

# =============================================================================
# TERMINAL ENHANCEMENT TESTS
# =============================================================================

@test "Terminal enhancement tools are functional" {
    # Test starship
    run docker compose exec workspace starship --version
    [ "$status" -eq 0 ]
    
    # Test zellij
    run docker compose exec workspace zellij --version
    [ "$status" -eq 0 ]
    
    # Test gum
    run docker compose exec workspace gum --version
    [ "$status" -eq 0 ]
}

# =============================================================================
# NETWORK CONNECTIVITY TESTS
# =============================================================================

@test "Container has internet connectivity" {
    run docker compose exec workspace ping -c 1 google.com
    [ "$status" -eq 0 ]
}

@test "DNS resolution works" {
    run docker compose exec workspace nslookup github.com
    [ "$status" -eq 0 ]
}

# =============================================================================
# SERVICE TESTS
# =============================================================================

@test "Supervisor is running" {
    run docker compose exec workspace supervisorctl status
    [ "$status" -eq 0 ]
}

@test "SSH service is available" {
    run docker compose exec workspace which sshd
    [ "$status" -eq 0 ]
}

# =============================================================================
# PERFORMANCE TESTS
# =============================================================================

@test "Container startup time is reasonable" {
    # Stop container
    docker compose down workspace
    
    # Measure startup time
    start_time=$(date +%s)
    docker compose up -d workspace
    
    # Wait for container to be ready
    timeout 60 bash -c 'until docker compose exec workspace echo "ready" 2>/dev/null; do sleep 1; done'
    
    end_time=$(date +%s)
    startup_time=$((end_time - start_time))
    
    # Startup should be less than 60 seconds
    [ "$startup_time" -lt 60 ]
}

@test "Container memory usage is reasonable" {
    run docker compose exec workspace bash -c 'free -m | grep Mem | awk "{print \$3}"'
    [ "$status" -eq 0 ]
    
    # Memory usage should be less than 2GB (2048MB)
    memory_used=$output
    [ "$memory_used" -lt 2048 ]
}

# =============================================================================
# CLEANUP
# =============================================================================

teardown() {
    # Optional: Clean up after tests
    # docker compose down workspace
    true
}
