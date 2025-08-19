# SSH Keys Directory
# 
# Place your SSH keys here for container access:
#
# incoming/     - Public keys for accessing this container
# outgoing/     - Private keys for connecting to other servers
#
# Example structure:
# .ssh/
# ├── incoming/
# │   ├── id_rsa.pub      # Your public key
# │   └── authorized_keys # Additional authorized keys
# └── outgoing/
#     ├── id_rsa         # Private key for external connections
#     └── id_rsa.pub     # Corresponding public key
#
# Note: This directory should be copied to .ssh/ before building
