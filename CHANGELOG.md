# Changelog

All notable changes to the Oracle Linux 9 Development Container project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Modern CLI Tools**: Added essential modern command-line tools
  - Neovim v0.10.3 - Hyperextensible Vim-based text editor
  - fd v10.2.0 - Simple, fast alternative to 'find'
  - ripgrep v14.1.1 - Line-oriented search tool
  - bat v0.24.0 - Cat clone with syntax highlighting
  - exa v0.10.1 - Modern replacement for 'ls'
  - HTTPie v3.2.4 - Modern HTTP client for API testing
  - bottom v0.10.2 - Cross-platform system monitor
  - Trivy v0.58.1 - Comprehensive security scanner

- **Enhanced Documentation**
  - Comprehensive README.md with detailed usage examples
  - Technical analysis document (ANALYSIS.md)
  - Contributing guidelines (CONTRIBUTING.md)
  - Complete tool inventory with repository links
  - Troubleshooting guide and FAQ section

- **Advanced Task Management**
  - Enhanced Taskfile.yml with 25+ tasks
  - Development workflow tasks (dev, dev-full, dev-minimal)
  - Testing and validation tasks (test, health, benchmark)
  - Security and maintenance tasks (security-scan, update, backup)
  - Monitoring and debugging tasks (monitor, tools, config)

- **Comprehensive Testing Framework**
  - Bats-based test suite for container validation
  - Tests for all major tool categories
  - Performance and security testing
  - Network connectivity validation
  - Service health checks

- **Feature Enhancements**
  - Selective tool installation via environment variables
  - Modern CLI tools integration
  - Enhanced error handling and logging
  - Improved build cache optimization
  - Security scanning capabilities

### Changed
- **Dockerfile Optimization**
  - Improved structure with clear section headers
  - Enhanced comments with repository links
  - Better layer organization for cache efficiency
  - Consolidated RUN commands to reduce layers

- **Configuration Management**
  - Updated .env.example with new tool flags
  - Enhanced docker-compose.yml with new build arguments
  - Improved environment variable organization

- **Documentation Structure**
  - Reorganized README with comprehensive sections
  - Added visual improvements with emojis and formatting
  - Enhanced usage examples and configuration guides

### Fixed
- Improved error handling in installation scripts
- Better validation for tool installations
- Enhanced logging and debugging capabilities

## [Previous Versions]

### [1.0.0] - Initial Release
- Basic Oracle Linux 9 development container
- Core development tools (Git, Docker, Python, Node.js)
- Infrastructure tools (Ansible, Terraform, kubectl, Helm)
- Cloud platform tools (AWS CLI, Cloudflared, Tailscale)
- Terminal enhancements (Starship, Zellij, Gum)
- Process management with Supervisor
- SSH server configuration
- Docker-in-Docker support

---

## Release Notes

### Modern CLI Tools Integration
This release significantly enhances the development experience by adding modern, performant alternatives to traditional Unix tools:

- **fd** replaces `find` with better performance and user-friendly syntax
- **ripgrep** provides blazing-fast text search across codebases
- **bat** enhances `cat` with syntax highlighting and Git integration
- **exa** modernizes `ls` with colors, icons, and Git status
- **HTTPie** simplifies API testing and HTTP requests
- **bottom** offers a beautiful alternative to `top` and `htop`
- **Neovim** provides a modern, extensible text editor
- **Trivy** adds comprehensive security scanning capabilities

### Enhanced Development Workflows
The new task system provides streamlined workflows for different development scenarios:

- **Development Mode**: `task dev` for enhanced development environment
- **Full Installation**: `task dev-full` with all tools enabled
- **Minimal Setup**: `task dev-minimal` for faster startup
- **Testing Suite**: `task test` for comprehensive validation
- **Health Monitoring**: `task health` and `task monitor` for system oversight

### Improved Documentation and Usability
- Complete tool inventory with versions and repository links
- Detailed usage examples for different development scenarios
- Comprehensive troubleshooting guide
- Contributing guidelines for community involvement
- Performance benchmarking and optimization tips

### Security Enhancements
- Integrated Trivy for vulnerability scanning
- Security-focused task workflows
- Enhanced container hardening practices
- Regular security update mechanisms

---

## Migration Guide

### From Previous Versions
1. **Update Configuration**: Copy new variables from `.env.example` to your `.env` file
2. **Rebuild Container**: Run `task rebuild` to get the latest tools
3. **Test Installation**: Run `task test` to verify everything works
4. **Explore New Tools**: Run `task tools` to see what's available

### New Environment Variables
Add these to your `.env` file to control new tool installations:
```bash
# Modern CLI Tools
INSTALL_NEOVIM=true
INSTALL_FD=true
INSTALL_RIPGREP=true
INSTALL_BAT=true
INSTALL_EXA=true
INSTALL_HTTPIE=true
INSTALL_BOTTOM=true
INSTALL_TRIVY=true
```

---

## Acknowledgments

Special thanks to all the open-source tool maintainers whose excellent work makes this development container possible:

- The Neovim team for the amazing editor
- The Rust community for fd, ripgrep, bat, exa, and bottom
- The HTTPie team for the excellent HTTP client
- Aqua Security for Trivy security scanner
- All contributors to the Oracle Linux 9 Development Container project

---

For detailed information about any release, please check the corresponding GitHub release page and documentation.
