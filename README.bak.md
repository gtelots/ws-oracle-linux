# 🐧 Oracle Linux 9 Development Container

## Upgrade

- Dùng đường dẫn khác, đừng bỏ trong tmp - /tmp/install-{tool}.lock
- Bỏ common function vào dotfiles, giúp sử dụng load toàn cục
- Cài đặt yazi
- Build testing and validation
- Performance optimization
- Comprehensive documentation
- Regular security updates
- Test all modular script installations
- Complete Dockerfile restructuring validation
- Follow https://github.com/bitnami/containers

## 🗺️ **Roadmap & Development Plan**

### Phase 1: Core Infrastructure ✅
- [x] Oracle Linux 9 base setup
- [x] Essential development tools
- [x] Docker-in-Docker implementation
- [x] Modular script architecture
- [x] Lock file system for installations

### Phase 2: Developer Experience (In Progress)
- [x] Individual tool installers
- [x] Professional dotfiles integration
- [x] Shell environment optimization
- [ ] Build testing and validation
- [ ] Performance optimization

### Phase 3: Advanced Features (Planned)
- [ ] Multi-architecture support (ARM64/AMD64)
- [ ] Custom development profiles
- [ ] IDE integrations
- [ ] Database connection management
- [ ] CI/CD pipeline integration

### Phase 4: Documentation & Maintenance (Ongoing)
- [ ] Comprehensive documentation
- [ ] Video tutorials
- [ ] Community contributions
- [ ] Regular security updates

## 📝 **TODOs**

### High Priority
- [ ] Complete Dockerfile restructuring validation
- [ ] Test all modular script installations
- [ ] Verify Docker-in-Docker functionality
- [ ] Performance benchmarking

### Medium Priority
- [ ] Add health checks for services
- [ ] Implement backup/restore scripts
- [ ] Create development profiles
- [ ] Add more database tools

### Low Priority
- [ ] GUI application support
- [ ] Custom theme development
- [ ] Plugin ecosystem
- [ ] Mobile development tools

## 📖 **Documentation**

- [Detailed Setup Guide](docs/DETAILED.md)
- [Configuration Reference](docs/CONFIGURATION.md)
- [Development Workflow](docs/WORKFLOW.md)
- [SSH Key Management](.ssh/README.md)

## Repos

- https://github.com/gtelots/ws-oracle-linux/blob/1.0.0/Dockerfile
- https://github.com/codeopshq/dotfiles
- https://github.com/wintermi/zsh-starship/blob/main/theme/starship.toml
- https://dev.to/girordo/a-hands-on-guide-to-setting-up-zsh-oh-my-zsh-asdf-and-spaceship-prompt-with-zinit-for-your-development-environment-91n
