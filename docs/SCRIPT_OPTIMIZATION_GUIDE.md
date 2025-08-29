# Script Optimization Guide

## 🎯 **OVERVIEW**

This guide provides step-by-step instructions for optimizing existing installation scripts using the shared library system. Follow this guide to eliminate code duplication and improve maintainability.

## 📋 **PREREQUISITES**

Before optimizing scripts, ensure you understand:
- **Shared library functions** available in `/opt/laragis/lib/`
- **Current script structure** and functionality
- **Testing requirements** for validation

## 🔧 **OPTIMIZATION PROCESS**

### **Step 1: Analyze Current Script**

#### **Identify Duplication Patterns:**
```bash
# Common patterns to look for:
- Tool configuration setup
- Architecture detection
- Download and installation logic
- Verification patterns
- Lock file management
```

#### **Example Analysis (before optimization):**
```bash
# Original script patterns
readonly TOOL_NAME="toolname"
readonly TOOL_VERSION="${TOOLNAME_VERSION:-1.0.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/toolname.installed"

is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }

# Architecture detection
local arch="$(uname -m)"
case "$arch" in
    "x86_64") arch="amd64" ;;
    "aarch64") arch="arm64" ;;
    *) log_error "Unsupported architecture: $arch"; return 1 ;;
esac

# Download logic
curl -fsSL "${download_url}" -o "${temp_dir}/file"
```

### **Step 2: Load Shared Libraries**

#### **Add Library Imports:**
```bash
#!/usr/bin/env bash
# Tool-specific header (keep existing)

# Load shared libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/install.sh
. /opt/laragis/lib/validation.sh  # If validation needed
. /opt/laragis/lib/github.sh      # If GitHub releases used
```

### **Step 3: Replace Configuration Setup**

#### **Before:**
```bash
readonly TOOL_NAME="toolname"
readonly TOOL_VERSION="${TOOLNAME_VERSION:-1.0.0}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/toolname.installed"
```

#### **After:**
```bash
# Configuration using shared function
setup_tool_config "toolname" "${TOOLNAME_VERSION:-1.0.0}"
```

### **Step 4: Replace Installation Check**

#### **Before:**
```bash
is_installed() { os_command_is_installed "$TOOL_NAME" || [[ -f "$TOOL_LOCK_FILE" ]]; }
```

#### **After:**
```bash
# Use shared function (no custom function needed)
if is_tool_installed "$TOOL_NAME" "$TOOL_LOCK_FILE"; then
    log_info "${TOOL_NAME} is already installed"
    return 0
fi
```

### **Step 5: Replace Installation Logic**

#### **For GitHub Releases (Before):**
```bash
local temp_dir="$(mktemp -d)"
trap "rm -rf '${temp_dir}'" EXIT

local arch="$(uname -m)"
case "$arch" in
    "x86_64") arch="amd64" ;;
    "aarch64") arch="arm64" ;;
    *) log_error "Unsupported architecture: $arch"; return 1 ;;
esac

local download_url="https://github.com/owner/repo/releases/download/v${TOOL_VERSION}/tool-${TOOL_VERSION}-linux-${arch}.tar.gz"
curl -fsSL "${download_url}" -o "${temp_dir}/tool.tar.gz"
cd "${temp_dir}"
tar -xzf tool.tar.gz
install -m 755 tool /usr/local/bin/tool
```

#### **For GitHub Releases (After):**
```bash
# Use shared GitHub installer
install_github_tool "owner/repo" "$TOOL_NAME" "$TOOL_VERSION" "package" "binary"
```

#### **For Cargo/Rust Tools (After):**
```bash
install_rust_tool_from_github "owner/repo" "$TOOL_NAME" "$TOOL_VERSION"
```

#### **For Custom Installation (After):**
```bash
# Custom installation function
install_custom_tool() {
  local temp_dir="$(create_temp_dir)"
  local arch="$(get_github_arch)"
  local download_url="https://example.com/tool-${arch}"
  
  if download_file "$download_url" "${temp_dir}/tool"; then
    install_binary "${temp_dir}/tool" "/usr/local/bin/$TOOL_NAME"
    return 0
  else
    return 1
  fi
}

# Use in main function
if try_package_install "$TOOL_NAME" || install_custom_tool; then
    # Success
else
    # Failure
fi
```

### **Step 6: Replace Verification and Cleanup**

#### **Before:**
```bash
os_command_is_installed "$TOOL_NAME" || { log_error "tool installation verification failed"; return 1; }
mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
```

#### **After:**
```bash
create_tool_lock_file "$TOOL_LOCK_FILE"
verify_tool_installation "$TOOL_NAME" "$TOOL_VERSION"
```

### **Step 7: Complete Optimized Structure**

