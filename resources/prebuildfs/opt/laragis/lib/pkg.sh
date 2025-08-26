#!/bin/bash

DNF_OPTS=( -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs )

ensure_pkgs() {
  local missing=()
  for p in "$@"; do rpm -q --quiet "$p" || missing+=("$p"); done
  ((${#missing[@]})) && dnf install "${DNF_OPTS[@]}" "${missing[@]}" || echo "All packages already installed: $*"
}
