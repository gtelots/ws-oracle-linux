# Scripts Directory Structure

This directory contains all scripts used in the Docker container build and runtime processes.

## Directory Structure

```
scripts/
├── init/           # Initialization scripts (run at container startup)
├── install/        # Installation scripts (run during Docker build)
├── setup/          # Configuration scripts (run during Docker build)
└── startup/        # Container startup scripts
```

## Script Categories

### `init/` - Container Initialization Scripts
Scripts that run automatically when the container starts up. These scripts:
- Configure runtime environment
- Set up user preferences
- Initialize development services
- Run in numerical order (01-, 02-, etc.)

**Examples:**
- `01-configure-git.sh` - Sets up Git configuration
- `02-setup-docker-stack.sh` - Creates Docker development stack

### `install/` - Installation Scripts
Scripts that install software packages and tools during Docker build. Organized by:
- `tools/` - Individual tool installers
- `python-tools.sh` - Python ecosystem tools
- `k8s-tools.sh` - Kubernetes tools
- `additional-packages.sh` - System packages

**Features:**
- Lock files prevent concurrent installations
- Installation markers prevent re-installation
- Detailed logging and error handling
- Architecture detection for downloads

### `setup/` - Configuration Scripts
Scripts that configure services and system settings during Docker build:
- `setup-ssh.sh` - SSH server configuration
- `setup-supervisor.sh` - Supervisor service manager
- `setup-dotfiles.sh` - User dotfiles setup
- `hosts-manager.sh` - /etc/hosts management utility

### `startup/` - Container Startup Scripts
Scripts that control container startup behavior:
- `start-container.sh` - Main container entry point
- Runs init scripts then starts services

## Usage Patterns

### Lock Files
Most installation scripts use lock files to prevent concurrent execution:
```bash
readonly LOCK_FILE="/tmp/script-name.lock"
```

### Installation Markers
Scripts create markers to skip re-installation:
```bash
readonly INSTALL_MARKER="/usr/local/bin/.tool-installed"
```

### Logging
All scripts use consistent logging functions:
```bash
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
```

### Error Handling
Scripts use strict error handling:
```bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
```

## Adding New Scripts

### Installation Scripts
1. Create script in appropriate subdirectory
2. Add lock file and installation marker
3. Include proper error handling and logging
4. Test for idempotency
5. Update main installation script if needed

### Initialization Scripts
1. Create script in `init/` with numeric prefix
2. Make it executable
3. Test that it runs successfully at startup
4. Ensure it's safe to run multiple times

### Configuration Scripts
1. Create script in `setup/`
2. Focus on one-time system configuration
3. Include validation of configuration state
4. Document any external dependencies

## Best Practices

1. **Idempotency**: Scripts should be safe to run multiple times
2. **Logging**: Use consistent logging throughout
3. **Error Handling**: Fail fast with clear error messages
4. **Documentation**: Include header comments explaining purpose
5. **Testing**: Test scripts independently and as part of build
6. **Lock Files**: Use locks for scripts that shouldn't run concurrently
7. **Markers**: Use installation markers to avoid duplicate work
8. **Architecture**: Support both x86_64 and aarch64 where applicable
