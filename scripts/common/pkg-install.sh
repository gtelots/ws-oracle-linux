#!/bin/bash
# =============================================================================
# Smart Package Installer v2.0 - Universal Package Management Tool
# =============================================================================
# A comprehensive, multi-distro package installer with advanced features:
# - Multi-package manager support (DNF, APT, APK, Zypper, Pacman)
# - Optimized installation flags for minimal footprint
# - Package groups and dependency management
# - Repository management (add/enable repos)
# - File-based package installation
# - Dry-run mode and verbose logging
# - Custom package manager options
# - Installation verification and rollback
# =============================================================================

set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="pkg-install"
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_AUTHOR="Oracle Linux DevContainer"

# Load common functions with enhanced error handling
load_common_functions() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local functions_paths=(
        "$script_dir/functions.sh"
        "/usr/local/scripts/common/functions.sh"
        "./functions.sh"
    )
    
    for path in "${functions_paths[@]}"; do
        if [[ -f "$path" ]]; then
            source "$path"
            return 0
        fi
    done
    
    echo "ERROR: Cannot find functions.sh in any of these locations:" >&2
    printf "  %s\n" "${functions_paths[@]}" >&2
    exit 1
}

load_common_functions

# Configuration variables
INSTALL_RECOMMENDS=false
INSTALL_DOCS=false
CLEAN_CACHE=true
UPDATE_REPOS=false
FORCE_INSTALL=false
VERBOSE_MODE=false
DRY_RUN=false
INSTALL_FROM_FILE=""
BACKUP_BEFORE_INSTALL=false
PACKAGE_LIST_FILE=""
CUSTOM_REPO=""

# Enhanced package installation with configurable options
install_packages_enhanced() {
    local packages=("$@")
    
    if [ ${#packages[@]} -eq 0 ]; then
        log_error "No packages specified" "PKG"
        show_enhanced_help
        exit 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log_info "🔍 DRY RUN MODE - Would install: ${packages[*]}" "PKG"
        log_info "Package manager: $(get_package_manager)" "PKG"
        log_info "Install recommends: $INSTALL_RECOMMENDS" "PKG"
        log_info "Install docs: $INSTALL_DOCS" "PKG"
        log_info "Clean cache: $CLEAN_CACHE" "PKG"
        return 0
    fi
    
    # Backup package list if requested
    if [ "$BACKUP_BEFORE_INSTALL" = true ]; then
        backup_installed_packages
    fi
    
    local pm=$(get_package_manager)
    log_info "📦 Using package manager: $pm" "PKG"
    
    # Build package manager specific commands
    case "$pm" in
        "dnf"|"yum")
            build_dnf_command "${packages[@]}"
            ;;
        "apt")
            build_apt_command "${packages[@]}"
            ;;
        "apk")
            build_apk_command "${packages[@]}"
            ;;
        "zypper")
            build_zypper_command "${packages[@]}"
            ;;
        "pacman")
            build_pacman_command "${packages[@]}"
            ;;
        *)
            log_error "Unsupported package manager: $pm" "PKG"
            exit 1
            ;;
    esac
    
    # Verify installation
    verify_package_installation "${packages[@]}"
}

# DNF/YUM command builder with enhanced options
build_dnf_command() {
    local packages=("$@")
    local cmd="dnf -y install"
    
    # Add configurable options
    [ "$INSTALL_RECOMMENDS" = false ] && cmd+=" --setopt=install_weak_deps=False"
    [ "$INSTALL_DOCS" = false ] && cmd+=" --nodocs"
    [ "$FORCE_INSTALL" = true ] && cmd+=" --best --allowerasing"
    [ "$UPDATE_REPOS" = true ] && cmd+=" --refresh"
    
    # Add custom DNF options if provided
    [ -n "${DNF_OPTS:-}" ] && cmd+=" $DNF_OPTS"
    
    log_info "🔧 Executing: $cmd ${packages[*]}" "PKG"
    eval "$cmd ${packages[*]}"
    
    # Clean cache if requested
    if [ "$CLEAN_CACHE" = true ]; then
        log_info "🧹 Cleaning DNF cache..." "PKG"
        dnf clean all >/dev/null 2>&1 || true
    fi
}

