#!/bin/bash
# -----------------------------------------------------------------------------
# SSH Server Setup Script for Oracle Linux 9 Container
# -----------------------------------------------------------------------------
# This script configures SSH server with security best practices
# and sets up SSH keys for passwordless access if available
# -----------------------------------------------------------------------------

set -euo pipefail

# Function to log messages
log() {
    echo "==> $1"
}

# Helper function to copy file to both users
copy_to_users() {
    local src_file="$1"
    local dest_path="$2"
    local username="$3"
    local user_uid="$4"
    local user_gid="$5"
    local permission="$6"
    
    cp "$src_file" "/root/$dest_path"
    cp "$src_file" "/home/${username}/$dest_path"
    chmod "$permission" "/root/$dest_path"
    chmod "$permission" "/home/${username}/$dest_path"
    chown "${user_uid}:${user_gid}" "/home/${username}/$dest_path"
}

# Function to setup SSH keys
setup_ssh_keys() {
    local ssh_dir="$1"
    local username="$2"
    local user_uid="$3"
    local user_gid="$4"
    
    if [ ! -d "$ssh_dir" ] || [ -z "$(ls -A "$ssh_dir/" 2>/dev/null)" ]; then
        log "No SSH keys found in $ssh_dir, password authentication only"
        return 0
    fi
    
    log "Setting up SSH keys from $ssh_dir with folder structure"
    
    # Create organized directory structure
    mkdir -p /root/.ssh/incoming /root/.ssh/outgoing
    mkdir -p "/home/${username}/.ssh/incoming" "/home/${username}/.ssh/outgoing"
    
    # Setup workspace access keys (incoming folder)
    if [ -d "$ssh_dir/incoming" ]; then
        log "Processing incoming access keys (for workspace access)"
        for key_file in "$ssh_dir/incoming"/*; do
            if [ -f "$key_file" ]; then
                local key_name=$(basename "$key_file")
                
                if [[ "$key_name" == *.pub ]]; then
                    log "  Adding public key to authorized_keys: $key_name"
                    cat "$key_file" >> /root/.ssh/authorized_keys
                    cat "$key_file" >> "/home/${username}/.ssh/authorized_keys"
                    # Keep in organized structure
                    copy_to_users "$key_file" ".ssh/incoming/$key_name" "$username" "$user_uid" "$user_gid" "644"
                else
                    log "  Installing incoming private key: $key_name"
                    # Keep in organized structure
                    copy_to_users "$key_file" ".ssh/incoming/$key_name" "$username" "$user_uid" "$user_gid" "600"
                fi
            fi
        done
    fi
    
    # Setup outgoing access keys (outgoing folder)
    if [ -d "$ssh_dir/outgoing" ]; then
        log "Processing outgoing access keys (for connecting to other servers)"
        for key_file in "$ssh_dir/outgoing"/*; do
            if [ -f "$key_file" ]; then
                local key_name=$(basename "$key_file")
                log "  Installing outgoing access key: $key_name"
                copy_to_users "$key_file" ".ssh/outgoing/$key_name" "$username" "$user_uid" "$user_gid" "600"
            fi
        done
    fi
    
    # Setup SSH config and known_hosts
    if [ -f "$ssh_dir/config" ]; then
        log "Installing SSH config file"
        copy_to_users "$ssh_dir/config" ".ssh/config" "$username" "$user_uid" "$user_gid" "644"
    fi
    
    if [ -f "$ssh_dir/known_hosts" ]; then
        log "Installing known_hosts file"
        copy_to_users "$ssh_dir/known_hosts" ".ssh/known_hosts" "$username" "$user_uid" "$user_gid" "644"
    fi
    
    # Set final permissions and ownership
    log "Setting proper file permissions"
    chmod 700 /root/.ssh /root/.ssh/incoming /root/.ssh/outgoing 2>/dev/null || true
    chmod 700 "/home/${username}/.ssh" "/home/${username}/.ssh/incoming" "/home/${username}/.ssh/outgoing" 2>/dev/null || true
    chmod 644 /root/.ssh/authorized_keys 2>/dev/null || true
    chmod 644 "/home/${username}/.ssh/authorized_keys" 2>/dev/null || true
    chown -R "${user_uid}:${user_gid}" "/home/${username}/.ssh"
    
    # Display summary
    local auth_count=0
    local incoming_keys=0
    local outgoing_keys=0
    
    [ -f /root/.ssh/authorized_keys ] && auth_count=$(wc -l < /root/.ssh/authorized_keys)
    incoming_keys=$(find /root/.ssh/incoming -type f 2>/dev/null | wc -l)
    outgoing_keys=$(find /root/.ssh/outgoing -type f 2>/dev/null | wc -l)
    
    log "SSH setup completed - Auth keys: $auth_count | Incoming: $incoming_keys | Outgoing: $outgoing_keys"
}

# Function to configure SSH daemon
configure_sshd() {
    local ssh_port="$1"
    local username="$2"
    
    log "Configuring SSH daemon with security best practices"
    
    cat >> /etc/ssh/sshd_config << EOF

# Custom SSH configuration
Port ${ssh_port}
PasswordAuthentication yes
PubkeyAuthentication yes
PermitRootLogin yes
AllowUsers ${username} root
MaxAuthTries 5
ClientAliveInterval 300
ClientAliveCountMax 2
UsePAM no
EOF
}

# Function to create SSH startup script
create_startup_script() {
    local ssh_port="$1"
    
    log "Creating SSH daemon startup script"
    
    cat > /usr/local/bin/start-sshd << EOF
#!/bin/bash
echo "Starting SSH daemon on port ${ssh_port}..."
exec /usr/sbin/sshd -D -p ${ssh_port}
EOF
    
    chmod +x /usr/local/bin/start-sshd
}

# Main execution
main() {
    local ssh_dir="${1:-/tmp/.ssh}"  # Default to /tmp/.ssh if no parameter provided
    local username="${USERNAME:-dev}"
    local user_uid="${USER_UID:-1000}"
    local user_gid="${USER_GID:-1000}"
    local ssh_port="${SSH_PORT:-22}"
    
    log "Installing and configuring SSH server"
    
    # Install OpenSSH server
    dnf -y install --setopt=install_weak_deps=False --nodocs openssh-server
    
    # Generate SSH host keys manually for better reliability
    mkdir -p /etc/ssh
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N "" -q
    ssh-keygen -t ecdsa -b 256 -f /etc/ssh/ssh_host_ecdsa_key -N "" -q
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" -q
    chmod 600 /etc/ssh/ssh_host_*_key
    chmod 644 /etc/ssh/ssh_host_*_key.pub
    
    # Create SSH directories with proper permissions
    mkdir -p /root/.ssh "/home/${username}/.ssh"
    chmod 700 /root/.ssh "/home/${username}/.ssh"
    chown "${user_uid}:${user_gid}" "/home/${username}/.ssh"
    
    # Setup SSH keys if available
    setup_ssh_keys "$ssh_dir" "$username" "$user_uid" "$user_gid"
    
    # Configure SSH daemon
    configure_sshd "$ssh_port" "$username"
    
    # Create startup script
    create_startup_script "$ssh_port"
    
    # Clean up temp ssh directory
    # if [ -d "$ssh_dir" ]; then
    #   log "Cleaning up temporary SSH directory: $ssh_dir"
    #   rm -rf "$ssh_dir"
    # fi
    
    log "SSH server setup completed successfully"
}

# Run main function
main "$@"