#### **Final Optimized Script Template:**
```bash
#!/usr/bin/env bash
# =============================================================================
# toolname - Tool Description
# =============================================================================
# DESCRIPTION: Tool description
# URL: https://github.com/owner/repo
# VERSION: v1.0.0
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load shared libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh
. /opt/laragis/lib/install.sh
. /opt/laragis/lib/github.sh

# Configuration using shared function
setup_tool_config "toolname" "${TOOLNAME_VERSION:-1.0.0}"

# Custom installation function (if needed)
install_custom_tool() {
  # Tool-specific installation logic using shared utilities
  local temp_dir="$(create_temp_dir)"
  # ... custom logic ...
}

# Main function
main() {
  log_info "Installing ${TOOL_NAME} v${TOOL_VERSION}..."
  
  # Check if already installed
  if is_tool_installed "$TOOL_NAME" "$TOOL_LOCK_FILE"; then
    log_info "${TOOL_NAME} is already installed"
    return 0
  fi
  
  # Install using appropriate strategy
  if install_github_tool "owner/repo" "$TOOL_NAME" "$TOOL_VERSION" "strategies..."; then
    create_tool_lock_file "$TOOL_LOCK_FILE"
    log_success "${TOOL_NAME} v${TOOL_VERSION} installed successfully"
  else
    log_error "${TOOL_NAME} installation failed"
    return 1
  fi
}

main "$@"
```

## 📊 **OPTIMIZATION STRATEGIES**

### **Strategy 1: Standard GitHub Binary**
```bash
# For tools with standard GitHub release patterns
install_github_tool "owner/repo" "$TOOL_NAME" "$TOOL_VERSION" "package" "binary"
```

### **Strategy 2: Rust/Cargo Tools**
```bash
# For Rust tools available via cargo
install_rust_tool_from_github "owner/repo" "$TOOL_NAME" "$TOOL_VERSION"
```

### **Strategy 3: Go Tools**
```bash
# For Go tools with standard patterns
install_go_tool_from_github "owner/repo" "$TOOL_NAME" "$TOOL_VERSION"
```

### **Strategy 4: Node.js Tools**
```bash
# For Node.js tools available via npm
install_node_tool_from_github "owner/repo" "$TOOL_NAME" "$TOOL_VERSION"
```

### **Strategy 5: Custom Installation**
```bash
# For tools requiring custom installation logic
install_custom_tool() {
  # Use shared utilities for common operations
  local temp_dir="$(create_temp_dir)"
  local arch="$(get_github_arch)"
  
  if download_file "$custom_url" "${temp_dir}/file"; then
    # Custom processing
    install_binary "${temp_dir}/processed_file" "/usr/local/bin/$TOOL_NAME"
  fi
}
```

## ✅ **VALIDATION CHECKLIST**

### **Before Optimization:**
- [ ] Script functionality documented
- [ ] Current installation method understood
- [ ] Dependencies identified
- [ ] Test cases prepared

### **During Optimization:**
- [ ] Shared libraries loaded correctly
- [ ] Configuration setup using `setup_tool_config`
- [ ] Installation check using `is_tool_installed`
- [ ] Installation using appropriate shared function
- [ ] Lock file creation using `create_tool_lock_file`
- [ ] Verification using `verify_tool_installation`

### **After Optimization:**
- [ ] Script executes without errors
- [ ] Tool installs correctly
- [ ] Version verification works
- [ ] Lock file prevents reinstallation
- [ ] Error handling works properly
- [ ] Logging is consistent

## 🧪 **TESTING**

### **Unit Testing:**
```bash
# Test the optimized script
./optimized-script.sh

# Verify installation
command -v toolname
toolname --version

# Test reinstallation prevention
./optimized-script.sh  # Should skip installation
```

### **Integration Testing:**
```bash
# Run container tests
task test

# Run shared library tests
bats tests/test-shared-libraries.bats
```

## 📈 **EXPECTED IMPROVEMENTS**

### **Code Reduction:**
- **30-50% reduction** in script size
- **Elimination** of duplicated patterns
- **Simplified** maintenance

### **Quality Improvements:**
- **Consistent** error handling
- **Standardized** logging
- **Robust** installation logic
- **Better** verification

### **Maintainability:**
- **Centralized** updates
- **Shared** testing
- **Consistent** patterns
- **Reduced** complexity

## 🔍 **COMMON PATTERNS**

### **Pattern 1: Simple Binary Download**
```bash
# Tools that are single binaries from GitHub
install_github_tool "owner/repo" "$TOOL_NAME" "$TOOL_VERSION" "binary"
```

### **Pattern 2: Package Manager Fallback**
```bash
# Try package manager first, then GitHub
install_github_tool "owner/repo" "$TOOL_NAME" "$TOOL_VERSION" "package" "binary"
```

### **Pattern 3: Language-Specific Package Manager**
```bash
# Try language package manager first
install_github_tool "owner/repo" "$TOOL_NAME" "$TOOL_VERSION" "cargo" "binary"
```

### **Pattern 4: Custom URL Pattern**
```bash
# For non-standard GitHub release patterns
install_custom_tool() {
  local filename="$(generate_github_filename "$TOOL_NAME" "$TOOL_VERSION" "custom")"
  local url="$(build_github_download_url "owner/repo" "$TOOL_VERSION" "$filename")"
  # ... rest of custom logic
}
```

## 📋 **MIGRATION PRIORITY**

### **High Priority (Immediate):**
1. **Modern CLI tools** - High duplication, standard patterns
2. **Language package managers** - Consistent patterns
3. **System utilities** - Common installation logic

### **Medium Priority:**
1. **Setup scripts** - Less duplication but benefit from consistency
2. **Health check scripts** - Validation improvements
3. **Workflow scripts** - Utility function benefits

### **Low Priority:**
1. **One-off scripts** - Minimal duplication
2. **Legacy scripts** - May require careful handling
3. **Complex scripts** - Need thorough analysis

---

**Follow this guide to systematically optimize scripts and achieve significant improvements in code quality and maintainability.**