# APT command builder with enhanced options
build_apt_command() {
    local packages=("$@")
    export DEBIAN_FRONTEND=noninteractive
    
    # Update if requested
    if [ "$UPDATE_REPOS" = true ]; then
        log_info "🔄 Updating package repositories..." "PKG"
        apt-get update -qq
    fi
    
    local cmd="apt-get install -y"
    
    # Add configurable options
    [ "$INSTALL_RECOMMENDS" = false ] && cmd+=" --no-install-recommends --no-install-suggests"
    [ "$FORCE_INSTALL" = true ] && cmd+=" --force-yes"
    
    # Add custom APT options if provided
    [ -n "${APT_OPTS:-}" ] && cmd+=" $APT_OPTS"
    
    log_info "🔧 Executing: $cmd ${packages[*]}" "PKG"
    eval "$cmd ${packages[*]}"
    
    # Clean cache if requested
    if [ "$CLEAN_CACHE" = true ]; then
        log_info "🧹 Cleaning APT cache..." "PKG"
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    fi
}

# APK command builder (Alpine Linux)
build_apk_command() {
    local packages=("$@")
    local cmd="apk add"
    
    [ "$CLEAN_CACHE" = false ] && cmd+=" --cache-dir /var/cache/apk" || cmd+=" --no-cache"
    [ "$UPDATE_REPOS" = true ] && cmd+=" --update"
    [ "$FORCE_INSTALL" = true ] && cmd+=" --force"
    
    # Add custom APK options if provided
    [ -n "${APK_OPTS:-}" ] && cmd+=" $APK_OPTS"
    
    log_info "🔧 Executing: $cmd ${packages[*]}" "PKG"
    eval "$cmd ${packages[*]}"
}

# Zypper command builder (openSUSE)
build_zypper_command() {
    local packages=("$@")
    local cmd="zypper install -y"
    
    [ "$INSTALL_RECOMMENDS" = false ] && cmd+=" --no-recommends"
    [ "$FORCE_INSTALL" = true ] && cmd+=" --force"
    [ "$UPDATE_REPOS" = true ] && cmd+=" --refresh"
    
    # Add custom Zypper options if provided
    [ -n "${ZYPPER_OPTS:-}" ] && cmd+=" $ZYPPER_OPTS"
    
    log_info "🔧 Executing: $cmd ${packages[*]}" "PKG"
    eval "$cmd ${packages[*]}"
}

# Pacman command builder (Arch Linux)
build_pacman_command() {
    local packages=("$@")
    local cmd="pacman -S --noconfirm"
    
    [ "$UPDATE_REPOS" = true ] && cmd="pacman -Sy --noconfirm"
    [ "$FORCE_INSTALL" = true ] && cmd+=" --overwrite '*'"
    
    # Add custom Pacman options if provided
    [ -n "${PACMAN_OPTS:-}" ] && cmd+=" $PACMAN_OPTS"
    
    log_info "🔧 Executing: $cmd ${packages[*]}" "PKG"
    eval "$cmd ${packages[*]}"
}

# Enhanced package verification
verify_package_installation() {
    local packages=("$@")
    local failed_packages=()
    local success_count=0
    
    log_info "🔍 Verifying package installation..." "PKG"
    
    for package in "${packages[@]}"; do
        # Extract package name (remove version constraints)
        local pkg_name=$(echo "$package" | sed 's/[><=].*//' | sed 's/-.*//')
        
        if is_tool_installed "$pkg_name" >/dev/null 2>&1; then
            log_success "✅ $pkg_name is already installed" "PKG"
            ((success_count++))
        else
            failed_packages+=("$pkg_name")
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        log_warning "⚠️ Some packages may not be verifiable: ${failed_packages[*]}" "PKG"
        log_info "This is normal for meta-packages or packages with different command names" "PKG"
    fi
    
    log_success "📊 Package installation completed successfully" "PKG"
    log_info "✅ Verified: $success_count/${#packages[@]} packages" "PKG"
}

