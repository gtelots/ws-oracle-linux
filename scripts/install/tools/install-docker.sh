#!/bin/bash
# -----------------------------------------------------------------------------
# Docker-in-Docker Installation Script
# -----------------------------------------------------------------------------
# This script installs Docker engine inside the container for DinD functionality
# -----------------------------------------------------------------------------

set -euo pipefail

# Function to log messages
log() {
    echo "==> $1"
}

# Install Docker-in-Docker
install_docker() {
    if [ "${INSTALL_DOCKER:-0}" = "1" ]; then
        local version="${DOCKER_VERSION:-27.4.1}"
        log "Installing Docker-in-Docker v$version"
        
        # Add Docker repository
        dnf -y install --setopt=install_weak_deps=False --nodocs dnf-plugins-core
        dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        
        # Install Docker Engine
        dnf -y install --setopt=install_weak_deps=False --nodocs \
            docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        # Create docker group and add user
        groupadd -f docker
        usermod -aG docker root
        
        # Set up Docker daemon configuration for DinD
        mkdir -p /etc/docker
        cat > /etc/docker/daemon.json << 'EOF'
{
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "features": {
        "buildkit": true
    }
}
EOF
        
        log "Docker-in-Docker v$version installed successfully"
        log "Note: Container must run with --privileged flag for DinD to work"
    else
        log "Skipping Docker-in-Docker installation"
    fi
}

# Run installation
install_docker
