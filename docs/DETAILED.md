# 🚀 Oracle Linux Development Workspace

A comprehensive development container based on Oracle Linux 9 with modern development tools, SSH server, and service management via Supervisor.

## ✨ Features

### 🔧 Core Development Tools
- **Python 3.11** with pip, poetry, virtualenv
- **Node.js** via Volta version manager
- **Git** with git-lfs support
- **Modern CLI tools**: fzf, ripgrep, bat, eza, zoxide
- **Text editors**: Neovim with LazyVim configuration
- **Shell**: Zsh with Zinit plugin manager and Starship prompt

### 🛠️ Additional Tools (Configurable)
- **Crontab** service for scheduled tasks
- **Tailscale** VPN client
- **Terraform** CLI for infrastructure as code
- **Cloudflare** CLI (cloudflared)
- **Teleport** CLI for secure access
- **Dry** - Docker terminal UI
- **WordPress CLI** for WordPress development
- **Supervisor** for service management

### 🔒 Security & Access
- **SSH Server** with customizable port
- **Organized SSH key management** (incoming/outgoing folders)
- **Non-root user** with sudo privileges
- **Password and key-based authentication**

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd ws-oracle-linux
cp build.env .env
# Edit .env to customize your configuration
```

### 2. Build and Run
```bash
# Install task runner if not available
# macOS: brew install go-task
# Linux: sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin

# Build and start container
task build
task up

# Open shell in container
task shell
```

### 3. SSH Access
```bash
# SSH into container (default port 2222)
ssh -p 2222 dev@localhost
ssh -p 2222 root@localhost
```

## ⚙️ Configuration

### Environment Variables

Copy `build.env` to `.env` and customize:

```bash
# Core configuration
TZ=Asia/Ho_Chi_Minh
USERNAME=dev
SSH_PORT=2222

# Enable/disable tools (1=enable, 0=disable)
INSTALL_CRONTAB=1
INSTALL_TAILSCALE=0
INSTALL_TERRAFORM=1
INSTALL_CLOUDFLARE=1
INSTALL_TELEPORT=0
INSTALL_DRY=1
INSTALL_WP_CLI=1
INSTALL_SUPERVISOR=1

# Specify versions
TERRAFORM_VERSION=1.10.3
WP_CLI_VERSION=2.12.0
CLOUDFLARE_VERSION=2024.12.2
```

### SSH Key Management

Organize your SSH keys in the `.ssh/` directory:

```
.ssh/
├── incoming/          # Keys for accessing this workspace
│   ├── id_rsa.pub    # Public keys added to authorized_keys
│   └── id_ed25519    # Private keys for incoming connections
├── outgoing/          # Keys for accessing external servers
│   ├── github_key    # Private keys for outgoing connections
│   └── server_key.pub
├── config            # SSH client configuration
└── known_hosts       # Known hosts file
```

## 📋 Available Tasks

Run `task help` for full list of available commands:

### Container Management
```bash
task build              # Build container with current settings
task build-minimal      # Build minimal container (SSH only)
task build-full         # Build with all tools enabled
task up                 # Start container
task down               # Stop container
task restart            # Restart container
task rebuild            # Rebuild and restart
```

### Development
```bash
task shell              # Open Zsh shell as dev user
task root               # Open shell as root user
task ssh                # SSH into container
task logs               # Show container logs
task tools-list         # List installed tools
```

### Maintenance
```bash
task clean              # Clean Docker resources
task clean-all          # Full cleanup
task env-check          # Validate configuration
```

## 🔧 Installed Tools by Category

### System & Core
- Oracle Linux 9 with EPEL repository
- Modern GNU/Linux utilities
- Essential development packages

### Version Control & Collaboration
- Git with LFS support
- LazyGit TUI interface

### Programming Languages
- Python 3.11 with pip, poetry, virtualenv
- Node.js via Volta (with npm, yarn, pnpm)

### Container & Infrastructure
- Docker CLI tools
- Kubernetes tools (kubectl, helm, k9s)
- Terraform CLI
- LazyDocker TUI

### Cloud & Networking
- Cloudflare CLI (cloudflared)
- Tailscale VPN client
- Teleport CLI

### WordPress Development
- WordPress CLI
- PHP runtime

### Text Editors & Shell
- Neovim with LazyVim
- Zsh with modern plugins
- Starship prompt

### System Management
- Supervisor for service management
- Crontab for scheduled tasks
- SSH server with security hardening

## 🐳 Build Variants

### Minimal Build (SSH only)
```bash
task build-minimal
```
Includes only SSH server and basic tools.

### Full Build (All tools)
```bash
task build-full
```
Includes all available tools and services.

### Custom Build
```bash
docker build \
  --build-arg INSTALL_TERRAFORM=1 \
  --build-arg INSTALL_WP_CLI=0 \
  --build-arg TERRAFORM_VERSION=1.9.0 \
  -t ws-oracle-linux-custom .
```

## 🔒 Security Considerations

- Default passwords: `root:root` and `dev:dev` (change after deployment)
- SSH server with customizable port (default: 2222)
- Non-root user with sudo privileges
- Organized SSH key management
- Firewall-friendly design

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Test your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Oracle Linux team for the base image
- All open source projects included in this container
- LazyVim community for the excellent Neovim configuration

---

**Happy coding! 🎉**
