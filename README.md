# 🐧 Oracle Linux 9 Development Container

A comprehensive, production-ready development environment built on Oracle Linux 9 with modern tooling, beautiful UI, and optimized architecture.

## ✨ **Key Features**

- � **Modern UI Framework**: Gum for beautiful terminal interfaces and interactions
- �️ **Advanced Terminal**: Zellij multiplexer with vim-style keybindings replacing tmux
- 🏗️ **Shared Functions Architecture**: Eliminated code duplication with centralized functions
- 🔧 **Rich Development Tools**: Neovim+LazyVim, Volta+Node.js, Kubernetes tools, databases
- 🐳 **Docker-in-Docker**: Centralized Docker management with lazy loading
- ☁️ **Cloud Ready**: AWS CLI, Terraform, and modern DevOps toolchain
- 🔐 **Security First**: SSH server, certificate management, and proper permissions
- 📊 **Database Tools**: DBeaver Community Edition for SQL debugging
- 🌐 **Network Tools**: Ngrok, Tailscale, Cloudflare CLI for connectivity
- � **Template Engine**: Gomplate for configuration management

## 🚀 **Quick Start**

```bash
# Clone the repository
git clone <repository-url>
cd ws-oracle-linux

# Set up SSH keys (optional)
cp -r .ssh-example .ssh
# Add your public keys to .ssh/incoming/

# Start the development environment
task up

# Access the container
task shell
# or via SSH (password: dev)
ssh -p 2222 dev@localhost
```

## 📁 **Project Structure**

```
📁 ws-oracle-linux/
├── 📄 .env                           # Environment configuration
├── 📄 docker-compose.yml             # Multi-service setup with DinD
├── 📄 Dockerfile                     # Optimized with layer caching
├── 📄 taskfile.yml                   # Laravel Sail-style task runner
├── 📁 ca-certificates/               # Custom certificate authorities
├── 📁 dotfiles/                      # Development dotfiles
│   ├── .gitconfig                    # Git configuration
│   ├── .vimrc                        # Vim configuration
│   └── .bashrc                       # Bash configuration
├── 📁 scripts/                       # Organized installation & setup scripts
│   ├── 📁 install/                   # Installation scripts
│   │   ├── python-tools.sh           # Python environment
│   │   ├── cli-tools.sh              # CLI utilities
│   │   ├── k8s-tools.sh              # Kubernetes tools
│   │   ├── additional-packages.sh    # System packages
│   │   ├── install-additional-tools.sh # Tool orchestrator
│   │   └── 📁 tools/                 # Individual tool installers
│   │       ├── install-ansible.sh
│   │       ├── install-dbeaver.sh
│   │       ├── install-terraform.sh
│   │       └── ... (other tools)
│   └── 📁 setup/                     # System setup scripts
│       ├── setup-ssh.sh              # SSH configuration
│       ├── setup-supervisor.sh       # Service management
│       └── docker-context.sh         # Docker context management
├── 📁 docs/                          # Comprehensive documentation
└── 📁 .ssh/                          # SSH key management
    ├── README.md                     # SSH setup guide
    ├── incoming/                     # Keys for accessing workspace
    └── outgoing/                     # Keys for external connections
```

## 🛠️ **Available Commands**

| Command | Description |
|---------|-------------|
| `task up` | Start the development environment |
| `task down` | Stop the development environment |
| `task shell` | Open interactive shell in container |
| `task ssh` | SSH into the container |
| `task tools` | List installed development tools |
| `task health` | Check container and service status |
| `task build` | Build the container image |
| `task fresh` | Clean rebuild everything |

## 🐳 **Docker-in-Docker Management**

The environment includes a separate Docker-in-Docker service for centralized container management:

```bash
# Setup Docker contexts (run once)
docker-context-setup setup

# List available contexts
docker-context-setup list

# Switch between contexts
docker-context-setup use local    # Use local Docker
docker-context-setup use dind     # Use Docker-in-Docker
docker-context-setup use remote   # Use remote Docker host
```

## 🔧 **Installed Tools**

### **Core Development**
- Python 3.11 + pip, poetry, virtualenv
- Node.js (via Volta) + npm, yarn, pnpm
- Git + LazyGit
- Neovim + LazyVim

### **CLI Utilities**
- task (task runner)
- lazydocker (Docker TUI)
- yq (YAML processor)
- fzf, ripgrep, bat, eza
- htop, bpytop, speedtest-cli

### **Infrastructure & DevOps**
- Kubernetes: kubectl, helm, k9s
- Terraform
- Ansible + collections & roles
- Docker + Docker Compose
- Cloudflare CLI

### **Database Tools**
- DBeaver Community Edition
- Database drivers and connectors

### **Networking**
- Ngrok (tunneling)
- Tailscale (VPN)
- OpenVSwitch (networking)

## ⚙️ **Configuration**

All tools can be enabled/disabled via environment variables in `.env`:

```bash
# Core tools
INSTALL_PYTHON=1
INSTALL_ANSIBLE=1
INSTALL_K8S=1

# Additional tools
INSTALL_TERRAFORM=1
INSTALL_DBEAVER=1
INSTALL_DOCKER=1
```

## 🗺️ **Roadmap & Development Plan**

### Phase 1: Core Infrastructure ✅
- [x] Oracle Linux 9 base setup
- [x] Essential development tools
- [x] Docker-in-Docker implementation
- [x] Modular script architecture
- [x] Lock file system for installations

### Phase 2: Developer Experience (In Progress)
- [x] Individual tool installers
- [x] Professional dotfiles integration
- [x] Shell environment optimization
- [ ] Build testing and validation
- [ ] Performance optimization

### Phase 3: Advanced Features (Planned)
- [ ] Multi-architecture support (ARM64/AMD64)
- [ ] Custom development profiles
- [ ] IDE integrations
- [ ] Database connection management
- [ ] CI/CD pipeline integration

### Phase 4: Documentation & Maintenance (Ongoing)
- [ ] Comprehensive documentation
- [ ] Video tutorials
- [ ] Community contributions
- [ ] Regular security updates

## 📝 **TODOs**

### High Priority
- [ ] Complete Dockerfile restructuring validation
- [ ] Test all modular script installations
- [ ] Verify Docker-in-Docker functionality
- [ ] Performance benchmarking

### Medium Priority
- [ ] Add health checks for services
- [ ] Implement backup/restore scripts
- [ ] Create development profiles
- [ ] Add more database tools

### Low Priority
- [ ] GUI application support
- [ ] Custom theme development
- [ ] Plugin ecosystem
- [ ] Mobile development tools

## 📖 **Documentation**

- [Detailed Setup Guide](docs/DETAILED.md)
- [Configuration Reference](docs/CONFIGURATION.md)
- [Development Workflow](docs/WORKFLOW.md)
- [SSH Key Management](.ssh/README.md)

## Repos

- https://github.com/gtelots/ws-oracle-linux/blob/1.0.0/Dockerfile
- https://github.com/codeopshq/dotfiles
- https://github.com/wintermi/zsh-starship/blob/main/theme/starship.toml
- https://dev.to/girordo/a-hands-on-guide-to-setting-up-zsh-oh-my-zsh-asdf-and-spaceship-prompt-with-zinit-for-your-development-environment-91n

## 🤝 **Contributing**

The modular architecture makes it easy to contribute:

1. **Add new tools**: Create a new script in `scripts/install/tools/`
2. **Modify setup**: Update scripts in `scripts/setup/`
3. **Update documentation**: Modify files in `docs/`

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ for developers who want a powerful, customizable development environment.**