# Oracle Linux 9 Base Image Package Analysis

## Base Image Analysis Results

**Image**: `oraclelinux:9`
**Total Base Packages**: ~187 packages
**Analysis Date**: 2025-08-21

### What's Already Included
- Basic system libraries (glibc, systemd-libs, etc.)
- Core utilities (coreutils, findutils, bash)
- Network basics (curl, ca-certificates)
- Package manager (dnf)
- Basic security (crypto-policies, audit-libs)

### What's Missing for Development

## 1. Core System Packages (Essential Missing)

### Package Management & Repositories
- `dnf-plugins-core` - Essential DNF plugins for repository management
- `oracle-epel-release-el9` - EPEL repository for additional packages
- `dnf-utils` - Additional DNF utilities

### Basic System Utilities
- `sudo` - Privilege escalation (critical for containers)
- `shadow-utils` - User management utilities
- `util-linux-user` - User management commands (chsh, chfn)
- `procps-ng` - Process management (ps, top, kill)
- `psmisc` - Additional process utilities (pstree, killall)
- `lsof` - List open files utility

### File & Archive Management
- `tar` - Archive creation/extraction
- `xz` - XZ compression support
- `gzip` - Gzip compression
- `bzip2` - Bzip2 compression
- `unzip` - ZIP archive extraction
- `zip` - ZIP archive creation
- `rsync` - File synchronization

### Network Utilities
- `wget` - File downloading
- `iproute` - Modern network configuration
- `iputils` - Network testing (ping, traceroute)
- `bind-utils` - DNS utilities (dig, nslookup)
- `net-tools` - Legacy network tools (netstat, ifconfig)
- `nmap-ncat` - Network connectivity testing

### Text Processing & Search
- `grep` - Text searching
- `sed` - Stream editor
- `gawk` - AWK text processing
- `diffutils` - File comparison utilities
- `patch` - Apply patches to files
- `less` - Pager for viewing files
- `tree` - Directory tree display
- `jq` - JSON processor

### System Monitoring
- `htop` - Interactive process viewer
- `ncdu` - Disk usage analyzer

## 2. Essential Development Packages

### Text Editors
- `vim-enhanced` - Full-featured Vim editor
- `nano` - Simple text editor
- `emacs-nox` - Emacs without X11 (optional)

### Version Control
- `git` - Git version control
- `git-lfs` - Git Large File Storage
- `subversion` - SVN version control (optional)

### Build Tools & Compilers
- `gcc` - C compiler
- `gcc-c++` - C++ compiler
- `make` - Build automation
- `cmake` - Modern build system
- `autoconf` - Configure script generator
- `automake` - Makefile generator
- `libtool` - Library building helper
- `pkgconf-pkg-config` - Package configuration

### Development Libraries
- `glibc-devel` - C library development files
- `kernel-headers` - Kernel headers for development
- `openssl-devel` - SSL/TLS development libraries
- `zlib-devel` - Compression library development files
- `libcurl-devel` - cURL development libraries

### Debugging & Analysis
- `gdb` - GNU Debugger
- `strace` - System call tracer
- `valgrind` - Memory debugging tool
- `perf` - Performance analysis tools

### Shell & Environment
- `bash-completion` - Bash auto-completion
- `zsh` - Z shell (alternative shell)
- `man-pages` - Manual pages
- `man-db` - Manual page database

### Security & Cryptography
- `gnupg2` - GPG encryption
- `openssh-clients` - SSH client tools

### Language Runtimes (Optional but Common)
- `python3` - Python 3 interpreter
- `python3-pip` - Python package manager
- `nodejs` - Node.js runtime
- `npm` - Node.js package manager

## Optimized Installation Strategy

### Stage 1: Core System (Most Critical)
```bash
dnf install -y --setopt=install_weak_deps=False --nodocs \
    sudo shadow-utils util-linux-user procps-ng psmisc lsof \
    tar xz gzip bzip2 unzip zip rsync \
    wget iproute iputils bind-utils net-tools nmap-ncat \
    grep sed gawk diffutils patch less tree jq
```

### Stage 2: Development Essentials
```bash
dnf install -y --setopt=install_weak_deps=False --nodocs \
    vim-enhanced nano git git-lfs \
    gcc gcc-c++ make cmake autoconf automake libtool pkgconf-pkg-config \
    glibc-devel kernel-headers openssl-devel zlib-devel \
    gdb strace bash-completion zsh man-pages gnupg2 openssh-clients
```

### Stage 3: Enhanced Tools (Optional)
```bash
dnf install -y --setopt=install_weak_deps=False --nodocs \
    htop ncdu valgrind python3 python3-pip
```

## Package Group Alternative

Instead of individual packages, you can use DNF groups:
```bash
dnf groupinstall -y "Development Tools"
```

This installs: autoconf, automake, binutils, bison, flex, gcc, gcc-c++, gdb, glibc-devel, libtool, make, pkgconf, pkgconf-m4, pkgconf-pkg-config, redhat-rpm-config, rpm-build, rpm-sign, strace, and more.

## Implementation Files Created

1. **`Dockerfile.optimized`** - Production-ready Dockerfile with comprehensive package installation
2. **`scripts/setup/install-base-packages.sh`** - Modular package installation script
3. **`docs/PACKAGE-ANALYSIS.md`** - This analysis document

## Docker Build Optimization Features

### Multi-Stage Approach
- Repository setup in separate stage
- Package categories installed in logical order
- Cleanup performed at the end

### Layer Caching Optimization
- Stable packages installed first
- Frequently changing packages installed last
- Each stage creates optimal cache layers

### Size Optimization
- `--setopt=install_weak_deps=False` - Excludes recommended packages
- `--nodocs` - Excludes documentation
- Comprehensive cleanup of caches and temporary files
- Removal of unnecessary files

### Security Best Practices
- Non-root user creation
- Proper sudo configuration
- Secure defaults for development tools

## Usage Examples

### Build Optimized Image
```bash
docker build -f Dockerfile.optimized -t oracle-dev:optimized .
```

### Build with Custom Options
```bash
docker build -f Dockerfile.optimized \
  --build-arg INSTALL_NODEJS=1 \
  --build-arg INSTALL_ENHANCED_TOOLS=0 \
  -t oracle-dev:minimal .
```

### Use Installation Script
```bash
# In existing container
INSTALL_ENHANCED_TOOLS=0 ./scripts/setup/install-base-packages.sh
```
