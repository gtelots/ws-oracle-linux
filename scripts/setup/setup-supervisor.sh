#!/bin/bash
# -----------------------------------------------------------------------------
# Supervisor Configuration Script
# -----------------------------------------------------------------------------
# This script sets up supervisor configuration for managing multiple services
# -----------------------------------------------------------------------------

set -euo pipefail

# Function to log messages
log() {
    echo "==> $1"
}

# Create supervisor main configuration
create_supervisor_config() {
    log "Creating supervisor main configuration"
    
    cat > /etc/supervisor/supervisord.conf << 'EOF'
[unix_http_server]
file=/tmp/supervisor.sock
chmod=0700

[supervisord]
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
childlogdir=/var/log/supervisor
user=root
nodaemon=true

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///tmp/supervisor.sock

[include]
files = /etc/supervisor/conf.d/*.conf
EOF
}

# Create SSH service configuration
create_ssh_service() {
    if [ "${INSTALL_OPENSSH_SERVER:-1}" = "1" ]; then
        log "Creating SSH service configuration for supervisor"
        
        cat > /etc/supervisor/conf.d/ssh.conf << EOF
[program:sshd]
command=/usr/local/bin/start-sshd
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/sshd.err.log
stdout_logfile=/var/log/supervisor/sshd.out.log
user=root
EOF
    fi
}

# Create cron service configuration
create_cron_service() {
    if [ "${INSTALL_CRONTAB:-0}" = "1" ]; then
        log "Creating cron service configuration for supervisor"
        
        cat > /etc/supervisor/conf.d/cron.conf << 'EOF'
[program:cron]
command=/usr/sbin/crond -n
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/cron.err.log
stdout_logfile=/var/log/supervisor/cron.out.log
user=root
EOF
    fi
}

# Create Docker service configuration
create_docker_service() {
    if [ "${INSTALL_DOCKER:-0}" = "1" ]; then
        log "Creating Docker service configuration for supervisor"
        
        cat > /etc/supervisor/conf.d/docker.conf << 'EOF'
[program:dockerd]
command=/usr/bin/dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/dockerd.err.log
stdout_logfile=/var/log/supervisor/dockerd.out.log
user=root
environment=HOME="/root"
EOF
    fi
}

# Create Tailscale service configuration
create_tailscale_service() {
    if [ "${INSTALL_TAILSCALE:-0}" = "1" ]; then
        log "Creating Tailscale service configuration for supervisor"
        
        cat > /etc/supervisor/conf.d/tailscale.conf << 'EOF'
[program:tailscaled]
command=/usr/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock
autostart=false
autorestart=true
stderr_logfile=/var/log/supervisor/tailscaled.err.log
stdout_logfile=/var/log/supervisor/tailscaled.out.log
user=root
directory=/tmp
environment=HOME="/root"
EOF
    fi
}

# Create startup script for supervisor
create_supervisor_startup() {
    log "Creating supervisor startup script"
    
    cat > /usr/local/bin/start-supervisor << 'EOF'
#!/bin/bash
# Create log directory
mkdir -p /var/log/supervisor

    # Create Tailscale state directory if needed
    if [ "${INSTALL_TAILSCALE:-0}" = "1" ]; then
        mkdir -p /var/lib/tailscale /var/run/tailscale
    fi
    
    # Create Docker state directory if needed
    if [ "${INSTALL_DOCKER:-0}" = "1" ]; then
        mkdir -p /var/lib/docker /var/run/docker
    fi# Start supervisor
exec /usr/local/bin/supervisord -c /etc/supervisor/supervisord.conf
EOF
    
    chmod +x /usr/local/bin/start-supervisor
}

# Main configuration function
main() {
    log "Setting up supervisor configuration"
    
    # Create supervisor directories
    mkdir -p /etc/supervisor/conf.d /var/log/supervisor
    
    # Create configurations
    create_supervisor_config
    create_ssh_service
    create_cron_service
    create_docker_service
    create_tailscale_service
    create_supervisor_startup
    
    log "Supervisor configuration completed"
}

# Run main function
main "$@"
