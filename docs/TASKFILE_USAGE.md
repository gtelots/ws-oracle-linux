# Taskfile Usage Guide - Oracle Linux 9 Development Container

Hướng dẫn chi tiết về cách sử dụng Taskfile.yml cho Oracle Linux 9 development container, lấy cảm hứng từ Laravel Sail.

## 🚀 Tổng quan

Taskfile.yml cung cấp một interface thống nhất và mạnh mẽ để quản lý Docker Compose environment với:
- **Container lifecycle management** - Start, stop, restart containers
- **Build operations** - Build, rebuild với cache management
- **Shell access** - Interactive shells với different users
- **Monitoring** - Logs, health checks, system status
- **Maintenance** - Cleanup, pruning, updates
- **Testing** - Automated test suites
- **Multi-environment support** - Dev, staging, production

## 📋 Cài đặt Task

### Linux/macOS
```bash
# Using Homebrew
brew install go-task/tap/go-task

# Using curl
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin

# Using Go
go install github.com/go-task/task/v3/cmd/task@latest
```

### Windows
```powershell
# Using Chocolatey
choco install go-task

# Using Scoop
scoop install task
```

## 🛠️ Cấu hình Environment

### 1. Environment Variables (.env)
```bash
# Project configuration
PROJECT_NAME=oracle-linux-dev
CONTAINER_NAME=oracle-linux-dev-container
ENV=development

# User configuration
CONTAINER_USER=developer
CONTAINER_UID=1000
CONTAINER_GID=1000

# Ports
HTTP_PORT=8080
HTTPS_PORT=8443
SSH_PORT=2222
DEBUG_PORT=9229

# Database (optional)
DB_DATABASE=oracle_dev
DB_USERNAME=developer
DB_PASSWORD=secret
DB_PORT=5432

# Redis (optional)
REDIS_PASSWORD=secret
REDIS_PORT=6379

# Resource limits
CPU_LIMIT=2.0
MEMORY_LIMIT=4G
CPU_RESERVATION=0.5
MEMORY_RESERVATION=1G

# Registry
REGISTRY_URL=localhost:5000
IMAGE_TAG=latest
```

### 2. Docker Compose Files
- `docker-compose.yml` - Base configuration
- `docker-compose.override.yml` - Development overrides
- `docker-compose.staging.yml` - Staging configuration
- `docker-compose.production.yml` - Production configuration

## 🔧 Container Lifecycle

### Basic Operations
```bash
# Start development environment
task up

# Stop and remove containers
task down

# Restart all containers
task restart

# Stop containers (without removing)
task stop

# Start stopped containers
task start
```

### Advanced Operations
```bash
# Complete fresh start
task fresh

# Rebuild containers
task rebuild

# Build with cache
task build

# Build without cache
task build-no-cache
```

## 🐚 Shell Access

### Interactive Shells
```bash
# Developer user shell (default)
task shell

# Root user shell
task shell-root

# Zsh shell (if available)
task zsh
```

### Running Commands
```bash
# Run single command as developer
task shell -- "ls -la /workspace"

# Run command as root
task shell-root -- "dnf update -y"

# Execute script
task shell -- "/opt/scripts/functionality-test.sh"
```

## 📊 Monitoring và Debugging

### Container Status
```bash
# Show container status
task ps

# Check health status
task health

# Comprehensive system check
task check

# Show current configuration
task config
```

### Logs Management
```bash
# Show all logs
task logs

# Follow logs in real-time
task logs-follow

# Show logs for specific service
docker-compose logs workspace
```

## 🧹 Maintenance

### Cleanup Operations
```bash
# Basic cleanup (stopped containers, unused images)
task clean

# Complete cleanup (everything)
task clean-all

# Docker system prune
task prune
```

### Updates
```bash
# Update system packages
task update

# Install development tools
task install-dev-tools

# Pull latest images
task pull
```

## 🧪 Testing

### Test Suites
```bash
# Run all tests
task test

# Security tests
task test-security

# Performance tests
task test-performance

# Functionality tests
task test-functionality
```

### Custom Testing
```bash
# Run specific test script
task shell -- "/opt/scripts/custom-test.sh"

# Test with different environment
ENV=testing task test
```

## 🗄️ Database Operations