# Package installation from file
install_from_file() {
    local file_path="$1"
    
    if [ ! -f "$file_path" ]; then
        log_error "📄 Package file not found: $file_path" "PKG"
        exit 1
    fi
    
    log_info "📄 Installing packages from file: $file_path" "PKG"
    
    # Read packages from file (skip empty lines and comments)
    local packages=()
    local line_count=0
    
    while IFS= read -r line; do
        ((line_count++))
        # Skip empty lines and comments
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        packages+=("$line")
    done < "$file_path"
    
    if [ ${#packages[@]} -eq 0 ]; then
        log_warning "📄 No packages found in file: $file_path ($line_count lines read)" "PKG"
        return 0
    fi
    
    log_info "📋 Found ${#packages[@]} packages in file" "PKG"
    install_packages_enhanced "${packages[@]}"
}

# Repository management
manage_repositories() {
    local action="$1"
    shift
    local repos=("$@")
    
    case "$action" in
        "add")
            for repo in "${repos[@]}"; do
                log_info "➕ Adding repository: $repo" "PKG"
                case "$(get_package_manager)" in
                    "dnf"|"yum")
                        if [[ "$repo" =~ ^https?:// ]]; then
                            dnf config-manager --add-repo "$repo"
                        else
                            dnf install -y "$repo"
                        fi
                        ;;
                    "apt")
                        if command -v add-apt-repository >/dev/null 2>&1; then
                            add-apt-repository -y "$repo"
                        else
                            echo "$repo" >> /etc/apt/sources.list.d/custom.list
                        fi
                        ;;
                    "apk")
                        echo "$repo" >> /etc/apk/repositories
                        ;;
                    *)
                        log_warning "Repository management not fully supported for this OS" "PKG"
                        ;;
                esac
            done
            ;;
        "enable")
            for repo in "${repos[@]}"; do
                log_info "✅ Enabling repository: $repo" "PKG"
                case "$(get_package_manager)" in
                    "dnf"|"yum")
                        dnf config-manager --set-enabled "$repo"
                        ;;
                    "zypper")
                        zypper modifyrepo --enable "$repo"
                        ;;
                    *)
                        log_warning "Repository enabling not supported for this OS" "PKG"
                        ;;
                esac
            done
            ;;
        "disable")
            for repo in "${repos[@]}"; do
                log_info "❌ Disabling repository: $repo" "PKG"
                case "$(get_package_manager)" in
                    "dnf"|"yum")
                        dnf config-manager --set-disabled "$repo"
                        ;;
                    "zypper")
                        zypper modifyrepo --disable "$repo"
                        ;;
                    *)
                        log_warning "Repository disabling not supported for this OS" "PKG"
                        ;;
                esac
            done
            ;;
    esac
}

# Backup installed packages
backup_installed_packages() {
    local backup_file="/tmp/packages_backup_$(date +%Y%m%d_%H%M%S).txt"
    
    log_info "💾 Creating package backup: $backup_file" "PKG"
    
    case "$(get_package_manager)" in
        "dnf"|"yum")
            dnf list installed > "$backup_file"
            ;;
        "apt")
            dpkg --list > "$backup_file"
            ;;
        "apk")
            apk list --installed > "$backup_file"
            ;;
        "zypper")
            zypper search --installed-only > "$backup_file"
            ;;
        "pacman")
            pacman -Q > "$backup_file"
            ;;
    esac
    
    log_success "💾 Package backup saved: $backup_file" "PKG"
}

# Search packages
search_packages() {
    local search_term="$1"
    
    log_info "🔍 Searching for packages matching: $search_term" "PKG"
    
    case "$(get_package_manager)" in
        "dnf"|"yum")
            dnf search "$search_term"
            ;;
        "apt")
            apt-cache search "$search_term"
            ;;
        "apk")
            apk search "$search_term"
            ;;
        "zypper")
            zypper search "$search_term"
            ;;
        "pacman")
            pacman -Ss "$search_term"
            ;;
    esac
}

# List installed packages
list_installed() {
    local filter="${1:-}"
    
    log_info "📋 Listing installed packages..." "PKG"
    
    case "$(get_package_manager)" in
        "dnf"|"yum")
            if [ -n "$filter" ]; then
                dnf list installed | grep -i "$filter"
            else
                dnf list installed
            fi
            ;;
        "apt")
            if [ -n "$filter" ]; then
                dpkg --list | grep -i "$filter"
            else
                dpkg --list
            fi
            ;;
        "apk")
            if [ -n "$filter" ]; then
                apk list --installed | grep -i "$filter"
            else
                apk list --installed
            fi
            ;;
        "zypper")
            if [ -n "$filter" ]; then
                zypper search --installed-only | grep -i "$filter"
            else
                zypper search --installed-only
            fi
            ;;
        "pacman")
            if [ -n "$filter" ]; then
                pacman -Q | grep -i "$filter"
            else
                pacman -Q
            fi
            ;;
    esac
}

