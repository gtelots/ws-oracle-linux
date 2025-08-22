# 🐧 Oracle Linux 9 Development Container

A comprehensive, production-ready development environment built on Oracle Linux 9 with modern tooling, beautiful UI, and optimized architecture.

## ✨ **Key Features**

## 🚀 **Quick Start**

```bash
# Clone the repository
git clone https://github.com/gtelots/ws-oracle-linux.git
cd ws-oracle-linux

# Set up SSH keys (optional)
cp -r .ssh-example .ssh
# Add your public keys to .ssh/incoming/

# Start the development environment
task up

# Access the container
task shell
# or via SSH (password: dev)
ssh -p 2222 dev@localhost
```

## 📁 **Project Structure**

## 🛠️ **Available Commands**

## 🐳 **Docker-in-Docker Management**

## 🔧 **Installed Tools**

## ⚙️ **Configuration**

All tools can be enabled/disabled via environment variables in `.env`:

```bash
# Core tools
INSTALL_K8S=1
INSTALL_TERRAFORM=0
```

## 🗺️ **Roadmap & Development Plan**

## 📝 **TODOs**

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ for developers who want a powerful, customizable development environment.**