### Database Management
```bash
# Start with database
docker-compose --profile database up -d

# Run migrations
task migrate

# Seed database
task seed

# Backup database
task backup
```

### Database Access
```bash
# Connect to PostgreSQL
task shell -- "psql -h postgres -U developer oracle_dev"

# Connect to Redis
task shell -- "redis-cli -h redis -a secret"
```

## 🌍 Multi-Environment Support

### Environment-Specific Commands
```bash
# Development environment (default)
task dev

# Staging environment
task staging

# Production environment
task production
```

### Environment Variables
```bash
# Override environment
ENV=staging task up

# Use different compose file
COMPOSE_FILE=docker-compose.staging.yml task up

# Multiple environment variables
ENV=production REGISTRY_URL=prod.registry.com task push
```

## 🔧 Development Utilities

### Code Management
```bash
# Format code
task format

# Generate documentation
task docs

# Install development tools
task install-dev-tools
```

### Registry Operations
```bash
# Push to registry
task push

# Pull from registry
task pull

# Tag and push specific version
IMAGE_TAG=v1.2.3 task push
```

## 📚 Advanced Usage

### Custom Tasks
Thêm custom tasks vào Taskfile.yml:

```yaml
tasks:
  my-custom-task:
    desc: "My custom development task"
    deps: [_check-requirements]
    vars:
      COMPOSE_CMD:
        sh: task _compose-cmd
    cmds:
      - echo "Running custom task..."
      - |
        {{.COMPOSE_CMD}} exec {{.CONTAINER_NAME}} /path/to/my/script.sh
```

### Task Dependencies
```yaml
tasks:
  deploy:
    desc: "Deploy application"
    deps: [test, build, push]  # Run these tasks first
    cmds:
      - echo "Deploying application..."
```

### Conditional Execution
```yaml
tasks:
  conditional-task:
    desc: "Run only in production"
    preconditions:
      - test "{{.ENV}}" = "production"
    cmds:
      - echo "Running production task..."
```

## 🔍 Troubleshooting

### Common Issues

1. **Task not found**
   ```bash
   # Check if Task is installed
   task --version
   
   # Install Task
   brew install go-task/tap/go-task
   ```

2. **Docker Compose not found**
   ```bash
   # Check Docker Compose
   docker-compose --version
   docker compose version
   
   # Install Docker Compose
   # Follow Docker documentation
   ```

3. **Permission denied**
   ```bash
   # Fix file permissions
   chmod +x scripts/*.sh
   
   # Check user configuration
   task config
   ```

4. **Container not starting**
   ```bash
   # Check container status
   task ps
   
   # Check logs
   task logs
   
   # Run health check
   task health
   ```

### Debug Mode
```bash
# Enable verbose output
task --verbose up

# Dry run (show commands without executing)
task --dry up

# List all available tasks
task --list
```

## 📊 Performance Tips

### Optimization
```bash
# Use BuildKit for faster builds
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Parallel operations
task build & task pull & wait

# Resource monitoring
task health
docker stats
```

### Caching
```bash
# Build with cache
task build

# Force rebuild without cache
task build-no-cache

# Clean build cache
docker builder prune
```

## 🔗 Integration

### CI/CD Integration
```yaml
# GitHub Actions example
- name: Setup Task
  uses: arduino/setup-task@v1
  
- name: Run tests
  run: task test
  
- name: Build and push
  run: |
    task build
    task push
```

### IDE Integration
```json
// VS Code tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Start Development",
      "type": "shell",
      "command": "task up",
      "group": "build"
    }
  ]
}
```

## 📖 Best Practices

### Development Workflow
1. **Start environment**: `task up`
2. **Access shell**: `task shell`
3. **Run tests**: `task test`
4. **Check health**: `task health`
5. **Stop environment**: `task down`

### Production Deployment
1. **Test locally**: `task test`
2. **Build images**: `task build`
3. **Push to registry**: `task push`
4. **Deploy**: `ENV=production task production`

### Maintenance Schedule
- **Daily**: `task health`, `task logs`
- **Weekly**: `task clean`, `task update`
- **Monthly**: `task clean-all`, review configurations

---

*Taskfile.yml cung cấp workflow mạnh mẽ và nhất quán cho Oracle Linux 9 development container, tương tự như Laravel Sail nhưng được tối ưu cho enterprise development environments.*
