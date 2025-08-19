#!/bin/bash

# =============================================================================
# Install Ansible with Essential Roles and Collections
# =============================================================================

set -euo pipefail

# Check if Ansible installation is enabled
if [ "${INSTALL_ANSIBLE:-0}" != "1" ] || [ "${INSTALL_PYTHON:-0}" != "1" ]; then
    echo "==> Skipping Ansible installation"
    exit 0
fi

echo "==> Installing Ansible globally with essential collections and roles..."

# Install Ansible core packages globally
python3.11 -m pip install --no-cache-dir \
    ansible \
    ansible-lint \
    ansible-core \
    jmespath \
    netaddr \
    passlib

# Create global Ansible configuration directory
mkdir -p /etc/ansible/roles
mkdir -p /etc/ansible/collections
mkdir -p /etc/ansible/playbooks
mkdir -p /etc/ansible/inventories

# Create Ansible configuration file
cat > /etc/ansible/ansible.cfg << 'EOF'
[defaults]
host_key_checking = False
retry_files_enabled = False
inventory = /etc/ansible/inventories/hosts
roles_path = /etc/ansible/roles:/usr/share/ansible/roles
collections_path = /etc/ansible/collections:/usr/share/ansible/collections
library = /usr/share/ansible/plugins/modules
module_utils = /usr/share/ansible/plugins/module_utils
action_plugins = /usr/share/ansible/plugins/action
callback_plugins = /usr/share/ansible/plugins/callback
connection_plugins = /usr/share/ansible/plugins/connection
filter_plugins = /usr/share/ansible/plugins/filter
vars_plugins = /usr/share/ansible/plugins/vars
strategy_plugins = /usr/share/ansible/plugins/strategy
stdout_callback = default
gather_facts = smart
fact_caching = memory
pipelining = True
timeout = 30

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[ssh_connection]
ssh_args = -C -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
EOF

# Install essential Ansible collections globally
echo "==> Installing essential Ansible collections..."
ansible-galaxy collection install \
    community.general \
    community.crypto \
    community.docker \
    community.mysql \
    community.postgresql \
    community.mongodb \
    community.network \
    ansible.posix \
    containers.podman \
    kubernetes.core \
    --force

# Install common Ansible roles globally
echo "==> Installing essential Ansible roles..."
ansible-galaxy role install \
    geerlingguy.docker \
    geerlingguy.nginx \
    geerlingguy.mysql \
    geerlingguy.postgresql \
    geerlingguy.redis \
    geerlingguy.nodejs \
    geerlingguy.php \
    geerlingguy.apache \
    geerlingguy.firewall \
    geerlingguy.security \
    --force

# Create sample inventory file
cat > /etc/ansible/inventories/hosts << 'EOF'
# Ansible Inventory File
# ======================
# Define your servers and groups here

[local]
localhost ansible_connection=local

[webservers]
# web1.example.com
# web2.example.com

[databases]
# db1.example.com
# db2.example.com

[all:vars]
# ansible_user=your_username
# ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF

# Create sample playbook
cat > /etc/ansible/playbooks/example.yml << 'EOF'
---
# Example Ansible Playbook
# ========================
- name: Example playbook
  hosts: local
  gather_facts: yes
  become: yes
  
  tasks:
    - name: Ensure basic packages are installed
      package:
        name:
          - curl
          - wget
          - git
        state: present
    
    - name: Display system information
      debug:
        msg: "Running on {{ ansible_distribution }} {{ ansible_distribution_version }}"
EOF

# Set proper permissions
chown -R root:root /etc/ansible
chmod -R 755 /etc/ansible
chmod 644 /etc/ansible/ansible.cfg
chmod 644 /etc/ansible/inventories/hosts
chmod 644 /etc/ansible/playbooks/example.yml

# Create symlink for global access
ln -sf /usr/local/bin/ansible /usr/bin/ansible 2>/dev/null || true
ln -sf /usr/local/bin/ansible-playbook /usr/bin/ansible-playbook 2>/dev/null || true
ln -sf /usr/local/bin/ansible-galaxy /usr/bin/ansible-galaxy 2>/dev/null || true
ln -sf /usr/local/bin/ansible-lint /usr/bin/ansible-lint 2>/dev/null || true

echo "==> Ansible installation completed successfully!"
echo "    Configuration: /etc/ansible/ansible.cfg"
echo "    Inventory: /etc/ansible/inventories/hosts"
echo "    Roles: /etc/ansible/roles"
echo "    Collections: /etc/ansible/collections"
echo "    Example playbook: /etc/ansible/playbooks/example.yml"

# Test Ansible installation
echo "==> Testing Ansible installation..."
ansible --version
ansible-galaxy collection list | head -10
ansible localhost -m ping
