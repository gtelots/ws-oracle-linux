#!/bin/bash
# =============================================================================
# Docker-in-Docker Setup with Context Management
# =============================================================================

set -euo pipefail

setup_docker_context() {
    if [ "${INSTALL_DOCKER:-0}" = "1" ]; then
        echo "==> Setting up Docker-in-Docker with context management"
        
        # Create docker context configuration
        mkdir -p /etc/docker
        cat > /etc/docker/daemon.json << 'EOF'
{
    "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"],
    "tls": false,
    "insecure-registries": [],
    "registry-mirrors": [],
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "experimental": false,
    "features": {
        "buildkit": true
    }
}
EOF
        
        # Create Docker context script for easy management
        cat > /usr/local/bin/docker-context-setup << 'EOF'
#!/bin/bash
# Docker Context Management Script

setup_contexts() {
    echo "Setting up Docker contexts..."
    
    # Local context (default)
    docker context create local --description "Local Docker daemon" \
        --docker "host=unix:///var/run/docker.sock" 2>/dev/null || true
    
    # Docker-in-Docker context
    docker context create dind --description "Docker-in-Docker" \
        --docker "host=tcp://docker-in-docker:2376" 2>/dev/null || true
    
    # Remote context (for external Docker hosts)
    if [ -n "${DOCKER_REMOTE_HOST:-}" ]; then
        docker context create remote --description "Remote Docker host" \
            --docker "host=${DOCKER_REMOTE_HOST}" 2>/dev/null || true
    fi
    
    echo "Available Docker contexts:"
    docker context ls
}

case "${1:-}" in
    "setup")
        setup_contexts
        ;;
    "list")
        docker context ls
        ;;
    "use")
        if [ -n "${2:-}" ]; then
            docker context use "$2"
            echo "Switched to context: $2"
        else
            echo "Usage: docker-context-setup use <context-name>"
        fi
        ;;
    *)
        echo "Docker Context Management"
        echo "Usage: docker-context-setup {setup|list|use <context>}"
        echo ""
        echo "Commands:"
        echo "  setup     - Setup all Docker contexts"
        echo "  list      - List available contexts"
        echo "  use       - Switch to a specific context"
        ;;
esac
EOF
        chmod +x /usr/local/bin/docker-context-setup
        
        echo "==> Docker context management setup completed"
        echo "    Use 'docker-context-setup setup' to initialize contexts"
        echo "    Use 'docker-context-setup list' to see available contexts"
        echo "    Use 'docker-context-setup use <context>' to switch contexts"
    else
        echo "==> Skipping Docker-in-Docker setup"
    fi
}

setup_docker_context
