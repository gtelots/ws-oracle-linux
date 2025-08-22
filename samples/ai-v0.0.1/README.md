# Oracle Linux 9 Development Container

[![Oracle Linux](https://img.shields.io/badge/Oracle%20Linux-9-red.svg)](https://www.oracle.com/linux/)
[![Docker](https://img.shields.io/badge/Docker-Multi--stage-blue.svg)](https://docs.docker.com/develop/dev-best-practices/dockerfile_best-practices/)
[![Security](https://img.shields.io/badge/Security-Hardened-green.svg)](https://github.com/bitnami/containers)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Enterprise-grade Oracle Linux 9 development container** following security best practices, performance optimization, and modern development workflows.

## 🚀 Features

### 🔒 Security-First Architecture
- **Non-root execution** with dedicated developer user
- **Security hardening** following Bitnami patterns
- **Modern cryptography** with Ed25519 SSH keys
- **Certificate management** for enterprise environments
- **Comprehensive security auditing** and validation

### 🛠️ Development Tools
- **Modern CLI tools**: bat, exa, fd, ripgrep, delta
- **Language runtimes**: Python 3.11, Node.js 18, Go 1.21, Rust
- **Container tools**: Docker CLI, kubectl, Helm
- **Database clients**: MySQL, PostgreSQL, Redis, MongoDB
- **Security tools**: nmap, tcpdump, htop, monitoring utilities

### 🏗️ Enterprise Architecture
- **Multi-stage builds** for optimized layers and caching
- **Modular design** with reusable components
- **Service orchestration** with health checks
- **Task automation** with comprehensive Taskfile
- **Lock file management** for reproducible builds

### 📊 Monitoring & Validation
- **Health checks** with detailed system validation
- **Performance benchmarking** and resource monitoring
- **Security scanning** and compliance verification
- **Structured logging** and audit trails

## 📁 Project Structure

```
oracle-linux-dev/
├── Dockerfile              # Multi-stage Oracle Linux 9 container
├── Taskfile.yml           # Task automation and lifecycle management
├── .env.example           # Environment configuration template
├── README.md              # This documentation
├── scripts/               # Installation and management scripts
│   ├── install-development-tools.sh
│   ├── healthcheck.sh
│   ├── security-check.sh
│   ├── functionality-test.sh
│   └── performance-test.sh
├── dotfiles/              # Shell configuration and productivity
│   ├── bashrc
│   └── aliases
├── .ssh/                  # SSH configuration and key management
│   ├── config
│   └── README.md
└── ca-certificates/       # Custom certificate authority files
    └── README.md
```

## 🚀 Quick Start

### Prerequisites
- Docker or Podman
- Task (optional, for automation)
- Git (for cloning)

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd oracle-linux-dev

# Copy environment configuration
cp .env.example .env

# Edit configuration as needed
vim .env
```

### 2. Build and Run

```bash
# Using Task (recommended)
task build
task run

# Or using Docker directly
docker build -t oracle-linux-dev .
docker run -it --rm oracle-linux-dev
```

### 3. Development Workflow

```bash
# Quick development setup
task dev

# Run with volume mounts
task run-daemon

# Execute shell in running container
task shell

# View logs
task logs
```

## 🔧 Configuration

### Environment Variables

Key configuration options in `.env`:

```bash
# Container configuration
CONTAINER_NAME=oracle-linux-dev
CONTAINER_USER=developer
WORKSPACE_DIR=/workspace

# Network ports
HTTP_PORT=8080
SSH_PORT=2222

# Security settings
SSH_ENABLE=true
SSL_ENABLE=true
SECURITY_HARDENING=true

# Development tools
NODE_VERSION=18
PYTHON_VERSION=3.11
```

### SSH Configuration

The container includes enterprise-grade SSH configuration:

```bash
# Generate SSH keys
ssh-keygen -t ed25519 -C "developer@oracle-linux-dev"

# Configure for different services
vim .ssh/config
```

### Custom Certificates

Add corporate or development certificates:

```bash
# Add corporate CA certificates
cp corporate-ca.crt ca-certificates/corporate/

# Update certificate trust store
sudo update-ca-trust
```

## 🛠️ Development Tools

### Installed Languages and Runtimes

| Tool | Version | Purpose |
|------|---------|---------|
| Python | 3.11+ | Development, scripting, data science |
| Node.js | 18+ | JavaScript runtime, web development |
| Go | 1.21+ | Systems programming, microservices |
| Rust | Latest | Systems programming, performance |

### Modern CLI Tools

| Tool | Replaces | Features |
|------|----------|----------|
| bat | cat | Syntax highlighting, Git integration |
| exa | ls | Better colors, Git status, tree view |
| fd | find | Faster, intuitive syntax |
| ripgrep | grep | Faster, better defaults |
| delta | diff | Better Git diffs |

### Container and Cloud Tools

- **Docker CLI**: Container management
- **kubectl**: Kubernetes cluster management
- **Helm**: Kubernetes package manager
- **Database clients**: MySQL, PostgreSQL, Redis, MongoDB

## 🔍 Testing and Validation

### Health Checks

```bash
# Run comprehensive health check
/opt/scripts/healthcheck.sh

# Check specific components
task health
```

### Security Validation

```bash
# Run security audit
/opt/scripts/security-check.sh

# Security testing
task test-security
```

### Performance Benchmarking

```bash
# Run performance tests
/opt/scripts/performance-test.sh

# Performance testing
task test-performance
```

### Functionality Testing

```bash
# Test all development tools
/opt/scripts/functionality-test.sh

# Functionality testing
task test-functionality
```

## 🏢 Enterprise Integration

### Corporate Networks

The container supports enterprise environments:

- **VPN integration** with corporate networks
- **Proxy configuration** for corporate firewalls
- **Custom CA certificates** for internal services
- **SSH jump hosts** and bastion servers
- **LDAP/Active Directory** integration ready

### Cloud Provider Support

Pre-configured for major cloud providers:

- **Oracle Cloud Infrastructure (OCI)**
- **Amazon Web Services (AWS)**
- **Google Cloud Platform (GCP)**
- **Microsoft Azure**

### Compliance and Security

- **Security hardening** following industry standards
- **Audit logging** for compliance requirements
- **Non-root execution** for security
- **Certificate management** for PKI environments

## 📊 Monitoring and Observability

### Health Monitoring

- **System resource monitoring** (CPU, memory, disk)
- **Service health checks** with detailed reporting
- **Network connectivity validation**
- **Development tool functionality verification**

### Performance Metrics

- **CPU performance benchmarking**
- **Memory allocation and usage testing**
- **Disk I/O performance measurement**
- **Development tool performance profiling**

### Logging and Auditing

- **Structured logging** with timestamps
- **Security event logging**
- **Performance metrics collection**
- **Audit trail generation**

## 🔧 Customization

### Adding Development Tools

```bash
# Add to install-development-tools.sh
sudo microdnf install -y your-package

# Or use language-specific package managers
pip3 install --user your-python-package
npm install -g your-node-package
```

### Custom Shell Configuration

```bash
# Add to dotfiles/bashrc
export YOUR_CUSTOM_VAR="value"

# Add to dotfiles/aliases
alias your-alias='your-command'
```

### Service Integration

```bash
# Add service configuration to .env
YOUR_SERVICE_URL=https://your-service.com
YOUR_SERVICE_API_KEY=your-api-key

# Add service-specific scripts to scripts/
```

## 🚨 Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Fix file permissions
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/config
   ```

2. **Network Connectivity**
   ```bash
   # Test network
   curl -v https://google.com
   nslookup google.com
   ```

3. **Container Build Issues**
   ```bash
   # Clean build
   task clean
   task build-no-cache
   ```

### Debug Mode

```bash
# Enable verbose logging
export LOG_LEVEL=debug

# Run with debug output
task run --verbose
```

### Support Resources

- **Oracle Linux Documentation**: [docs.oracle.com](https://docs.oracle.com/en/operating-systems/oracle-linux/)
- **Container Security**: [Bitnami Security Practices](https://github.com/bitnami/containers)
- **Development Workflows**: [Laravel Homestead](https://laravel.com/docs/homestead)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

### Development Guidelines

- Follow security best practices
- Add comprehensive tests
- Update documentation
- Use conventional commits
- Ensure backward compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Oracle Linux Team** for the excellent base distribution
- **Bitnami** for security hardening patterns
- **Laravel Homestead** for development workflow inspiration
- **Laradock** for modular architecture concepts

---

**Built with ❤️ for enterprise development teams**

*Oracle Linux 9 Development Container - Production-ready, secure, and developer-friendly.*
