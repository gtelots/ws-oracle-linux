#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/log.sh"

# Returns true (0) if this the given command/app is installed and on the PATH or false (1) otherwise.
function os_command_is_installed {
  local -r name="$1"
  command -v "$name" > /dev/null 2>&1
}

# detect_os
# Purpose: Detect the host operating system (coarse-grained) with common sub-flavors.
# Usage  : detect_os        # prints: linux | darwin | windows | freebsd | openbsd | netbsd | solaris | aix
# Output : stdout -> normalized OS id (one of the above)
# Sets   : OS_ID, OS_FLAVOR, OS_PRETTY, OS_UNAME  (globals; not readonly for reusability)
# Notes  : On WSL, OS_ID="linux" and OS_FLAVOR="wsl". On MSYS/MINGW/Cygwin, OS_ID="windows" with appropriate flavor.
detect_os() {
  # Reset globals each call (safe to re-run)
  OS_ID=""
  OS_FLAVOR=""
  OS_PRETTY=""
  OS_UNAME="$(command uname -s 2>/dev/null || echo unknown)"

  # Normalize helper
  _ci_grep() { grep -qiE "$1" "$2" 2>/dev/null; }

  case "$OS_UNAME" in
    Darwin*)
      OS_ID="darwin"
      OS_PRETTY="macOS"
      ;;
    Linux*)
      # Detect WSL (any reasonable signal)
      if _ci_grep 'microsoft|wsl' /proc/version || \
         _ci_grep 'microsoft|wsl' /proc/sys/kernel/osrelease || \
         [ -n "${WSL_INTEROP:-}" ] || [ -d /mnt/c/Windows ]; then
        OS_FLAVOR="wsl"
        OS_PRETTY="Linux (Windows Subsystem for Linux)"
      else
        OS_PRETTY="Linux"
      fi
      OS_ID="linux"
      ;;
    CYGWIN* | *-CYGWIN*)
      OS_ID="windows"
      OS_FLAVOR="cygwin"
      OS_PRETTY="Windows (Cygwin)"
      ;;
    MSYS* | MINGW* | *-MSYS* | *-MINGW*)
      OS_ID="windows"
      # Distinguish MSYS vs MINGW when possible
      if printf '%s' "$OS_UNAME" | grep -q "MINGW"; then
        OS_FLAVOR="mingw"
        OS_PRETTY="Windows (MinGW)"
      else
        OS_FLAVOR="msys"
        OS_PRETTY="Windows (MSYS)"
      fi
      ;;
    FreeBSD*)
      OS_ID="freebsd"
      OS_PRETTY="FreeBSD"
      ;;
    OpenBSD*)
      OS_ID="openbsd"
      OS_PRETTY="OpenBSD"
      ;;
    NetBSD*)
      OS_ID="netbsd"
      OS_PRETTY="NetBSD"
      ;;
    SunOS*)
      OS_ID="solaris"
      OS_PRETTY="Solaris"
      ;;
    AIX*)
      OS_ID="aix"
      OS_PRETTY="AIX"
      ;;
    *)
      OS_ID="unknown"
      OS_PRETTY="$OS_UNAME"
      ;;
  esac

  printf '%s\n' "$OS_ID"
}