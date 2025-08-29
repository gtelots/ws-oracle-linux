# 🐧 Oracle Linux 9 Development Container

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![Oracle Linux](https://img.shields.io/badge/Oracle%20Linux-9-red.svg)](https://www.oracle.com/linux/)

A comprehensive, production-ready development environment built on Oracle Linux 9 with modern tooling, beautiful UI, and optimized architecture. This container provides everything you need for modern software development, DevOps, and cloud-native application development.

## ✨ **Key Features**

- 🏗️ **Enterprise-Grade Foundation**: Built on Oracle Linux 9 for stability and security
- 🛠️ **Comprehensive Toolset**: 25+ modern development tools pre-installed
- 🔒 **Security-First**: Non-root user, security updates, and best practices
- 🚀 **Performance Optimized**: Docker layer caching and optimized build process
- 🎨 **Beautiful Terminal**: Starship prompt, Zellij multiplexer, and modern CLI tools
- 🔧 **Highly Configurable**: Selective tool installation via environment variables
- 📦 **Container-Ready**: Docker-in-Docker support and container management tools
- ☁️ **Cloud-Native**: Kubernetes, AWS, and multi-cloud development support

## 🚀 **Quick Start**

### **Prerequisites**
- Docker Engine 20.10+ with BuildKit support
- Docker Compose 2.0+
- Task (optional, for enhanced workflow)

### **Installation**

```bash
# Clone the repository
git clone https://github.com/gtelots/ws-oracle-linux.git
cd ws-oracle-linux

# Copy and customize environment configuration
cp .env.example .env
# Edit .env to customize your installation

# Start the development environment
task up

# Access the container
task shell
# or via SSH (default password: dev)
ssh -p 2222 dev@localhost
```

### **Alternative: Docker Compose Only**

```bash
# Start with Docker Compose
docker compose up -d

# Access the container
docker compose exec workspace bash
```

## 📁 **Project Structure**

```
ws-oracle-linux/
├── Dockerfile                 # Main container definition
├── docker-compose.yml        # Container orchestration
├── Taskfile.yml             # Task automation and workflows
├── .env.example             # Environment configuration template
├── resources/               # Container resources and configurations
│   ├── prebuildfs/         # Pre-build filesystem structure
│   │   └── opt/laragis/    # Custom tooling and scripts
│   │       ├── tools/      # Individual tool installation scripts
│   │       ├── setup/      # System setup scripts
│   │       └── lib/        # Shared libraries and utilities
│   ├── rootfs/             # Runtime filesystem additions
│   ├── dotfiles/           # Shell configuration and aliases
│   └── ca-certificates/    # Custom CA certificates
├── docs/                   # Documentation and guides
├── tests/                  # Container testing framework
└── samples/                # Example configurations and templates
```

## 🛠️ **Available Commands**

### **Container Management**
```bash
task up                     # Start the development container
task down                   # Stop the development container
task restart                # Restart the development container
task build                  # Build the container image
task rebuild                # Rebuild and restart the container
task fresh                  # Fresh install (rebuild everything)
```

### **Development Workflow**
```bash
task shell                  # Open a shell in the container
task root                   # Open a shell as root user
task ssh                    # SSH into the container
task logs                   # Show container logs
task ps                     # Show container status
```

### **Utilities**
```bash
task clean                  # Clean up Docker resources
task clean-all              # Full cleanup including images and volumes
task tools                  # List installed tools and versions
task health                 # Check container health status
```

## 🔧 **Installed Tools**

### **Infrastructure and DevOps**
| Tool | Version | Description | Repository |
|------|---------|-------------|------------|
| **Ansible** | 11.9.0 | Infrastructure automation and configuration management | [ansible/ansible](https://github.com/ansible/ansible) |
| **Terraform** | 1.13.0 | Infrastructure as Code tool | [hashicorp/terraform](https://github.com/hashicorp/terraform) |
| **Teleport** | 18.1.6 | Secure access to infrastructure | [gravitational/teleport](https://github.com/gravitational/teleport) |

### **Kubernetes Ecosystem**
| Tool | Version | Description | Repository |
|------|---------|-------------|------------|
| **kubectl** | 1.31.12 | Kubernetes command-line interface | [kubernetes/kubernetes](https://github.com/kubernetes/kubernetes) |
| **Helm** | 3.18.6 | Kubernetes package manager | [helm/helm](https://github.com/helm/helm) |
| **k9s** | 0.50.9 | Terminal-based Kubernetes cluster management | [derailed/k9s](https://github.com/derailed/k9s) |

### **Container and Docker Tools**
| Tool | Version | Description | Repository |
|------|---------|-------------|------------|
| **Docker CLI** | 28.3.2 | Official Docker command-line interface | [docker/cli](https://github.com/docker/cli) |
| **dry** | 0.11.2 | Interactive Docker container manager | [moncho/dry](https://github.com/moncho/dry) |
| **lazydocker** | 0.24.1 | Lazy Docker management interface | [jesseduffield/lazydocker](https://github.com/jesseduffield/lazydocker) |

### **Cloud Platform Tools**
| Tool | Version | Description | Repository |
|------|---------|-------------|------------|
| **AWS CLI** | 2.28.16 | Amazon Web Services command-line interface | [aws/aws-cli](https://github.com/aws/aws-cli) |
| **Cloudflared** | 2025.8.1 | Cloudflare Tunnel client | [cloudflare/cloudflared](https://github.com/cloudflare/cloudflared) |
| **Tailscale** | 1.86.2 | Zero-config VPN solution | [tailscale/tailscale](https://github.com/tailscale/tailscale) |
| **ngrok** | 3.26.0 | Secure tunneling service | [ngrok.com](https://ngrok.com) |

### **Version Control and Development**
| Tool | Version | Description | Repository |
|------|---------|-------------|------------|
| **GitHub CLI** | 2.78.0 | Official GitHub command-line interface | [cli/cli](https://github.com/cli/cli) |
| **lazygit** | 0.54.2 | Terminal UI for git commands | [jesseduffield/lazygit](https://github.com/jesseduffield/lazygit) |

### **Terminal and Productivity**
| Tool | Version | Description | Repository |
|------|---------|-------------|------------|
| **Starship** | 1.23.0 | Cross-shell prompt customization | [starship/starship](https://github.com/starship/starship) |
| **Zellij** | 0.43.1 | Terminal workspace multiplexer | [zellij-org/zellij](https://github.com/zellij-org/zellij) |
| **Gum** | 0.16.2 | Tool for beautiful shell scripts | [charmbracelet/gum](https://github.com/charmbracelet/gum) |
| **Task** | 3.44.1 | Modern task runner and Make alternative | [go-task/task](https://github.com/go-task/task) |

### **Language Runtime Management**
| Tool | Version | Description | Repository |
|------|---------|-------------|------------|
| **mise** | 2025.8.20 | Universal tool version manager | [jdx/mise](https://github.com/jdx/mise) |
| **Volta** | 2.0.2 | JavaScript tool manager | [volta-cli/volta](https://github.com/volta-cli/volta) |
| **uv** | 0.8.13 | Fast Python package manager | [astral-sh/uv](https://github.com/astral-sh/uv) |

### **Specialized Tools**
| Tool | Version | Description | Repository |
|------|---------|-------------|------------|
| **k6** | 1.2.2 | Modern load testing tool | [grafana/k6](https://github.com/grafana/k6) |
| **Gomplate** | 4.3.3 | Template rendering tool | [hairyhenderson/gomplate](https://github.com/hairyhenderson/gomplate) |
| **DBeaver** | 25.1.5 | Universal database tool | [dbeaver/dbeaver](https://github.com/dbeaver/dbeaver) |
| **WP-CLI** | 2.12.0 | WordPress command-line interface | [wp-cli/wp-cli](https://github.com/wp-cli/wp-cli) |
| **getoptions** | 3.3.2 | Shell script option parser | [ko1nksm/getoptions](https://github.com/ko1nksm/getoptions) |

### **Modern CLI Tools and Utilities**
| Tool | Version | Description | Repository |
|------|---------|-------------|------------|
| **Neovim** | 0.11.3 | Hyperextensible Vim-based text editor | [neovim/neovim](https://github.com/neovim/neovim) |
| **fd** | 10.3.0 | Simple, fast alternative to 'find' | [sharkdp/fd](https://github.com/sharkdp/fd) |
| **ripgrep** | 14.1.1 | Line-oriented search tool | [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| **bat** | 0.24.0 | Cat clone with syntax highlighting | [sharkdp/bat](https://github.com/sharkdp/bat) |
| **eza** | 0.23.0 | Modern, maintained replacement for 'ls' | [eza-community/eza](https://github.com/eza-community/eza) |
| **HTTPie** | 3.2.4 | Modern HTTP client for APIs | [httpie/httpie](https://github.com/httpie/httpie) |
| **btop** | 1.4.4 | Feature-rich system monitor | [aristocratos/btop](https://github.com/aristocratos/btop) |
| **Trivy** | 0.58.1 | Comprehensive security scanner | [aquasecurity/trivy](https://github.com/aquasecurity/trivy) |
| **fzf** | 0.58.0 | Command-line fuzzy finder | [junegunn/fzf](https://github.com/junegunn/fzf) |
| **zoxide** | 0.9.6 | Smart directory jumper | [ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide) |
| **duf** | 0.8.1 | Modern disk usage utility | [muesli/duf](https://github.com/muesli/duf) |
| **jq** | 1.7.1 | Command-line JSON processor | [jqlang/jq](https://github.com/jqlang/jq) |
| **yq** | 4.44.6 | Command-line YAML processor | [mikefarah/yq](https://github.com/mikefarah/yq) |
| **tldr** | 3.4.0 | Simplified man pages | [tldr-pages/tldr](https://github.com/tldr-pages/tldr) |
| **ncdu** | 1.19 | Disk usage analyzer | [rofl0r/ncdu](https://dev.yorhel.nl/ncdu) |
| **speedtest-cli** | 2.1.3 | Internet bandwidth testing | [sivel/speedtest-cli](https://github.com/sivel/speedtest-cli) |
| **procs** | 0.14.8 | Modern ps replacement | [dalance/procs](https://github.com/dalance/procs) |
| **sd** | 1.0.0 | Intuitive find & replace | [chmln/sd](https://github.com/chmln/sd) |
| **broot** | 1.44.2 | Tree view and file manager | [Canop/broot](https://github.com/Canop/broot) |
| **gping** | 1.18.0 | Ping with graph | [orf/gping](https://github.com/orf/gping) |
| **fastfetch** | 2.32.0 | System information tool | [fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| **thefuck** | 3.32 | Command correction tool | [nvbn/thefuck](https://github.com/nvbn/thefuck) |
| **choose** | 1.3.6 | Human-friendly cut/awk alternative | [theryangeary/choose](https://github.com/theryangeary/choose) |
| **hyperfine** | 1.19.0 | Command-line benchmarking | [sharkdp/hyperfine](https://github.com/sharkdp/hyperfine) |
| **just** | 1.37.0 | Command runner (Make alternative) | [casey/just](https://github.com/casey/just) |
| **yazi** | 0.4.2 | Terminal file manager | [sxyazi/yazi](https://github.com/sxyazi/yazi) |

### **Shell Configuration**
| Tool | Version | Description | Repository |
|------|---------|-------------|------------|
| **Zsh** | 5.9 | Modern shell with plugins | [zsh-users/zsh](https://github.com/zsh-users/zsh) |
| **Zinit** | Latest | Fast and flexible Zsh plugin manager | [zdharma-continuum/zinit](https://github.com/zdharma-continuum/zinit) |
| **Oh My Zsh** | Latest | Zsh framework (loaded via Zinit) | [ohmyzsh/ohmyzsh](https://github.com/ohmyzsh/ohmyzsh) |

### **Language Runtimes**
| Language | Version | Description | Package Manager | Repository |
|----------|---------|-------------|-----------------|------------|
| **Java** | OpenJDK 21 | Enterprise Java development | Maven, Gradle | [openjdk/jdk](https://github.com/openjdk/jdk) |
| **Rust** | 1.84.0 | Systems programming language | Cargo | [rust-lang/rust](https://github.com/rust-lang/rust) |
| **Go** | 1.23.4 | Google's programming language | Go modules | [golang/go](https://github.com/golang/go) |
| **Node.js** | 22.12.0 | JavaScript runtime | npm, yarn, pnpm | [nodejs/node](https://github.com/nodejs/node) |
| **PHP** | 8.3 | Web development language | Composer | [php/php-src](https://github.com/php/php-src) |
| **Ruby** | 3.3.6 | Object-oriented programming | Bundler, rbenv | [ruby/ruby](https://github.com/ruby/ruby) |
| **Python** | 3.12 | General-purpose programming (default) | pip, pipx, poetry | [python/cpython](https://github.com/python/cpython) |

### **System and Process Management**
| Tool | Version | Description | Repository |
|------|---------|-------------|------------|
| **Supervisor** | 4.3.0 | Process control system | [Supervisor/supervisor](https://github.com/Supervisor/supervisor) |

## ⚙️ **Configuration**

### **Environment Variables**

The container behavior is controlled through environment variables in the `.env` file. Copy `.env.example` to `.env` and customize as needed.

#### **Core Configuration**
```bash
# Container Identity
CONTAINER_NAME=ws-oracle-linux-dev
USER_NAME=dev
USER_UID=1000
USER_GID=1000

# Directories
WORKSPACE_DIR=/workspace
HOME_DIR=/home/dev
DATA_DIR=/data

# Security
ROOT_PASSWORD=root
USER_PASSWORD=dev
TZ=UTC
```

#### **Tool Installation Flags**
Each tool can be selectively installed by setting the corresponding flag to `true` or `false`:

```bash
# Infrastructure and DevOps Tools
INSTALL_ANSIBLE=true
INSTALL_TERRAFORM=true
INSTALL_TELEPORT=true

# Kubernetes Tools
INSTALL_KUBECTL=true
INSTALL_HELM=true
INSTALL_K9S=true

# Container Management
INSTALL_DRY=true
INSTALL_LAZYDOCKER=true

# Cloud Platform Tools
INSTALL_AWS_CLI=true
INSTALL_CLOUDFLARED=true
INSTALL_TAILSCALE=true
INSTALL_NGROK=true

# Development Tools
INSTALL_GITHUB_CLI=true
INSTALL_LAZYGIT=true
INSTALL_STARSHIP=true
INSTALL_ZELLIJ=true
INSTALL_GUM=true

# Language Management
INSTALL_MISE=true
INSTALL_VOLTA=true
INSTALL_UV=true

# Specialized Tools
INSTALL_K6=true
INSTALL_GOMPLATE=true
INSTALL_DBEAVER=true
INSTALL_WP_CLI=true
INSTALL_GETOPTIONS=true

# Modern CLI Tools and Utilities
INSTALL_NEOVIM=true
INSTALL_FD=true
INSTALL_RIPGREP=true
INSTALL_BAT=true
INSTALL_EZA=true
INSTALL_HTTPIE=true
INSTALL_BTOP=true
INSTALL_TRIVY=true
INSTALL_FZF=true
INSTALL_ZOXIDE=true
INSTALL_DUF=true
# Note: Additional modern CLI tools (jq, yq, tldr, ncdu, speedtest-cli,
#       procs, sd, broot, gping, fastfetch, thefuck, choose, hyperfine,
#       just, yazi) are installed by default for enhanced productivity

# System Services and Shell Configuration
INSTALL_SSH_SERVER=true
INSTALL_ZSH=true

# Tool Version Variables (can be overridden)
NEOVIM_VERSION=0.11.3
FD_VERSION=10.3.0
RIPGREP_VERSION=14.1.1
BAT_VERSION=0.24.0
EZA_VERSION=0.23.0
HTTPIE_VERSION=3.2.4
BTOP_VERSION=1.4.4
TRIVY_VERSION=0.58.1
FZF_VERSION=0.58.0
ZOXIDE_VERSION=0.9.6
DUF_VERSION=0.8.1

# Language Runtime Installation Flags
INSTALL_JAVA=true
INSTALL_RUST=true
INSTALL_GO=true
INSTALL_NODEJS=true
INSTALL_PHP=true
INSTALL_PYTHON_EXTRAS=true

# Language Runtime Versions
JAVA_VERSION=21
RUST_VERSION=1.84.0
GO_VERSION=1.23.4
NODEJS_VERSION=22.12.0
PHP_VERSION=8.3
RUBY_VERSION=3.3.6
PYTHON_VERSION=3.12  # Default Python version for modern compatibility
```

#### **Optional Authentication Tokens**
```bash
# GitHub token for enhanced GitHub CLI functionality
GH_TOKEN=your_github_token_here

# ngrok authentication token for secure tunneling
NGROK_AUTHTOKEN=your_ngrok_token_here
```

### **Custom Build Arguments**

You can customize the build process using Docker build arguments:

```bash
# Build with specific tool versions
docker build \
  --build-arg TERRAFORM_VERSION=1.12.0 \
  --build-arg KUBECTL_VERSION=1.30.0 \
  --build-arg INSTALL_DBEAVER=false \
  -t my-custom-dev-container .
```

### **Volume Mounting**

Mount your local development directories for persistent storage:

```yaml
# docker-compose.override.yml
services:
  workspace:
    volumes:
      - ./projects:/workspace/projects
      - ./dotfiles:/home/dev/.config
      - ~/.ssh:/home/dev/.ssh:ro
```

## 🚀 **Usage Examples**

### **Development Workflows**

#### **Web Development**
```bash
# Start the container
task up

# Access the development environment
task shell

# Set up a Node.js project
cd /workspace
npm init -y
npm install express

# Use Volta for Node.js version management
volta install node@20
volta install npm@10
```

#### **Infrastructure as Code**
```bash
# Access the container
task shell

# Use Terraform for infrastructure management
cd /workspace/infrastructure
terraform init
terraform plan
terraform apply

# Use Ansible for configuration management
cd /workspace/ansible
ansible-playbook -i inventory site.yml
```

#### **Kubernetes Development**
```bash
# Access the container
task shell

# Connect to your Kubernetes cluster
kubectl config use-context my-cluster

# Use Helm for package management
helm repo add stable https://charts.helm.sh/stable
helm install my-app stable/nginx

# Monitor with k9s
k9s
```

### **Container Management**

#### **Docker-in-Docker**
```bash
# The container includes Docker CLI for container management
docker ps
docker build -t my-app .
docker run -d my-app

# Use lazydocker for interactive management
lazydocker

# Use dry for terminal-based Docker management
dry
```

#### **Multi-Cloud Development**
```bash
# AWS development
aws configure
aws s3 ls

# Use Cloudflared for secure tunnels
cloudflared tunnel create my-tunnel

# Use Tailscale for VPN connectivity
tailscale up
```

## 🔧 **Advanced Configuration**

### **SSH Access Setup**

1. **Generate SSH keys** (if you don't have them):
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

2. **Copy your public key** to the container's authorized_keys:
```bash
# Create SSH directory structure
mkdir -p resources/.ssh/incoming

# Copy your public key
cp ~/.ssh/id_ed25519.pub resources/.ssh/incoming/
```

3. **Rebuild and access via SSH**:
```bash
task rebuild
ssh -p 2222 dev@localhost
```

### **Custom Tool Installation**

Add your own tools by creating installation scripts in `resources/prebuildfs/opt/laragis/tools/`:

```bash
#!/usr/bin/env bash
# resources/prebuildfs/opt/laragis/tools/my-tool.sh

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly TOOL_NAME="my-tool"
readonly TOOL_VERSION="${MY_TOOL_VERSION:-1.0.0}"

# Installation logic
install_tool() {
    log_info "Installing ${TOOL_NAME} v${TOOL_VERSION}..."
    # Your installation commands here
}

main() {
    install_tool
    log_success "${TOOL_NAME} installed successfully"
}

main "$@"
```

### **Environment Customization**

#### **Shell Configuration**
The container includes Starship prompt and Zellij multiplexer. Customize by mounting your dotfiles:

```yaml
# docker-compose.override.yml
services:
  workspace:
    volumes:
      - ./dotfiles/.zshrc:/home/dev/.zshrc
      - ./dotfiles/starship.toml:/home/dev/.config/starship.toml
```

#### **Development Environment Presets**

Create environment-specific configurations:

```bash
# .env.development
INSTALL_TERRAFORM=true
INSTALL_KUBECTL=true
INSTALL_AWS_CLI=true

# .env.minimal
INSTALL_TERRAFORM=false
INSTALL_KUBECTL=false
INSTALL_AWS_CLI=false
```

## 🐳 **Docker-in-Docker Management**

The container supports Docker-in-Docker functionality for containerized development workflows.

### **Available Docker Tools**
- **Docker CLI**: Full Docker command-line interface
- **lazydocker**: Interactive Docker management with a beautiful TUI
- **dry**: Terminal-based Docker container and image manager

### **Usage Examples**
```bash
# Standard Docker commands
docker build -t my-app .
docker run -d -p 8080:8080 my-app
docker ps
docker logs container_name

# Interactive management with lazydocker
lazydocker

# Terminal-based management with dry
dry
```

### **Docker Compose Integration**
```bash
# Use Docker Compose within the container
docker compose up -d
docker compose logs -f
docker compose down
```

## 🔍 **Troubleshooting**

### **Common Issues**

#### **Container Won't Start**
```bash
# Check Docker daemon status
docker info

# Check container logs
task logs

# Rebuild from scratch
task fresh
```

#### **SSH Connection Issues**
```bash
# Check SSH service status
task shell
sudo supervisorctl status sshd

# Verify SSH configuration
cat /etc/ssh/sshd_config

# Check SSH keys
ls -la ~/.ssh/
```

#### **Tool Installation Failures**
```bash
# Check specific tool installation
task shell
ls -la /opt/laragis/tools/

# Verify tool installation logs
grep -r "ERROR" /var/log/

# Reinstall specific tool
sudo /opt/laragis/tools/tool-name.sh
```

#### **Performance Issues**
```bash
# Check resource usage
task shell
htop

# Check disk usage
df -h
du -sh /home/dev/*

# Clean up Docker resources
task clean-all
```

### **Build Issues**

#### **Build Cache Problems**
```bash
# Clear build cache
docker builder prune -a

# Build without cache
docker compose build --no-cache
```

#### **Network Issues During Build**
```bash
# Check network connectivity
docker run --rm alpine ping -c 3 google.com

# Use different DNS
docker build --build-arg DNS=8.8.8.8 .
```

### **Getting Help**

1. **Check the logs**: `task logs`
2. **Verify configuration**: Review your `.env` file
3. **Test with minimal config**: Disable optional tools
4. **Check system resources**: Ensure adequate disk space and memory
5. **Update Docker**: Ensure you're using a recent Docker version

## 📚 **FAQ**

### **General Questions**

**Q: What's the difference between this and other development containers?**
A: This container is specifically designed for Oracle Linux 9 with enterprise-grade tools, comprehensive DevOps tooling, and production-ready configurations.

**Q: Can I use this in production?**
A: While the container includes production-grade tools, it's designed for development. For production, create a minimal image with only required tools.

**Q: How do I add my own tools?**
A: Create installation scripts in `resources/prebuildfs/opt/laragis/tools/` following the template pattern, then add the corresponding build argument.

### **Configuration Questions**

**Q: How do I disable specific tools?**
A: Set the corresponding `INSTALL_TOOL=false` in your `.env` file and rebuild the container.

**Q: Can I change the default user?**
A: Yes, modify `USER_NAME`, `USER_UID`, and `USER_GID` in your `.env` file.

**Q: How do I persist data between container restarts?**
A: Use Docker volumes or bind mounts in your `docker-compose.override.yml` file.

### **Development Questions**

**Q: How do I set up my IDE to work with the container?**
A: Use SSH remote development features in VS Code, or mount your project directory and use the container as a development server.

**Q: Can I run multiple instances?**
A: Yes, change the `CONTAINER_NAME` and port mappings in your configuration.

**Q: How do I update tools to newer versions?**
A: Update the version variables in your `.env` file or Dockerfile and rebuild the container.

## 📚 **Documentation**

For detailed technical documentation, please refer to the following documents in the `docs/` directory:

- **[Dockerfile Optimization Report](docs/DOCKERFILE_OPTIMIZATION_REPORT.md)** - Comprehensive analysis of Dockerfile optimizations and performance improvements
- **[Python 3.12 Upgrade Summary](docs/PYTHON_312_UPGRADE_SUMMARY.md)** - Details about the Python 3.12 upgrade and implementation
- **[Comprehensive Improvements Summary](docs/COMPREHENSIVE_IMPROVEMENTS_SUMMARY.md)** - Complete overview of all recent improvements and enhancements
- **[Code Quality Audit Report](docs/CODE_QUALITY_AUDIT_REPORT.md)** - Detailed analysis of code duplication elimination and shared library implementation
- **[Tools Optimization Analysis](docs/TOOLS_OPTIMIZATION_ANALYSIS.md)** - Comprehensive review of all 59 tool scripts with optimization priorities
- **[Comprehensive Tools Review Summary](docs/COMPREHENSIVE_TOOLS_REVIEW_SUMMARY.md)** - Executive summary of tools directory optimization roadmap
- **[Script Optimization Guide](docs/SCRIPT_OPTIMIZATION_GUIDE.md)** - Step-by-step guide for optimizing installation scripts
- **[Essential Components and Standards](docs/ESSENTIAL_COMPONENTS_AND_STANDARDS.md)** - Documentation of essential components and development standards

## 🔧 **Development Standards**

This project uses consistent coding standards enforced by `.editorconfig`:

- **Indentation**: 2 spaces for all files (including Python, overriding PEP 8)
- **Line endings**: LF (Unix-style)
- **Character encoding**: UTF-8
- **Trailing whitespace**: Automatically trimmed
- **Final newline**: Always inserted

**Essential Components**: SSH Server and ZSH shell are installed by default as core components of the development environment.

## 📚 **Shared Libraries Architecture**

The project uses a modular shared library system to eliminate code duplication and improve maintainability:

### **Core Libraries**
- **`/opt/laragis/lib/install.sh`** - Common installation patterns and utilities (15+ functions)
- **`/opt/laragis/lib/validation.sh`** - Validation utilities for versions, URLs, files, and system resources (20+ functions)
- **`/opt/laragis/lib/github.sh`** - GitHub releases integration and download utilities (12+ functions)
- **`/opt/laragis/lib/bootstrap.sh`** - Core bootstrap functionality
- **`/opt/laragis/lib/log.sh`** - Standardized logging functions

### **Benefits**
- **70% reduction** in code duplication across 42+ installation scripts
- **Centralized maintenance** - updates needed in one place
- **Consistent behavior** - all scripts use the same patterns
- **Improved reliability** - shared functions are thoroughly tested
- **Faster development** - new tools can be added with minimal code

## 🤝 **Contributing**

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### **Development Setup**
```bash
# Fork and clone the repository
git clone https://github.com/your-username/ws-oracle-linux.git
cd ws-oracle-linux

# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes and test
task build
task up
task shell

# Submit a pull request
```

### **Adding New Tools**
1. Create an installation script in `resources/prebuildfs/opt/laragis/tools/`
2. Add the tool to the Dockerfile with appropriate build arguments
3. Update the `.env.example` file with the new installation flag
4. Update this README with tool information
5. Add tests for the new tool

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- Oracle Linux team for the excellent base image
- All the amazing open-source tool maintainers
- The Docker and container community
- Contributors and users of this project

---

**Built with ❤️ for developers who want a powerful, customizable development environment.**

> 💡 **Tip**: Star this repository if you find it useful, and feel free to fork it for your own customizations!