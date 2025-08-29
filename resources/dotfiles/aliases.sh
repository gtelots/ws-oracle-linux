#!/usr/bin/env bash
# =============================================================================
# Shared Shell Aliases for Oracle Linux Development Container
# =============================================================================
# DESCRIPTION: Common aliases for both bash and zsh shells with fallbacks
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# =============================================================================
# Modern CLI Tool Aliases (with fallbacks)
# =============================================================================

# Directory listing aliases
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto --group-directories-first'
    alias ll='eza -la --color=auto --group-directories-first'
    alias la='eza -a --color=auto --group-directories-first'
    alias lt='eza --tree --color=auto'
else
    alias ls='ls --color=auto'
    alias ll='ls -la --color=auto'
    alias la='ls -a --color=auto'
    alias lt='tree'
fi

# File content viewing
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --style=auto'
    alias less='bat --style=auto --paging=always'
else
    alias cat='cat'
    alias less='less'
fi

# File searching
if command -v fd >/dev/null 2>&1; then
    alias find='fd'
else
    alias find='find'
fi

# Text searching
if command -v rg >/dev/null 2>&1; then
    alias grep='rg'
else
    alias grep='grep --color=auto'
fi

# Process monitoring
if command -v procs >/dev/null 2>&1; then
    alias ps='procs'
else
    alias ps='ps'
fi

# System monitoring
if command -v btop >/dev/null 2>&1; then
    alias top='btop'
elif command -v htop >/dev/null 2>&1; then
    alias top='htop'
else
    alias top='top'
fi

# Disk usage
if command -v duf >/dev/null 2>&1; then
    alias df='duf'
else
    alias df='df -h'
fi

if command -v dust >/dev/null 2>&1; then
    alias du='dust'
elif command -v ncdu >/dev/null 2>&1; then
    alias du='ncdu'
else
    alias du='du -h'
fi

# Network tools
if command -v gping >/dev/null 2>&1; then
    alias ping='gping'
else
    alias ping='ping'
fi

# =============================================================================
# Git Aliases
# =============================================================================

alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate'
alias gs='git status'
alias gss='git status --short'
alias gd='git diff'
alias gdc='git diff --cached'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gba='git branch -a'
alias gm='git merge'
alias gr='git remote'
alias grv='git remote -v'

# =============================================================================
# Docker Aliases
# =============================================================================

alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dv='docker volume ls'
alias dn='docker network ls'
alias dlog='docker logs'
alias dexec='docker exec -it'

# =============================================================================
# Kubernetes Aliases
# =============================================================================

alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kl='kubectl logs'
alias ke='kubectl exec -it'

# =============================================================================
# System Navigation Aliases
# =============================================================================

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# =============================================================================
# System Utility Aliases
# =============================================================================

alias h='history'
alias c='clear'
alias e='exit'
alias q='exit'
alias reload='exec $SHELL'

# File operations
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias mkdir='mkdir -p'

# Network and system info
alias ports='netstat -tulanp'
alias myip='curl -s https://ipinfo.io/ip'
alias weather='curl -s wttr.in'

# =============================================================================
# Development Aliases
# =============================================================================

# Editor aliases
if command -v nvim >/dev/null 2>&1; then
    alias vim='nvim'
    alias vi='nvim'
    alias v='nvim'
else
    alias v='vim'
fi

# Python aliases
alias py='python3'
alias pip='pip3'

# Node.js aliases
alias ni='npm install'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'

# =============================================================================
# Modern CLI Tool Specific Aliases
# =============================================================================

# fzf integration
if command -v fzf >/dev/null 2>&1; then
    alias fzf-preview='fzf --preview "bat --color=always --style=numbers --line-range=:500 {}"'
fi

# zoxide integration
if command -v zoxide >/dev/null 2>&1; then
    alias z='zoxide'
    alias zi='zoxide query -i'
fi

# HTTPie aliases
if command -v http >/dev/null 2>&1; then
    alias GET='http GET'
    alias POST='http POST'
    alias PUT='http PUT'
    alias DELETE='http DELETE'
fi

# Just command runner
if command -v just >/dev/null 2>&1; then
    alias j='just'
    alias jl='just --list'
fi

# Hyperfine benchmarking
if command -v hyperfine >/dev/null 2>&1; then
    alias bench='hyperfine'
fi

# System information
if command -v fastfetch >/dev/null 2>&1; then
    alias sysinfo='fastfetch'
elif command -v neofetch >/dev/null 2>&1; then
    alias sysinfo='neofetch'
fi

# =============================================================================
# Conditional Aliases Based on Environment
# =============================================================================

# Container-specific aliases
if [[ -f /.dockerenv ]]; then
    alias container-info='echo "Running in Docker container"'
fi

# SSH-specific aliases
if [[ -n "$SSH_CONNECTION" ]]; then
    alias ssh-info='echo "Connected via SSH from: ${SSH_CLIENT%% *}"'
fi
