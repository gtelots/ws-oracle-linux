# Taskfile Quick Reference - Oracle Linux 9 Development Container

> **Tham khảo nhanh các lệnh Taskfile cho Oracle Linux 9 development container**

## 🚀 Container Lifecycle

```bash
# Start development environment
task up

# Stop and remove containers
task down

# Restart all containers
task restart

# Stop containers (keep them)
task stop

# Start stopped containers
task start

# Complete fresh start
task fresh
```

## 🔨 Build Operations

```bash
# Build with cache
task build

# Build without cache
task build-no-cache

# Rebuild (down + build)
task rebuild

# Fresh start (down + build-no-cache + up)
task fresh
```

## 🐚 Shell Access

```bash
# Developer shell
task shell

# Root shell
task shell-root

# Zsh shell (if available)
task zsh

# Run single command
task shell -- "command here"
```

## 📊 Monitoring

```bash
# Container status
task ps

# Show logs
task logs

# Follow logs
task logs-follow

# Health check
task health

# System check
task check

# Show configuration
task config
```

## 🧹 Maintenance

```bash
# Basic cleanup
task clean

# Complete cleanup
task clean-all

# Docker system prune
task prune

# Update packages
task update

# Install dev tools
task install-dev-tools
```

## 🧪 Testing

```bash
# All tests
task test

# Security tests
task test-security

# Performance tests
task test-performance

# Functionality tests
task test-functionality
```

## 🗄️ Database Operations

```bash
# Run migrations
task migrate

# Seed database
task seed

# Backup database
task backup

# Start with database
docker-compose --profile database up -d
```

## 🌍 Multi-Environment

```bash
# Development (default)
task dev

# Staging environment
task staging

# Production environment
task production

# Custom environment
ENV=testing task up
```

## 📦 Registry Operations

```bash
# Push to registry
task push

# Pull from registry
task pull

# Custom registry
REGISTRY_URL=my-registry.com task push
```

## 🔧 Development Utilities

```bash
# Format code
task format

# Generate docs
task docs

# Show help
task help

# List all tasks
task --list
```

## ⚙️ Environment Variables

### Core Configuration
```bash
PROJECT_NAME=oracle-linux-dev
CONTAINER_NAME=oracle-linux-dev-container
ENV=development
```

### User Settings
```bash
CONTAINER_USER=developer
CONTAINER_UID=1000
CONTAINER_GID=1000
```

### Ports
```bash
HTTP_PORT=8080
HTTPS_PORT=8443
SSH_PORT=2222
DEBUG_PORT=9229
```

### Database
```bash
DB_DATABASE=oracle_dev
DB_USERNAME=developer
DB_PASSWORD=secret
DB_PORT=5432
```

### Resources
```bash
CPU_LIMIT=2.0
MEMORY_LIMIT=4G
CPU_RESERVATION=0.5
MEMORY_RESERVATION=1G
```

## 🔍 Troubleshooting

### Check Status
```bash
# Container status
task ps

# Health check
task health

# View logs
task logs

# System information
task check
```

### Debug Commands
```bash
# Verbose output
task --verbose up

# Dry run
task --dry up

# List tasks
task --list

# Show task details
task --summary up
```

### Common Fixes
```bash
# Restart containers
task restart

# Fresh rebuild
task fresh

# Clean and restart
task clean && task up

# Complete reset
task clean-all && task fresh
```

## 📋 Task Categories

### 🔄 **Lifecycle**
- `up` - Start containers
- `down` - Stop and remove
- `restart` - Restart all
- `stop` - Stop only
- `start` - Start stopped

### 🔨 **Build**
- `build` - Build with cache
- `build-no-cache` - Build fresh
- `rebuild` - Stop + build
- `fresh` - Complete fresh start

### 🐚 **Shell**
- `shell` - Developer shell
- `shell-root` - Root shell
- `zsh` - Zsh shell

### 📊 **Monitor**
- `ps` - Container status
- `logs` - Show logs
- `logs-follow` - Follow logs
- `health` - Health check
- `check` - System check

### 🧹 **Maintain**
- `clean` - Basic cleanup
- `clean-all` - Complete cleanup
- `prune` - System prune
- `update` - Update packages

### 🧪 **Test**
- `test` - All tests
- `test-security` - Security
- `test-performance` - Performance
- `test-functionality` - Functionality

### 🗄️ **Database**
- `migrate` - Run migrations
- `seed` - Seed data
- `backup` - Backup DB

### 🌍 **Environment**
- `dev` - Development
- `staging` - Staging
- `production` - Production

### 📦 **Registry**
- `push` - Push images
- `pull` - Pull images

### 🔧 **Utilities**
- `format` - Format code
- `docs` - Generate docs
- `help` - Show help
- `config` - Show config

## 💡 Pro Tips

### Shortcuts
```bash
# Quick development start
task up && task shell

# Test and build
task test && task build

# Clean restart
task down && task up

# Full reset
task clean-all && task fresh
```

### Environment Overrides
```bash
# Temporary environment
ENV=testing task up

# Multiple variables
ENV=staging REGISTRY_URL=staging.registry.com task push

# Debug mode
DEBUG=true task up
```

### Parallel Operations
```bash
# Background start
task up &

# Multiple terminals
task shell  # Terminal 1
task logs-follow  # Terminal 2
```

### Aliases (add to ~/.bashrc)
```bash
alias tup='task up'
alias tdown='task down'
alias tshell='task shell'
alias tlogs='task logs-follow'
alias ttest='task test'
alias tclean='task clean'
```

## 🔗 Resources

- **Full Documentation**: `docs/TASKFILE_USAGE.md`
- **Task Official Docs**: https://taskfile.dev
- **Docker Compose Docs**: https://docs.docker.com/compose/
- **Oracle Linux Docs**: https://docs.oracle.com/en/operating-systems/oracle-linux/

---

*Professional Taskfile for Oracle Linux 9 Development Container - Inspired by Laravel Sail*
