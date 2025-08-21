#!/bin/bash
# =============================================================================
# UI Functions - User interaction and progress display
# =============================================================================

set -euo pipefail

# Ensure logging is available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

# Progress indicator
show_progress() {
    local message="$1"
    local duration="${2:-1}"
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum spin --spinner dot --title "$message" -- sleep "$duration"
    else
        echo -e "${CYAN}⏳${NC} $message..."
        sleep "$duration"
    fi
}

# Show progress with command execution
show_progress_with_command() {
    local message="$1"
    local command="$2"
    
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum spin --spinner dot --title "$message" -- bash -c "$command"
    else
        echo -e "${CYAN}⏳${NC} $message..."
        bash -c "$command"
    fi
}

# Confirmation prompt
confirm() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum confirm "$message"
    else
        local prompt_suffix="(y/N)"
        [[ "$default" == "y" ]] && prompt_suffix="(Y/n)"
        
        echo -e "${YELLOW}❓${NC} $message $prompt_suffix"
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            [nN][oO]|[nN]) return 1 ;;
            "") [[ "$default" == "y" ]] && return 0 || return 1 ;;
            *) return 1 ;;
        esac
    fi
}

# Input prompt
prompt_input() {
    local prompt="$1"
    local placeholder="${2:-}"
    local default="${3:-}"
    
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        if [[ -n "$placeholder" ]]; then
            gum input --placeholder "$placeholder" --prompt "$prompt: " --value "$default"
        else
            gum input --prompt "$prompt: " --value "$default"
        fi
    else
        local full_prompt="$prompt"
        [[ -n "$placeholder" ]] && full_prompt="$full_prompt ($placeholder)"
        [[ -n "$default" ]] && full_prompt="$full_prompt [$default]"
        
        echo -e "${CYAN}❓${NC} $full_prompt: "
        read -r input
        echo "${input:-$default}"
    fi
}

# Password input (hidden)
prompt_password() {
    local prompt="$1"
    
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum input --password --prompt "$prompt: "
    else
        echo -e "${CYAN}🔒${NC} $prompt: "
        read -s -r password
        echo
        echo "$password"
    fi
}

# Selection from list
select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum choose --header "$prompt" "${options[@]}"
    else
        echo -e "${CYAN}❓${NC} $prompt"
        local i=1
        for option in "${options[@]}"; do
            echo "$i) $option"
            ((i++))
        done
        echo -n "Select option (1-${#options[@]}): "
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#options[@]}" ]]; then
            echo "${options[$((choice-1))]}"
        else
            echo ""
            return 1
        fi
    fi
}

# Multi-select from list
select_multiple() {
    local prompt="$1"
    shift
    local options=("$@")
    
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum choose --no-limit --header "$prompt" "${options[@]}"
    else
        echo -e "${CYAN}❓${NC} $prompt (enter numbers separated by spaces, e.g., '1 3 5')"
        local i=1
        for option in "${options[@]}"; do
            echo "$i) $option"
            ((i++))
        done
        echo -n "Select options: "
        read -r choices
        
        local selected=()
        for choice in $choices; do
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#options[@]}" ]]; then
                selected+=("${options[$((choice-1))]}")
            fi
        done
        
        printf '%s\n' "${selected[@]}"
    fi
}

# Display table
show_table() {
    local headers=("$@")
    
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        # gum table command with headers
        gum table --headers="${headers[*]}"
    else
        # Simple table formatting
        printf '%-20s' "${headers[@]}"
        echo
        printf '%-20s' $(printf '=%.0s' $(seq 1 20))
        echo
        # Note: Data should be piped to this function
        while IFS= read -r line; do
            echo "$line"
        done
    fi
}

# Progress bar
show_progress_bar() {
    local current="$1"
    local total="$2"
    local message="${3:-Progress}"
    
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        local percentage=$((current * 100 / total))
        echo "$percentage% $message"
    else
        local percentage=$((current * 50 / total))
        local filled=$(printf '█%.0s' $(seq 1 $percentage))
        local empty=$(printf '░%.0s' $(seq 1 $((50 - percentage))))
        printf '\r%s [%s%s] %d/%d %s' "$message" "$filled" "$empty" "$current" "$total" ""
        [[ "$current" -eq "$total" ]] && echo
    fi
}

# File browser
browse_files() {
    local start_path="${1:-.}"
    local prompt="${2:-Select a file}"
    
    if [[ "$GUM_AVAILABLE" == "true" ]]; then
        gum file --directory="$start_path" --header="$prompt"
    else
        echo -e "${CYAN}❓${NC} $prompt"
        echo "Current directory: $(realpath "$start_path")"
        echo "Available files:"
        find "$start_path" -maxdepth 1 -type f -exec basename {} \; | sort
        echo -n "Enter filename: "
        read -r filename
        echo "$start_path/$filename"
    fi
}

# Export UI functions
export -f show_progress show_progress_with_command confirm prompt_input prompt_password
export -f select_option select_multiple show_table show_progress_bar browse_files
