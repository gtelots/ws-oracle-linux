#!/usr/bin/env bash
# =============================================================================
# SSH Service Setup
# =============================================================================
# DESCRIPTION: Configure SSH server and client for container
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly SSH_PORT="${SSH_PORT:-2222}"
readonly SSH_CONFIG_DIR="/etc/ssh"
readonly SSH_HOST_KEY_DIR="${SSH_CONFIG_DIR}"
readonly USER_SSH_DIR="/home/${USER_NAME}/.ssh"
readonly SUPERVISOR_CONFIG_DIR="/etc/supervisor/conf.d"

setup_ssh_server() {
    log_info "Setting up SSH server..."

    # Install OpenSSH server if not present
    if ! command -v sshd >/dev/null 2>&1; then
        log_info "Installing OpenSSH server..."
        dnf -y install openssh-server openssh-clients
    fi

    # Generate host keys if they don't exist
    if [[ ! -f "${SSH_HOST_KEY_DIR}/ssh_host_rsa_key" ]]; then
        log_info "Generating SSH host keys..."
        ssh-keygen -A
    fi

    # Create SSH configuration
    log_info "Configuring SSH server..."
    cat > "${SSH_CONFIG_DIR}/sshd_config" << EOF
# SSH Server Configuration for Container
Port ${SSH_PORT}
Protocol 2

# Host Keys
HostKey ${SSH_HOST_KEY_DIR}/ssh_host_rsa_key
HostKey ${SSH_HOST_KEY_DIR}/ssh_host_ecdsa_key
HostKey ${SSH_HOST_KEY_DIR}/ssh_host_ed25519_key

# Authentication
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
ChallengeResponseAuthentication no
UsePAM yes

# Security Settings
X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/libexec/openssh/sftp-server

# Container-specific settings
UsePrivilegeSeparation no
StrictModes no
EOF

    # Set proper permissions
    chmod 600 "${SSH_CONFIG_DIR}/sshd_config"
    chmod 600 "${SSH_HOST_KEY_DIR}"/ssh_host_*_key
    chmod 644 "${SSH_HOST_KEY_DIR}"/ssh_host_*_key.pub
}

setup_ssh_client() {
    log_info "Setting up SSH client configuration..."

    # Create SSH client configuration
    cat > "${SSH_CONFIG_DIR}/ssh_config" << EOF
# SSH Client Configuration for Container
Host *
    SendEnv LANG LC_*
    HashKnownHosts yes
    GSSAPIAuthentication yes
    GSSAPIDelegateCredentials no

    # Security settings
    Protocol 2
    ForwardAgent no
    ForwardX11 no

    # Connection settings
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ConnectTimeout 30

    # Key management
    IdentitiesOnly yes
    AddKeysToAgent yes
EOF

    chmod 644 "${SSH_CONFIG_DIR}/ssh_config"
}

setup_user_ssh() {
    log_info "Setting up user SSH configuration..."

    # Create user SSH directory
    mkdir -p "${USER_SSH_DIR}"
    chown "${USER_UID}:${USER_GID}" "${USER_SSH_DIR}"
    chmod 700 "${USER_SSH_DIR}"

    # Create authorized_keys file if it doesn't exist
    if [[ ! -f "${USER_SSH_DIR}/authorized_keys" ]]; then
        touch "${USER_SSH_DIR}/authorized_keys"
        chown "${USER_UID}:${USER_GID}" "${USER_SSH_DIR}/authorized_keys"
        chmod 600 "${USER_SSH_DIR}/authorized_keys"
    fi

    # Create known_hosts file
    if [[ ! -f "${USER_SSH_DIR}/known_hosts" ]]; then
        touch "${USER_SSH_DIR}/known_hosts"
        chown "${USER_UID}:${USER_GID}" "${USER_SSH_DIR}/known_hosts"
        chmod 644 "${USER_SSH_DIR}/known_hosts"
    fi

    # Create user SSH config
    cat > "${USER_SSH_DIR}/config" << EOF
# User SSH Configuration
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ConnectTimeout 30

    # Security
    HashKnownHosts yes
    VerifyHostKeyDNS yes

    # Key management
    IdentitiesOnly yes
    AddKeysToAgent yes

# Example host configurations
# Host myserver
#     HostName example.com
#     User myuser
#     Port 22
#     IdentityFile ~/.ssh/id_rsa
EOF

    chown "${USER_UID}:${USER_GID}" "${USER_SSH_DIR}/config"
    chmod 600 "${USER_SSH_DIR}/config"
}

setup_ssh_keys() {
    log_info "Setting up SSH key management..."

    # Copy incoming SSH keys if they exist
    local incoming_keys_dir="/opt/laragis/ssh/incoming"
    if [[ -d "${incoming_keys_dir}" ]]; then
        log_info "Processing incoming SSH keys..."

        # Copy public keys to authorized_keys
        find "${incoming_keys_dir}" -name "*.pub" -type f | while read -r pubkey; do
            log_info "Adding public key: $(basename "${pubkey}")"
            cat "${pubkey}" >> "${USER_SSH_DIR}/authorized_keys"
        done

        # Set proper permissions
        chown "${USER_UID}:${USER_GID}" "${USER_SSH_DIR}/authorized_keys"
        chmod 600 "${USER_SSH_DIR}/authorized_keys"
    fi

    # Generate default SSH key pair for the user if it doesn't exist
    if [[ ! -f "${USER_SSH_DIR}/id_rsa" ]]; then
        log_info "Generating default SSH key pair for user..."
        sudo -u "${USER_NAME}" ssh-keygen -t rsa -b 4096 -f "${USER_SSH_DIR}/id_rsa" -N "" -C "${USER_NAME}@container"

        log_info "SSH key pair generated:"
        log_info "  Private key: ${USER_SSH_DIR}/id_rsa"
        log_info "  Public key: ${USER_SSH_DIR}/id_rsa.pub"
    fi
}

setup_supervisor_integration() {
    log_info "Setting up Supervisor integration for SSH..."

    # Create Supervisor configuration for SSH
    cat > "${SUPERVISOR_CONFIG_DIR}/sshd.conf" << EOF
[program:sshd]
command=/usr/sbin/sshd -D -f ${SSH_CONFIG_DIR}/sshd_config
autostart=true
autorestart=true
startretries=3
user=root
redirect_stderr=true
stdout_logfile=/var/log/supervisor/sshd.log
stdout_logfile_maxbytes=10MB
stdout_logfile_backups=3
EOF

    log_info "SSH service configured for Supervisor management"
}

# Main function
main() {
    log_info "Setting up SSH service..."

    # Setup SSH components
    setup_ssh_server
    setup_ssh_client
    setup_user_ssh
    setup_ssh_keys
    setup_supervisor_integration

    log_success "SSH service setup completed successfully"
    log_info "SSH server will be available on port ${SSH_PORT}"
    log_info "Use 'ssh -p ${SSH_PORT} ${USER_NAME}@localhost' to connect"
}

main "$@"