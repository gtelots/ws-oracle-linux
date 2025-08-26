#!/bin/bash

_have() { command -v "$1" >/dev/null 2>&1; }

# _arch_uname
# Purpose: Return kernel CPU arch with minimal alias normalization.
# Usage  : _arch_uname
# Output : x86_64, aarch64, armv7l, riscv64, ...
_arch_uname() {
  local m
  m="$(command uname -m 2>/dev/null || echo unknown)"
  case "$m" in
    amd64)  printf '%s\n' x86_64 ;;
    arm64)  printf '%s\n' aarch64 ;;
    *)      printf '%s\n' "$m" ;;
  esac
}

# arch_deb
# Purpose: Return Debian/Generic-style arch (used by many GitHub binaries).
# Usage  : arch_deb
# Env    : ARCH_DEB_OVERRIDE (force value, e.g. "amd64")
# Order  : override -> dpkg/dpkg-architecture -> uname mapping
# Output : amd64, arm64, armhf, armel, i386, ppc64el, s390x, riscv64, ...
arch_deb() {
  if [ -n "${ARCH_DEB_OVERRIDE:-}" ]; then
    printf '%s\n' "${ARCH_DEB_OVERRIDE}"
    return 0
  fi
  if command -v dpkg >/dev/null 2>&1; then
    dpkg --print-architecture
    return 0
  fi
  if command -v dpkg-architecture >/dev/null 2>&1; then
    dpkg-architecture -qDEB_BUILD_ARCH
    return 0
  fi
  case "$(_arch_uname)" in
    x86_64)              printf '%s\n' amd64 ;;
    aarch64)             printf '%s\n' arm64 ;;
    armv7l|armv7)        printf '%s\n' armhf ;;
    armv6l|armv6)        printf '%s\n' armel ;;
    i386|i486|i586|i686) printf '%s\n' i386 ;;
    ppc64le)             printf '%s\n' ppc64el ;;
    s390x)               printf '%s\n' s390x ;;
    riscv64)             printf '%s\n' riscv64 ;;
    *)                   printf '%s\n' "$(_arch_uname)" ;;
  esac
}

# arch_rpm
# Purpose: Return RPM-style arch (for RHEL/Oracle/Fedora/SUSE RPM packages).
# Usage  : arch_rpm
# Env    : ARCH_RPM_OVERRIDE (force value, e.g. "x86_64")
# Order  : override -> rpm macro -> uname mapping
# Output : x86_64, aarch64, armv7hl, armv6hl, i686, ppc64le, s390x, riscv64, ...
arch_rpm() {
  if [ -n "${ARCH_RPM_OVERRIDE:-}" ]; then
    printf '%s\n' "${ARCH_RPM_OVERRIDE}"
    return 0
  fi
  if command -v rpm >/dev/null 2>&1; then
    rpm --eval '%{_arch}'
    return 0
  fi
  case "$(_arch_uname)" in
    x86_64)              printf '%s\n' x86_64 ;;
    aarch64)             printf '%s\n' aarch64 ;;
    armv7l|armv7)        printf '%s\n' armv7hl ;;
    armv6l|armv6)        printf '%s\n' armv6hl ;;
    i386|i486|i586|i686) printf '%s\n' i686 ;;
    ppc64le)             printf '%s\n' ppc64le ;;
    s390x)               printf '%s\n' s390x ;;
    riscv64)             printf '%s\n' riscv64 ;;
    *)                   printf '%s\n' "$(_arch_uname)" ;;
  esac
}

# arch_style
# Purpose: Decide which naming style to use on this host.
# Usage  : arch_style
# Env    : ARCH_STYLE_OVERRIDE ("deb" | "rpm")
# Logic  : override -> package tools (dpkg/rpm) -> /etc/os-release hints -> default "deb"
# Output : "deb" or "rpm"
arch_style() {
  if [ -n "${ARCH_STYLE_OVERRIDE:-}" ]; then
    case "$ARCH_STYLE_OVERRIDE" in deb|rpm) printf '%s\n' "$ARCH_STYLE_OVERRIDE"; return 0;; esac
  fi
  if command -v dpkg >/dev/null 2>&1 && ! command -v rpm >/dev/null 2>&1; then
    printf '%s\n' deb; return 0
  fi
  if command -v rpm  >/dev/null 2>&1 && ! command -v dpkg >/dev/null 2>&1; then
    printf '%s\n' rpm; return 0
  fi
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    _id=$(printf '%s' "${ID:-}" | tr '[:upper:]' '[:lower:]')
    _like=$(printf '%s' "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')
    case "$_id" in
      ubuntu|debian)                          printf '%s\n' deb; return 0 ;;
      ol|oracle|oraclelinux|rhel|centos|rocky|almalinux|fedora|sles|opensuse)
                                               printf '%s\n' rpm; return 0 ;;
    esac
    case "$_like" in
      *debian*)                 printf '%s\n' deb; return 0 ;;
      *rhel*|*fedora*|*suse*)   printf '%s\n' rpm; return 0 ;;
    esac
  fi
  printf '%s\n' deb
}

# arch_auto
# Purpose: Return the proper arch string automatically by host style, or explicit style if given.
# Usage  : arch_auto [deb|rpm]
# Env    : ARCH_STYLE_OVERRIDE, ARCH_DEB_OVERRIDE, ARCH_RPM_OVERRIDE
# Output : amd64/arm64/... (DEB) or x86_64/aarch64/... (RPM)
arch_auto() {
  local style="${1:-}"
  if [ -z "$style" ]; then
    style="$(arch_style)"
  fi
  case "$style" in
    rpm) arch_rpm ;;
    deb|debian|generic) arch_deb ;;
    *)   arch_deb ;;  # safe default for most GitHub assets
  esac
}

export -f arch_style
export -f arch_auto
export -f arch_deb
export -f arch_rpm

# --- Example ---
# echo "style: $(arch_style)"    # deb | rpm
# echo "arch : $(arch_auto)"     # amd64 on Ubuntu, x86_64 on Oracle/RHEL
# echo "deb  : $(arch_auto deb)"
# echo "rpm  : $(arch_auto rpm)"