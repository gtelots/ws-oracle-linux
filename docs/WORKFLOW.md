# Development Workflow Guide

## Daily Development Workflow

### 1. Starting Your Development Session
```bash
# Start the development environment
task up

# Access your development container
task shell                    # Zsh shell with all tools
# OR
ssh -p 2222 dev@localhost     # SSH access
```

### 2. Development Tools Usage

#### Git Operations
```bash
# Git is pre-configured with modern aliases
git status                    # Check repository status
lg                           # Beautiful git log (alias for lazygit)
lazygit                      # Interactive git TUI

# SSH keys for external repositories are in ~/.ssh/outgoing/
git clone git@github.com:user/repo.git
```

#### Python Development
```bash
# Python 3.11 with modern tooling
python --version             # Python 3.11
poetry --version             # Dependency management
pip install package          # Package installation

# Create virtual environment
python -m venv venv
source venv/bin/activate
```

#### Node.js Development
```bash
# Node.js via Volta version manager
node --version               # Current Node.js version
npm --version                # NPM package manager
volta install node@18       # Switch Node.js versions
volta install node@latest   # Install latest LTS

# Package managers
npm install package          # NPM
yarn add package            # Yarn
pnpm add package            # PNPM
```

#### Container Management
```bash
# Docker operations (if Docker-in-Docker enabled)
docker ps                    # List containers
docker build -t myapp .      # Build images
dry                         # Docker TUI interface

# Kubernetes operations (if K8s tools enabled)
kubectl get pods            # Kubernetes CLI
helm list                   # Helm charts
k9s                         # Kubernetes TUI
```

### 3. Infrastructure Management

#### Terraform Operations
```bash
# Infrastructure as code
terraform init               # Initialize Terraform
terraform plan              # Plan infrastructure changes
terraform apply             # Apply changes
terraform destroy           # Destroy infrastructure
```

#### WordPress Development
```bash
# WordPress CLI operations
wp core download            # Download WordPress
wp config create            # Create wp-config.php
wp db create                # Create database
wp plugin install          # Install plugins
wp theme activate          # Activate themes
```

#### Cloudflare Management
```bash
# Cloudflare tunnel operations
cloudflared tunnel login    # Authenticate
cloudflared tunnel create myapp
cloudflared tunnel run myapp
```

### 4. Networking & Tunneling

#### Ngrok Tunneling
```bash
# Expose local services (if ngrok enabled)
ngrok http 3000             # Expose port 3000
ngrok tcp 22                # Expose TCP port
ngrok authtoken YOUR_TOKEN  # Set auth token
```

#### Tailscale VPN
```bash
# VPN networking (if Tailscale enabled)
tailscale up               # Connect to tailnet
tailscale status           # Check connection status
tailscale ip               # Show assigned IP
```

## File Organization

### Project Structure
```
/workspace/                  # Main workspace directory
├── projects/               # Your development projects
│   ├── web-app/           # Web application
│   ├── api-service/       # API service
│   └── infrastructure/    # Terraform configs
├── scripts/               # Utility scripts
└── docs/                  # Documentation
```

### SSH Key Organization
```
~/.ssh/
├── incoming/              # Keys for accessing this workspace
│   ├── laptop.pub        # Your laptop's public key
│   ├── desktop.pub       # Desktop public key
│   └── ci-cd.pub         # CI/CD system key
├── outgoing/              # Keys for external services
│   ├── github-personal   # GitHub personal account
│   ├── github-work       # GitHub work account
│   ├── gitlab-key        # GitLab key
│   ├── aws-key           # AWS server key
│   └── staging-server    # Staging server key
├── config                # SSH client configuration
└── known_hosts           # Known hosts
```

### SSH Config Example
```bash
# ~/.ssh/config

# GitHub accounts
Host github-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/outgoing/github-personal

Host github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/outgoing/github-work

# Servers
Host staging
    HostName staging.company.com
    User deploy
    Port 22
    IdentityFile ~/.ssh/outgoing/staging-server

Host production
    HostName prod.company.com
    User deploy
    Port 22
    IdentityFile ~/.ssh/outgoing/production-server
```

## Service Management

### Using Supervisor
```bash
# Check all services status
supervisorctl status

# Manage specific services
supervisorctl start sshd
supervisorctl stop dockerd
supervisorctl restart cron

# View service logs
supervisorctl tail sshd stdout
supervisorctl tail dockerd stderr

# Follow logs in real-time
supervisorctl tail -f sshd
```

### Cron Jobs Management
```bash
# Edit crontab
crontab -e

# List current cron jobs
crontab -l

# Example cron jobs
# Backup every day at 2 AM
0 2 * * * /workspace/scripts/backup.sh

# Update SSL certificates weekly
0 0 * * 0 /workspace/scripts/update-certs.sh

# Health check every 5 minutes
*/5 * * * * curl -f http://localhost:3000/health || echo "Service down"
```

## Best Practices

### 1. Security
- Always use SSH keys instead of passwords
- Rotate SSH keys regularly
- Use different keys for different purposes
- Keep private keys secure and never commit them
- Use strong passwords for user accounts

### 2. Development
- Use version managers (Volta for Node.js)
- Create virtual environments for Python projects
- Use container-specific configurations
- Document your development setup
- Use meaningful commit messages

### 3. Infrastructure
- Use Terraform for infrastructure management
- Version control your infrastructure code
- Test infrastructure changes in staging first
- Use proper tagging and naming conventions
- Monitor resource usage and costs

### 4. Backup & Recovery
- Regular backup of important data
- Version control for all code and configurations
- Document recovery procedures
- Test backup restoration regularly

### 5. Performance
- Monitor container resource usage
- Clean up unused Docker images and containers
- Use .dockerignore for faster builds
- Optimize Dockerfile layers
- Regular system maintenance

## Common Workflows

### 1. New Project Setup
```bash
# Start container
task up && task shell

# Create project directory
mkdir -p /workspace/projects/my-new-project
cd /workspace/projects/my-new-project

# Initialize project
git init
# OR
npm create vite@latest .
# OR
poetry new my-project
```

### 2. Deploying with Terraform
```bash
cd /workspace/projects/infrastructure

# Initialize and plan
terraform init
terraform plan -out=plan.out

# Review and apply
terraform show plan.out
terraform apply plan.out

# Clean up
terraform destroy
```

### 3. WordPress Development
```bash
# Create new WordPress site
mkdir -p /workspace/projects/wordpress-site
cd /workspace/projects/wordpress-site

# Download and configure WordPress
wp core download
wp config create --dbname=mydb --dbuser=user --dbpass=pass
wp core install --title="My Site" --admin_user=admin --admin_email=admin@example.com

# Development workflow
wp plugin install contact-form-7 --activate
wp theme install twentytwentyfour --activate
```

### 4. Container Development
```bash
# If Docker-in-Docker is enabled
cd /workspace/projects/my-app

# Build and run containers
docker build -t my-app .
docker run -d -p 3000:3000 my-app

# Use Docker Compose
docker compose up -d

# Monitor with dry
dry
```

## Troubleshooting Common Issues

### SSH Connection Problems
```bash
# Check SSH service status
task health

# Restart SSH service
supervisorctl restart sshd

# Check SSH configuration
sshd -T
```

### Performance Issues
```bash
# Check container resources
docker stats

# Check disk usage
df -h
du -sh /workspace/*

# Clean up
task clean
```

### Tool-specific Issues
```bash
# Python package conflicts
python -m pip install --upgrade pip
pip check

# Node.js version issues
volta list
volta install node@lts

# Docker space issues
docker system prune -a
```
