# SSH Configuration for Oracle Linux 9 Development Container

This directory contains SSH configuration and key management for the development container, following enterprise security best practices.

## 🔐 Security Overview

The SSH configuration implements security hardening based on:
- **Bitnami Security Patterns**: Non-root execution, minimal privileges
- **Enterprise Standards**: Strong encryption, key-based authentication
- **Modern Cryptography**: Ed25519 keys, secure algorithms only

## 📁 Directory Structure

```
.ssh/
├── config              # SSH client configuration
├── README.md          # This documentation
├── authorized_keys    # Public keys for incoming connections (if needed)
├── known_hosts        # Verified host keys
└── keys/              # Private key storage (create as needed)
    ├── id_ed25519     # Default Ed25519 private key
    ├── id_ed25519.pub # Default Ed25519 public key
    └── ...            # Additional keys for different services
```

## 🚀 Quick Setup

### 1. Generate SSH Keys

```bash
# Generate default Ed25519 key (recommended)
ssh-keygen -t ed25519 -C "developer@oracle-linux-dev" -f ~/.ssh/id_ed25519

# Generate service-specific keys
ssh-keygen -t ed25519 -C "github-access" -f ~/.ssh/id_ed25519_github
ssh-keygen -t ed25519 -C "gitlab-access" -f ~/.ssh/id_ed25519_gitlab
```

### 2. Set Proper Permissions

```bash
# Set directory permissions
chmod 700 ~/.ssh

# Set file permissions
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519*
chmod 644 ~/.ssh/id_ed25519*.pub
chmod 644 ~/.ssh/authorized_keys  # if exists
chmod 644 ~/.ssh/known_hosts      # if exists
```

### 3. Add Keys to SSH Agent

```bash
# Start SSH agent (if not running)
eval "$(ssh-agent -s)"

# Add keys to agent
ssh-add ~/.ssh/id_ed25519
ssh-add ~/.ssh/id_ed25519_github
ssh-add ~/.ssh/id_ed25519_gitlab
```

## 🔧 Configuration Features

### Security Hardening
- **Protocol 2 Only**: Modern SSH protocol
- **Key-Based Auth**: Password authentication disabled
- **Strong Algorithms**: ChaCha20-Poly1305, Ed25519, SHA-256
- **Host Verification**: Strict host key checking
- **Connection Limits**: Timeouts and keep-alive settings

### Development Convenience
- **Service-Specific Keys**: Different keys for different services
- **Port Forwarding**: Pre-configured for common development ports
- **Jump Hosts**: Bastion server support for corporate environments
- **Auto-Completion**: Works with SSH tab completion

### Enterprise Features
- **Cloud Provider Support**: AWS, GCP, Azure, OCI configurations
- **Corporate Networks**: VPN and bastion host configurations
- **Compliance Ready**: High-security host configurations
- **Audit Logging**: Configurable logging levels

## 🌐 Predefined Host Configurations

### Development Hosts
- `dev-server`: Local development server with port forwarding
- `docker-host`: Docker host access from container

### Git Repositories
- `github.com`: GitHub with dedicated key
- `gitlab.com`: GitLab with dedicated key
- `bitbucket.org`: Bitbucket with dedicated key

### Cloud Providers
- `oci-*`: Oracle Cloud Infrastructure
- `aws-*`: Amazon Web Services
- `gcp-*`: Google Cloud Platform
- `azure-*`: Microsoft Azure

### Enterprise
- `bastion`: Jump host for corporate networks
- `internal-*`: Internal servers via bastion
- `secure-*`: High-security environments

## 🔑 Key Management Best Practices

### Key Types and Usage
1. **Ed25519** (Recommended): Fast, secure, small key size
2. **ECDSA**: Good alternative, widely supported
3. **RSA 4096**: Legacy support, larger key size

### Key Organization
```bash
# Service-specific naming convention
id_ed25519_github      # GitHub access
id_ed25519_gitlab      # GitLab access
id_ed25519_aws         # AWS EC2 access
id_ed25519_corporate   # Corporate systems
```

### Key Rotation
- Rotate keys every 12-24 months
- Use different keys for different environments
- Keep backup of public keys
- Document key usage and expiration

## 🛡️ Security Checklist

- [ ] SSH directory permissions set to 700
- [ ] Private keys permissions set to 600
- [ ] Public keys permissions set to 644
- [ ] Config file permissions set to 600
- [ ] Password authentication disabled
- [ ] Strong algorithms configured
- [ ] Host key verification enabled
- [ ] SSH agent configured with timeout
- [ ] Keys added to appropriate services
- [ ] Backup of public keys created

## 🔍 Troubleshooting

### Connection Issues
```bash
# Test SSH connection with verbose output
ssh -vvv username@hostname

# Test specific key
ssh -i ~/.ssh/id_ed25519 username@hostname

# Check SSH agent
ssh-add -l
```

### Permission Problems
```bash
# Fix SSH directory permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub
```

### Key Problems
```bash
# Regenerate host keys if needed
ssh-keygen -R hostname

# Test key authentication
ssh-keygen -t ed25519 -f test_key
ssh-copy-id -i test_key.pub username@hostname
```

## 📚 Additional Resources

- [SSH Security Best Practices](https://infosec.mozilla.org/guidelines/openssh)
- [Ed25519 Key Benefits](https://blog.g3rt.nl/upgrade-your-ssh-keys.html)
- [SSH Hardening Guide](https://stribika.github.io/2015/01/04/secure-secure-shell.html)
- [Oracle Linux Security Guide](https://docs.oracle.com/en/operating-systems/oracle-linux/9/security/)

## 🚨 Security Notes

⚠️ **Never commit private keys to version control**
⚠️ **Use different keys for different environments**
⚠️ **Regularly audit and rotate SSH keys**
⚠️ **Monitor SSH access logs**
⚠️ **Use SSH agent with timeout for key management**

---

*This SSH configuration is part of the Oracle Linux 9 Development Container project, designed for enterprise-grade security and developer productivity.*
