#!/bin/bash
# =============================================================================
# Logging Functions - Clean, consistent logging across all scripts
# =============================================================================

set -euo pipefail

# Color codes for output formatting (only define if not already set)
if [[ -z "${RED:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly NC='\033[0m' # No Color
fi

# Check if gum is available for enhanced UI (only define if not already set)
if [[ -z "${GUM_AVAILABLE:-}" ]]; then
    GUM_AVAILABLE=false
    if command -v gum >/dev/null 2>&1; then
        GUM_AVAILABLE=true
    fi
fi

# Basic logging functions - used everywhere
log_info() {
    local message="$1"
    local prefix="${2:-INFO}"
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum log --level info "$message"
    else
        echo -e "${BLUE}[${prefix}]${NC} $message"
    fi
}

log_success() {
    local message="$1"
    local prefix="${2:-SUCCESS}"
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum log --level info "✅ $message"
    else
        echo -e "${GREEN}[${prefix}]${NC} ✅ $message"
    fi
}

log_warning() {
    local message="$1"
    local prefix="${2:-WARNING}"
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum log --level warn "$message"
    else
        echo -e "${YELLOW}[${prefix}]${NC} ⚠️ $message"
    fi
}

log_error() {
    local message="$1"
    local prefix="${2:-ERROR}"
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum log --level error "$message"
    else
        echo -e "${RED}[${prefix}]${NC} ❌ $message"
    fi >&2
}

log_debug() {
    local message="$1"
    local prefix="${2:-DEBUG}"
    if [[ "${DEBUG:-false}" == "true" ]]; then
        if [[ "$GUM_AVAILABLE" == "true" ]]; then
            gum log --level debug "$message"
        else
            echo -e "${PURPLE}[${prefix}]${NC} 🐛 $message"
        fi
    fi
}

# Specialized logging functions for different contexts
log_step() {
    local step_number="$1"
    local total_steps="$2"
    local message="$3"
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum log --level info "Step $step_number/$total_steps: $message"
    else
        echo -e "${CYAN}[STEP $step_number/$total_steps]${NC} $message"
    fi
}

log_install() {
    local tool_name="$1"
    local version="${2:-}"
    local message="Installing $tool_name"
    [[ -n "$version" ]] && message="$message (version: $version)"
    
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum log --level info "📦 $message"
    else
        echo -e "${BLUE}[INSTALL]${NC} 📦 $message"
    fi
}

log_install_success() {
    local tool_name="$1"
    local version="${2:-}"
    local message="$tool_name installed successfully"
    [[ -n "$version" ]] && message="$message (version: $version)"
    
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum log --level info "✅ $message"
    else
        echo -e "${GREEN}[INSTALL]${NC} ✅ $message"
    fi
}

log_install_skip() {
    local tool_name="$1"
    local reason="${2:-already installed}"
    local message="Skipping $tool_name installation: $reason"
    
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum log --level info "⏭️ $message"
    else
        echo -e "${YELLOW}[INSTALL]${NC} ⏭️ $message"
    fi
}

log_banner() {
    local title="$1"
    local width=60
    local padding=$((($width - ${#title} - 4) / 2))
    
    echo ""
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 $width))${NC}"
    echo -e "${CYAN}$(printf '%*s' $padding)  $title  $(printf '%*s' $padding)${NC}"
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 $width))${NC}"
    echo ""
}

log_separator() {
    echo -e "${CYAN}$(printf '%0.s-' {1..60})${NC}"
}

# Export all logging functions
export -f log_info log_success log_warning log_error log_debug
export -f log_step log_install log_install_success log_install_skip
export -f log_banner log_separator
