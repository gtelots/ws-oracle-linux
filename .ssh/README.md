# SSH Keys Management - Complete Guide

Organized SSH key management system with clear directory structure for easy management and distinction between incoming and outgoing access.

## 📁 Directory Structure:

```
~/.ssh/
├── incoming/              # 🔑 Keys for accessing INTO workspace from outside
│   ├── workspace.pub      # Public key → will be added to authorized_keys
│   ├── workspace          # Corresponding private key
│   ├── laptop.pub         # Public key from laptop
│   ├── laptop             # Private key from laptop
│   └── team_access.pub    # Public key for team access
│
├── outgoing/              # 🚀 Keys for accessing OUT to other servers
│   ├── prod_server        # Private key for production server
│   ├── staging_db         # Private key for staging database
│   ├── github_deploy      # Private key for GitHub deployment
│   ├── aws_ec2            # Private key for AWS EC2
│   └── k8s_cluster        # Private key for Kubernetes cluster
│
├── authorized_keys        # Generated from incoming/*.pub files
├── config                 # SSH client configuration
└── known_hosts           # Known hosts file
```

## 🔧 How It Works:

### 📥 Incoming Directory (Access INTO workspace):
- **Purpose**: Contains keys to allow access **INTO** workspace from outside
- **Public keys (.pub)**: Will be added to `authorized_keys` for incoming connections
- **Private keys**: Corresponding private keys stored for convenience
- **Usage**: Place public keys here to allow SSH access into workspace
- **Process**: Script automatically adds all .pub files to authorized_keys
- **Permissions**: Private keys set to 600, public keys to 644
- **Users**: Keys copied to both root and dev user

### 📤 Outgoing  Directory (Access OUT to other servers):
- **Purpose**: Contains keys to access **OUT** to other servers from workspace
- **Private keys only**: Only private keys needed, no .pub files required
- **Permissions**: All keys automatically set to 600
- **Usage**: Place private keys here to connect to external servers
- **Naming**: Name keys by server/service for easy identification
- **SSH Config**: Use with SSH config to create shortcuts

## 📋 Detailed Usage Guide:

### 📥 Setting up incoming access (allow access INTO workspace):

1. **Place public keys in incoming/ directory:**
```bash
incoming/
├── my_laptop.pub          # Public key from your laptop
├── team_member.pub        # Public key from team member
├── ci_server.pub          # Public key from CI server
├── workspace.pub          # Main workspace access key
└── backup_access.pub      # Backup access key
```

2. **Script will automatically:**
- Add all .pub files to `authorized_keys`
- Copy keys to both root and dev user
- Set correct permissions (private: 600, public: 644)
- Create authorized_keys with permission 644

3. **Important notes:**
- Public keys (.pub) will be added to authorized_keys
- Corresponding private keys can be placed in same directory for convenience
- Keys will be copied to both root and dev user
- Use descriptive names for easy identification

### 📤 Setting up outgoing access (connect OUT to other servers):

1. **Place private keys in outgoing/ directory:**
```bash
outgoing/
├── prod_server            # Private key for production server
├── staging_db             # Private key for staging database
├── github_deploy          # Private key for GitHub deployment
├── aws_ec2                # Private key for AWS EC2
├── k8s_cluster            # Private key for Kubernetes cluster
├── docker_registry        # Private key for private Docker registry
└── gcp_compute            # Private key for Google Cloud Compute
```

2. **Create SSH config for easy access:**
```bash
# File: ~/.ssh/config
Host prod
    HostName prod.example.com
    User ubuntu
    IdentityFile ~/.ssh/outgoing/prod_server

Host staging-db
    HostName staging-db.example.com
    User postgres
    IdentityFile ~/.ssh/outgoing/staging_db

Host github-deploy
    HostName github.com
    User git
    IdentityFile ~/.ssh/outgoing/github_deploy

Host aws-web
    HostName ec2-xxx.amazonaws.com
    User ec2-user
    IdentityFile ~/.ssh/outgoing/aws_ec2

Host k8s
    HostName k8s-cluster.example.com
    User admin
    IdentityFile ~/.ssh/outgoing/k8s_cluster
```

3. **Important notes:**
- Only place private keys - no .pub files needed
- Name keys by server/service for easy identification
- Use with SSH config to create shortcuts
- All keys automatically set to permission 600

## 🚀 Usage Examples:

### After container setup:

```bash
# Connect to external servers using shortcuts
ssh prod                    # Connect to production server
ssh staging-db              # Connect to staging database
ssh aws-web                 # Connect to AWS instance

# Use with Git
git clone git@github-deploy:user/repo.git

# Direct SSH with key
ssh -i ~/.ssh/outgoing/prod_server ubuntu@prod.example.com
```

### Access workspace from outside:

```bash
# From your laptop (if laptop.pub is in incoming/)
ssh dev@workspace-container-ip

# From CI server (if ci_server.pub is in incoming/)
ssh root@workspace-container-ip
```

## 🔄 Backward Compatibility:

Script still supports legacy flat structure with naming convention:
```
.ssh/
├── id_ed25519_workspace.pub    # [Legacy] → authorized_keys + incoming/
├── id_ed25519_workspace        # [Legacy] → incoming/
├── prod_server                 # [Legacy] → outgoing/
└── config                      # [Legacy] config file
```

**Legacy files will be automatically organized:**
- Files with `workspace`, `access`, or `incoming` in name → `incoming/` directory
- Other private keys → `outgoing/` directory
- Public keys (.pub) → Added to `authorized_keys` + `incoming/` directory

## 🔒 Security Notes:

1. **Incoming keys**: Both public and private keys stored in `incoming/`
2. **Outgoing keys**: Only private keys stored in `outgoing/`
3. **Permissions**:
   - Private keys: 600 (owner read/write only)
   - Public keys: 644 (readable by all)
   - authorized_keys: 644
4. **Organization**: Keys organized in directories for easy management
5. **User access**: Keys copied to both root and dev user

## 📋 Example File Structure:

### Sample incoming/ structure:
```
incoming/
├── workspace.pub          # Main workspace access key
├── workspace              # Corresponding private key
├── developer_laptop.pub   # Developer's laptop key
├── ci_server.pub          # CI/CD server key
└── backup_access.pub      # Backup access key
```

### Sample outgoing/ structure:
```
outgoing/
├── prod_web               # Production web server
├── prod_db                # Production database
├── staging_app            # Staging application server
├── github_deploy          # GitHub deployment key
├── gitlab_ci              # GitLab CI key
├── aws_ec2_prod           # AWS EC2 production
├── gcp_compute            # Google Cloud Compute
└── k8s_cluster_admin      # Kubernetes cluster admin
```

This organized structure makes SSH key management easier and more secure!

---

## 🎯 Quick Summary:

- **incoming/**: Place public keys (.pub) to allow access INTO workspace
- **outgoing/**: Place private keys to access OUT to other servers
- **Auto-processing**: Script handles permissions, authorized_keys, and user copying
- **SSH config**: Create shortcuts for easy connections
- **Security**: Permissions set automatically, keys organized clearly