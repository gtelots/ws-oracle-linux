#!/usr/bin/env bash
# =============================================================================
# Bash Commons
# =============================================================================
# DESCRIPTION: Installs getoptions - A collection of reusable Bash functions for handling common tasks such as logging, assertions, string manipulation, and more
# URL: https://github.com/gruntwork-io/bash-commons
# VERSION: v1.0.0
# =============================================================================

set -euo pipefail;

readonly BASH_COMMONS_VERSION="${BASH_COMMONS_VERSION:-1.0.0}"
readonly BASH_COMMONS_DIR="${BASH_COMMONS_DIR:-/opt/gruntwork/bash-commons}"

tmp="$(mktemp -d)"
curl -fsSL "https://github.com/gruntwork-io/bash-commons/archive/refs/tags/v${BASH_COMMONS_VERSION}.tar.gz" -o "$tmp/bash-commons.tgz"
tar -xzf "$tmp/bash-commons.tgz" -C "$tmp"
mkdir -p "${BASH_COMMONS_DIR}"
cp -r "$tmp"/bash-commons-*/modules/bash-commons/src/* "${BASH_COMMONS_DIR}/"
rm -rf "$tmp"