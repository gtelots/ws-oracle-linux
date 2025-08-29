# Contributing to Oracle Linux 9 Development Container

Thank you for your interest in contributing to the Oracle Linux 9 Development Container project! This guide will help you get started with contributing to this comprehensive development environment.

## 🚀 **Quick Start for Contributors**

### **Prerequisites**
- Docker Engine 20.10+ with BuildKit support
- Docker Compose 2.0+
- Task (optional but recommended)
- Git
- Basic knowledge of Docker, shell scripting, and containerization

### **Development Setup**
```bash
# Fork and clone the repository
git clone https://github.com/your-username/ws-oracle-linux.git
cd ws-oracle-linux

# Create a development branch
git checkout -b feature/your-feature-name

# Set up the development environment
cp .env.example .env
task dev

# Run tests to ensure everything works
task test
```

## 📋 **How to Contribute**

### **Types of Contributions**
We welcome various types of contributions:

1. **🐛 Bug Reports**: Report issues or unexpected behavior
2. **✨ Feature Requests**: Suggest new tools or improvements
3. **🔧 Tool Additions**: Add new development tools to the container
4. **📚 Documentation**: Improve documentation, guides, or examples
5. **🧪 Testing**: Add or improve test coverage
6. **🎨 UI/UX**: Improve user experience and interface
7. **⚡ Performance**: Optimize build times, image size, or runtime performance

### **Before You Start**
1. **Check existing issues** to avoid duplicate work
2. **Open an issue** to discuss major changes before implementation
3. **Review the project structure** and coding standards
4. **Test your changes** thoroughly before submitting

## 🏗️ **Project Structure**

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

## 🔧 **Adding New Tools**

### **Step 1: Create Installation Script**
Create a new script in `resources/prebuildfs/opt/laragis/tools/`:

```bash
#!/usr/bin/env bash
# =============================================================================
# Tool Name
# =============================================================================
# DESCRIPTION: Brief description of the tool
# URL: https://github.com/owner/repo
# VERSION: v1.0.0
# AUTHOR: Your Name <your.email@example.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/arch.sh
. /opt/laragis/lib/os.sh

# Configuration
readonly TOOL_NAME="tool-name"
readonly TOOL_VERSION="${TOOL_VERSION:-1.0.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/${TOOL_NAME}.installed"
readonly INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

is_installed() { 
    os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]
}

install_tool() {
    local os="$(detect_os)"
    local arch="$(arch_auto)"
    
    # Your installation logic here
    # Download, extract, install the tool
    
    # Verify installation
    os_command_is_installed "$TOOL_NAME" || { 
        error "${TOOL_NAME} installation verification failed"
        return 1
    }

    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

main() {
    log_info "Installing ${TOOL_NAME} v${TOOL_VERSION}..."

    is_installed && { 
        log_info "${TOOL_NAME} is already installed"
        return 0
    }

    install_tool

    log_success "${TOOL_NAME} v${TOOL_VERSION} installed successfully"
}

main "$@"
```

### **Step 2: Update Dockerfile**
Add your tool to the appropriate section in the Dockerfile:

```dockerfile
# Your Tool - Brief description
# Repository: https://github.com/owner/repo
ARG YOUR_TOOL_VERSION=1.0.0

# Copy installation script
COPY resources/prebuildfs/opt/laragis/tools/your-tool.sh /opt/laragis/tools/your-tool.sh

# Install the tool
RUN if [ "${INSTALL_YOUR_TOOL}" = "true" ]; then \
        echo "==> Installing Your Tool v${YOUR_TOOL_VERSION}..." && \
        YOUR_TOOL_VERSION="${YOUR_TOOL_VERSION}" /opt/laragis/tools/your-tool.sh; \
    fi
```

### **Step 3: Update Configuration Files**
1. Add build argument to `docker-compose.yml`
2. Add installation flag to `.env.example` and `.env`
3. Update README.md with tool information

### **Step 4: Add Tests**
Add tests for your tool in `tests/test-container.bats`:

```bash
@test "Your tool is installed and functional" {
    run docker compose exec workspace your-tool --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"version"* ]]
}
```

## 🧪 **Testing Guidelines**

### **Running Tests**
```bash
# Run all tests
task test

# Run specific test categories
task test-tools
task test-services
task test-network

# Run performance benchmarks
task benchmark

# Run security scans
task security-scan
```

### **Test Requirements**
- All new tools must have corresponding tests
- Tests should verify both installation and basic functionality
- Performance-critical changes should include benchmark tests
- Security-related changes should include security tests

## 📝 **Documentation Standards**

### **Code Documentation**
- All shell scripts must include header comments with description, URL, and version
- Complex functions should have inline comments
- Use consistent formatting and indentation

### **README Updates**
- Add new tools to the tools table with repository links
- Update usage examples if applicable
- Include configuration options for new features

### **Commit Messages**
Use conventional commit format:
```
type(scope): description

feat(tools): add ripgrep for fast text searching
fix(docker): resolve build cache issue with DNF
docs(readme): update installation instructions
test(tools): add tests for new CLI tools
```

## 🔍 **Code Review Process**

### **Pull Request Guidelines**
1. **Clear title and description** explaining the changes
2. **Reference related issues** using keywords (fixes #123)
3. **Include test results** and verification steps
4. **Update documentation** as needed
5. **Keep changes focused** - one feature per PR

### **Review Checklist**
- [ ] Code follows project conventions
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] No security vulnerabilities introduced
- [ ] Performance impact is acceptable
- [ ] Backward compatibility is maintained

## 🚀 **Release Process**

### **Version Numbering**
We follow Semantic Versioning (SemVer):
- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### **Release Checklist**
1. Update version numbers in relevant files
2. Update CHANGELOG.md with release notes
3. Run comprehensive tests
4. Create release tag and GitHub release
5. Update Docker Hub images

## 🤝 **Community Guidelines**

### **Code of Conduct**
- Be respectful and inclusive
- Provide constructive feedback
- Help newcomers get started
- Focus on what's best for the community

### **Getting Help**
- **Issues**: For bug reports and feature requests
- **Discussions**: For questions and general discussion
- **Discord/Slack**: For real-time community chat (if available)

## 🎯 **Priority Areas**

We're particularly interested in contributions in these areas:

1. **Modern Development Tools**: Latest CLI tools and utilities
2. **IDE Integrations**: VS Code Server, Neovim configurations
3. **Cloud Platform Support**: Additional cloud provider tools
4. **Security Enhancements**: Security scanning and hardening
5. **Performance Optimization**: Build time and runtime improvements
6. **Documentation**: Tutorials, examples, and guides

## 📞 **Contact**

- **Maintainer**: Truong Thanh Tung <ttungbmt@gmail.com>
- **Project Repository**: https://github.com/gtelots/ws-oracle-linux
- **Issues**: https://github.com/gtelots/ws-oracle-linux/issues

Thank you for contributing to making this development container even better! 🚀
