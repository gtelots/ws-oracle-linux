#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Main execution
main() {
  # ---- Guards & defaults (fail fast if missing) ----
  : "${USER_NAME:?USER_NAME required}"
  : "${USER_UID:?USER_UID required}"
  : "${USER_GID:?USER_GID required}"
  USER_SHELL="${USER_SHELL:-/bin/bash}"
  HOME_DIR="${HOME_DIR:-/home/${USER_NAME}}"
  SUDO_POLICY="${SUDO_POLICY:-nopass}"   # skip|safe|nopass

  # ---- Inputs: prefer CLI, then env ----
  local root_password="${1:-${ROOT_PASSWORD:-root}}"
  local user_password="${2:-${USER_PASSWORD:-dev}}"
  
  # ---- Ensure required packages ----
  pkg-install sudo

  # --- Ensure primary group exists: reuse by name or GID; create if missing ---
  { getent group "${USER_NAME}" || getent group "${USER_GID}"; } >/dev/null 2>&1 || groupadd -g "${USER_GID}" "${USER_NAME}"

  # --- Ensure wheel group exists (shared sudo policy for multiple dev users) ---
  getent group wheel >/dev/null 2>&1 || groupadd wheel

  # --- Ensure user exists; add to wheel; idempotent ---
  id -u "${USER_NAME}" >/dev/null 2>&1 || useradd -u "${USER_UID}" -g "${USER_GID}" -G wheel -m -s "${USER_SHELL}" "${USER_NAME}"

  # --- Set passwords: prefer BuildKit secrets, fallback to ARGs; lock if empty ---
  read_secret_or() { local f="$1" fallback="$2" v; [[ -f "$f" ]] && IFS= read -r v <"$f" && printf '%s' "$v" || printf '%s' "$fallback"; }
  local ROOT_PW USER_PW
  ROOT_PW="$(read_secret_or /run/secrets/root_pw "${root_password}")"
  USER_PW="$(read_secret_or /run/secrets/user_pw "${user_password}")"

  if [ -n "$ROOT_PW" ]; then case "$ROOT_PW" in \$*) echo "root:${ROOT_PW}" | chpasswd -e ;; *) echo "root:${ROOT_PW}" | chpasswd ;; esac
  else passwd -l root || true; fi

  if [ -n "$USER_PW" ]; then case "$USER_PW" in \$*) echo "${USER_NAME}:${USER_PW}" | chpasswd -e ;; *) echo "${USER_NAME}:${USER_PW}" | chpasswd ;; esac
  else passwd -l "${USER_NAME}" || true; fi

  # ---- Optional sudoers policy ----
  # Sudo configuration via sudoers.d (safer than editing /etc/sudoers directly) ---
  if [[ "$SUDO_POLICY" != "skip" ]]; then
    install -d -m 0755 /etc/sudoers.d
    : > /etc/sudoers.d/00-defaults
    echo 'Defaults !requiretty' >> /etc/sudoers.d/00-defaults
    echo 'Defaults env_reset' >> /etc/sudoers.d/00-defaults
    echo 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> /etc/sudoers.d/00-defaults
    chmod 0440 /etc/sudoers.d/00-defaults

    case "$SUDO_POLICY" in
      safe)   echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/99-wheel ;;
      nopass) printf '%%wheel ALL=(ALL:ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/99-wheel ;;
      *) echo "Unknown SUDO_POLICY: $SUDO_POLICY (use: skip|safe|nopass)" >&2; exit 2 ;;
    esac
    chmod 0440 /etc/sudoers.d/99-wheel

    # Ensure /etc/sudoers includes sudoers.d (if the distro file lacks it)
    grep -q '^#includedir /etc/sudoers.d' /etc/sudoers || echo '#includedir /etc/sudoers.d' >> /etc/sudoers
    # Validate the complete sudoers configuration (includes) when visudo is available
    command -v visudo >/dev/null 2>&1 && visudo -cf /etc/sudoers >/dev/null
  fi

  # ---- Prepare HOME skeleton & ownership ----
  mkdir -p "${HOME_DIR}"/{.ssh,.local/bin,.config,.cache}
  chown -R "${USER_UID}:${USER_GID}" "${HOME_DIR}"
  chmod 700 "${HOME_DIR}/.ssh"

  echo "OK: user ${USER_NAME} ready (sudo=${SUDO_POLICY})"
}

# Run main function
main "$@"