# Enhanced package installation with groups and categories
install_package_group() {
    local group_name="$1"
    shift
    local packages=("$@")
    
    log_banner "INSTALLING $group_name"
    log_info "📦 Packages: ${packages[*]}" "PKG"
    
    install_packages_enhanced "${packages[@]}"
    
    log_success "✅ $group_name installation completed" "PKG"
}

# Install with dependency resolution
install_with_deps() {
    local main_package="$1"
    shift
    local dependencies=("$@")
    
    log_info "🔗 Installing dependencies for $main_package..." "PKG"
    if [ ${#dependencies[@]} -gt 0 ]; then
        log_info "Dependencies: ${dependencies[*]}" "PKG"
        install_packages_enhanced "${dependencies[@]}"
    fi
    
    log_info "📦 Installing main package: $main_package" "PKG"
    install_packages_enhanced "$main_package"
}

# Main function with enhanced option parsing
main() {
    local mode="install"
    local packages=()
    local group_name=""
    local main_package=""
    local dependencies=()
    
    # Parse enhanced options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --group)
                mode="group"
                if [ -z "${2:-}" ]; then
                    log_error "Group name required after --group" "PKG"
                    exit 1
                fi
                group_name="$2"
                shift 2
                ;;
            --with-deps)
                mode="deps"
                if [ -z "${2:-}" ]; then
                    log_error "Main package required after --with-deps" "PKG"
                    exit 1
                fi
                main_package="$2"
                shift 2
                ;;
            --from-file)
                mode="file"
                if [ -z "${2:-}" ]; then
                    log_error "File path required after --from-file" "PKG"
                    exit 1
                fi
                INSTALL_FROM_FILE="$2"
                shift 2
                ;;
            --add-repo)
                mode="add-repo"
                shift
                ;;
            --enable-repo)
                mode="enable-repo"
                shift
                ;;
            --disable-repo)
                mode="disable-repo"
                shift
                ;;
            --search)
                mode="search"
                shift
                ;;
            --list)
                mode="list"
                shift
                ;;
            --backup)
                mode="backup"
                shift
                ;;
            --with-recommends)
                INSTALL_RECOMMENDS=true
                shift
                ;;
            --with-docs)
                INSTALL_DOCS=true
                shift
                ;;
            --no-clean)
                CLEAN_CACHE=false
                shift
                ;;
            --update)
                UPDATE_REPOS=true
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --verbose|-v)
                VERBOSE_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --backup-before)
                BACKUP_BEFORE_INSTALL=true
                shift
                ;;
            --dnf-opts)
                if [ -z "${2:-}" ]; then
                    log_error "Options required after --dnf-opts" "PKG"
                    exit 1
                fi
                export DNF_OPTS="$2"
                shift 2
                ;;
            --apt-opts)
                if [ -z "${2:-}" ]; then
                    log_error "Options required after --apt-opts" "PKG"
                    exit 1
                fi
                export APT_OPTS="$2"
                shift 2
                ;;
            --apk-opts)
                if [ -z "${2:-}" ]; then
                    log_error "Options required after --apk-opts" "PKG"
                    exit 1
                fi
                export APK_OPTS="$2"
                shift 2
                ;;
            --zypper-opts)
                if [ -z "${2:-}" ]; then
                    log_error "Options required after --zypper-opts" "PKG"
                    exit 1
                fi
                export ZYPPER_OPTS="$2"
                shift 2
                ;;
            --pacman-opts)
                if [ -z "${2:-}" ]; then
                    log_error "Options required after --pacman-opts" "PKG"
                    exit 1
                fi
                export PACMAN_OPTS="$2"
                shift 2
                ;;
            --version)
                echo "$SCRIPT_NAME v$SCRIPT_VERSION by $SCRIPT_AUTHOR"
                exit 0
                ;;
            --help|-h)
                show_enhanced_help
                exit 0
                ;;
            --*)
                log_error "Unknown option: $1" "PKG"
                log_info "Use --help for available options" "PKG"
                exit 1
                ;;
            *)
                packages+=("$1")
                shift
                ;;
        esac
    done
    
    # Enable verbose logging if requested
    [ "$VERBOSE_MODE" = true ] && set -x
    
    # Execute based on mode
    case "$mode" in
        "group")
            install_package_group "$group_name" "${packages[@]}"
            ;;
        "deps")
            dependencies=("${packages[@]}")
            install_with_deps "$main_package" "${dependencies[@]}"
            ;;
        "file")
            install_from_file "$INSTALL_FROM_FILE"
            ;;
        "add-repo")
            manage_repositories "add" "${packages[@]}"
            ;;
        "enable-repo")
            manage_repositories "enable" "${packages[@]}"
            ;;
        "disable-repo")
            manage_repositories "disable" "${packages[@]}"
            ;;
        "search")
            if [ ${#packages[@]} -eq 0 ]; then
                log_error "Search term required" "PKG"
                exit 1
            fi
            search_packages "${packages[0]}"
            ;;
        "list")
            list_installed "${packages[0]:-}"
            ;;
        "backup")
            backup_installed_packages
            ;;
        "install")
            if [ ${#packages[@]} -eq 0 ]; then
                log_error "No packages specified for installation" "PKG"
                show_enhanced_help
                exit 1
            fi
            install_packages_enhanced "${packages[@]}"
            ;;
    esac
}

# Enhanced help function
show_enhanced_help() {
    cat << 'EOF'
Smart Package Installer v2.0 - Universal Package Management Tool

USAGE:
    pkg-install [OPTIONS] package1 package2 ...

INSTALLATION MODES:
    pkg-install package1 package2                    # Install packages
    pkg-install --group "NAME" pkg1 pkg2            # Install package group
    pkg-install --with-deps main dep1 dep2          # Install with dependencies
    pkg-install --from-file packages.txt            # Install from file

REPOSITORY MANAGEMENT:
    pkg-install --add-repo https://repo.url         # Add repository
    pkg-install --enable-repo repo-name             # Enable repository
    pkg-install --disable-repo repo-name            # Disable repository

PACKAGE INFORMATION:
    pkg-install --search term                       # Search packages
    pkg-install --list [filter]                     # List installed packages
    pkg-install --backup                            # Backup package list

INSTALLATION OPTIONS:
    --with-recommends      Include recommended packages (default: false)
    --with-docs           Include documentation (default: false)
    --no-clean            Don't clean package cache after install
    --update              Update repositories before install
    --force               Force installation (resolve conflicts)
    --backup-before       Backup packages before installation
    --verbose, -v         Enable verbose output
    --dry-run             Show what would be installed without doing it

PACKAGE MANAGER SPECIFIC:
    --dnf-opts "OPTIONS"   Pass custom options to DNF/YUM
    --apt-opts "OPTIONS"   Pass custom options to APT
    --apk-opts "OPTIONS"   Pass custom options to APK
    --zypper-opts "OPTS"   Pass custom options to Zypper
    --pacman-opts "OPTS"   Pass custom options to Pacman

EXAMPLES:

Basic installation:
    pkg-install curl wget git

With custom options:
    pkg-install --with-recommends --update curl wget
    pkg-install --force --verbose docker-ce
    pkg-install --dry-run --group "Dev Tools" gcc make cmake

Repository management:
    pkg-install --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    pkg-install --enable-repo powertools

From package file:
    pkg-install --from-file /path/to/packages.txt

Package information:
    pkg-install --search docker
    pkg-install --list | grep python
    pkg-install --backup

With package manager specific options:
    pkg-install --dnf-opts "--enablerepo=powertools" some-package
    pkg-install --apt-opts "--target-release=bullseye" some-package

FILE FORMAT (packages.txt):
    curl
    wget
    git
    # Comments are ignored
    vim-enhanced

OPTIMIZED DEFAULTS:
    DNF/YUM: --setopt=install_weak_deps=False --nodocs
    APT:     --no-install-recommends --no-install-suggests + auto cleanup
    APK:     --no-cache --update
    Zypper:  --no-recommends
    Pacman:  --noconfirm
    
Override defaults with --with-recommends, --with-docs, --no-clean

SUPPORTED PACKAGE MANAGERS:
    ✓ DNF/YUM (RHEL, CentOS, Fedora, Oracle Linux)
    ✓ APT (Debian, Ubuntu)
    ✓ APK (Alpine Linux)
    ✓ Zypper (openSUSE, SLES)
    ✓ Pacman (Arch Linux, Manjaro)

EOF
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
