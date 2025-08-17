# Configuration Guide

## Environment Variables

### Core System Configuration
```bash
# Basic container settings
TZ=Asia/Ho_Chi_Minh          # Container timezone
USERNAME=dev                  # Default user name
USER_UID=1000                # User ID for file permissions
USER_GID=1000                # Group ID for file permissions
```

### SSH Configuration
```bash
INSTALL_OPENSSH_SERVER=1     # Enable SSH server
SSH_PORT=22                  # SSH port inside container
SSH_FORWARD_PORT=2222        # Host port mapping
```

### Development Tools
```bash
# Core development stack
INSTALL_PYTHON=1             # Python 3.11 with pip, poetry
INSTALL_VOLTA=1              # Node.js version manager
INSTALL_ANSIBLE=1            # Configuration management
INSTALL_K8S=1               # Kubernetes tools (kubectl, helm, k9s)

# Additional tools (1=enable, 0=disable)
INSTALL_CRONTAB=1           # Scheduled tasks
INSTALL_NGROK=0             # Secure tunneling
INSTALL_TAILSCALE=0         # VPN networking
INSTALL_TERRAFORM=1         # Infrastructure as code
INSTALL_CLOUDFLARE=1        # Cloudflare CLI
INSTALL_TELEPORT=0          # Secure access
INSTALL_DRY=1              # Docker UI
INSTALL_WP_CLI=1           # WordPress CLI
INSTALL_DOCKER=0           # Docker-in-Docker
INSTALL_SUPERVISOR=1       # Process management
```

### Version Management
```bash
# Specify exact versions for reproducible builds
TERRAFORM_VERSION=1.10.3
WP_CLI_VERSION=2.12.0
CLOUDFLARE_VERSION=2024.12.2
NGROK_VERSION=3.18.4
TAILSCALE_VERSION=1.84.1
TELEPORT_VERSION=17.1.5
DRY_VERSION=0.11.2
DOCKER_VERSION=27.4.1

# CLI Tools
TASK_VERSION=3.44.1
LAZYDOCKER_VERSION=0.24.1
LAZYGIT_VERSION=0.54.2
YQ_VERSION=4.47.1

# Kubernetes Tools
KUBECTL_VERSION=1.31.12
HELM_VERSION=3.18.0
K9S_VERSION=0.50.9
```

## SSH Key Management

### Directory Structure
```
.ssh/
├── incoming/          # Keys for accessing this workspace
├── outgoing/          # Keys for accessing external servers
├── config            # SSH client configuration
└── known_hosts       # Known hosts file
```

### Incoming Keys (Workspace Access)
Place public keys in `incoming/` to allow access to this workspace:
```bash
cp ~/.ssh/id_rsa.pub .ssh/incoming/my-key.pub
```

### Outgoing Keys (External Server Access)
Place keys in `outgoing/` for connecting to external servers:
```bash
cp ~/.ssh/github_key .ssh/outgoing/
cp ~/.ssh/server_key .ssh/outgoing/
```

### SSH Config Example
```bash
# .ssh/config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/outgoing/github_key

Host production-server
    HostName 192.168.1.100
    User deploy
    Port 22
    IdentityFile ~/.ssh/outgoing/server_key
```

## Custom Certificates

### Adding Enterprise CA Certificates
```bash
# Place certificates in ca-certificates directory
cp /path/to/company-root-ca.crt ./ca-certificates/
cp /path/to/internal-ca.crt ./ca-certificates/

# Rebuild container to apply
task rebuild
```

### Supported Certificate Formats
- `.crt` files (PEM format)
- `.pem` files (PEM format)

## Docker-in-Docker Configuration

### Enable Docker-in-Docker
```bash
# In .env file
INSTALL_DOCKER=1
DOCKER_VERSION=27.4.1
```

### Container Requirements
```bash
# Must run with privileged mode
docker run --privileged -d ws-oracle-linux

# Or in docker-compose.yml
services:
  workspace:
    privileged: true
```

### Docker Daemon Configuration
The container includes optimized Docker daemon settings:
```json
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
```

## Service Management with Supervisor

### Configuration Location
- Main config: `/etc/supervisor/supervisord.conf`
- Service configs: `/etc/supervisor/conf.d/`

### Available Services
- **SSH Server** - Always enabled if SSH is installed
- **Cron Service** - Enabled if `INSTALL_CRONTAB=1`
- **Docker Daemon** - Enabled if `INSTALL_DOCKER=1`
- **Tailscale** - Enabled if `INSTALL_TAILSCALE=1` (manual start)

### Managing Services
```bash
# Check service status
supervisorctl status

# Start/stop services
supervisorctl start sshd
supervisorctl stop dockerd
supervisorctl restart cron

# View logs
supervisorctl tail sshd
supervisorctl tail dockerd stderr
```

## Advanced Build Configuration

### Minimal Build
```bash
docker build \
  --build-arg INSTALL_CRONTAB=0 \
  --build-arg INSTALL_TERRAFORM=0 \
  --build-arg INSTALL_WP_CLI=0 \
  --build-arg INSTALL_SUPERVISOR=0 \
  -t ws-oracle-linux-minimal .
```

### Development Build
```bash
docker build \
  --build-arg INSTALL_TERRAFORM=1 \
  --build-arg INSTALL_DOCKER=1 \
  --build-arg INSTALL_WP_CLI=1 \
  -t ws-oracle-linux-dev .
```

### Production Build
```bash
docker build \
  --build-arg INSTALL_NGROK=0 \
  --build-arg INSTALL_DRY=0 \
  --build-arg INSTALL_TAILSCALE=1 \
  --build-arg INSTALL_TERRAFORM=1 \
  -t ws-oracle-linux-prod .
```

## Troubleshooting

### Common Issues

#### SSH Connection Refused
```bash
# Check if SSH service is running
task health

# Check SSH port mapping
docker compose ps

# Test SSH connectivity
ssh -p 2222 -o ConnectTimeout=5 dev@localhost
```

#### Container Won't Start
```bash
# Check container logs
task logs

# Check Docker daemon
docker system info

# Rebuild with no cache
task rebuild
```

#### Tools Not Found
```bash
# Check tool installation status
task tools

# Verify environment variables
grep INSTALL_ .env

# Rebuild with correct settings
task rebuild
```

### Debug Mode
Enable verbose logging:
```bash
# Set debug environment
DEBUG=1 task up

# Or check container internals
task root
journalctl -f
```
