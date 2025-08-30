#!/bin/bash

DNF_OPTS=( -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs )

ensure_pkgs() {
  local missing=()
  for p in "$@"; do rpm -q --quiet "$p" || missing+=("$p"); done
  ((${#missing[@]})) && dnf install "${DNF_OPTS[@]}" "${missing[@]}" || echo "All packages already installed: $*"
}

# Clean package manager cache
cleanup_cache() {
  log_info "Cleaning package manager cache to reduce layer size..."
  
  # Clean all caches
  dnf clean all
  
  # Remove cache directories
  rm -rf /var/cache/dnf/* /tmp/* 2>/dev/null || true
  
  log_success "Package manager cache cleaned"
}