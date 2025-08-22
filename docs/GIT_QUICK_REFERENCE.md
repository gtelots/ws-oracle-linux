# Git Configuration Quick Reference

> **Quick reference for Oracle Linux 9 development container Git configuration**

## 🚀 Essential Commands

### Initial Setup
```bash
# Set up Git configuration for the team
scripts/setup-git-config.sh

# Validate configuration
scripts/test-git-config.sh

# Run security audit
scripts/security-audit.sh
```

### Daily Workflow
```bash
# Check file attributes
git check-attr -a filename

# Check if file would be ignored
git check-ignore -v filename

# View line endings
git ls-files --eol filename

# Normalize line endings
git add --renormalize .
```

## 🔧 Troubleshooting

### Line Ending Issues
```bash
# Problem: Mixed line endings
git ls-files --eol | grep -v "i/lf"

# Solution: Normalize
git add --renormalize .
git commit -m "Normalize line endings"
```

### Binary File Issues
```bash
# Problem: Binary file showing in diff
git check-attr binary filename

# Solution: Add to .gitattributes
echo "filename binary" >> .gitattributes
```

### Performance Issues
```bash
# Problem: Repository too large
git count-objects -vH

# Solution: Clean up
git gc --prune=now --aggressive
```

## 🔐 Security Checklist

### Before Commit
- [ ] No secrets in files: `git diff --cached | grep -i password`
- [ ] Security files are binary: `git check-attr binary *.key`
- [ ] Environment files ignored: `git check-ignore .env.local`
- [ ] Large files use Git LFS: `git lfs ls-files`

### Weekly Audit
- [ ] Run security scan: `scripts/security-audit.sh`
- [ ] Check repository size: `du -sh .git`
- [ ] Review ignored files: `git status --ignored`
- [ ] Validate team compliance: `scripts/validate-team-config.sh`

## 📋 File Type Reference

### Text Files (LF line endings)
```
*.sh *.py *.js *.go *.rs *.md
Dockerfile* *.yml *.yaml *.json
*.conf *.cfg *.env
```

### Binary Files
```
*.key *.pem *.p12 *.crt *.der
*.png *.jpg *.zip *.tar.gz
*.exe *.dll *.so *.rpm
```

### Ignored Files
```
node_modules/ __pycache__/ .vscode/
*.log *.tmp .env.local
build/ dist/ target/
```

## 🎯 Common Patterns

### Adding New File Types
```bash
# Text file with LF endings
echo "*.newext text eol=lf" >> .gitattributes

# Binary file
echo "*.binext binary" >> .gitattributes

# Ignored file
echo "*.ignore" >> .gitignore
```

### Security Files
```bash
# Always binary
echo "*.secret binary" >> .gitattributes

# Always ignored
echo "*.secret" >> .gitignore

# Export ignore (not in releases)
echo "*.secret export-ignore" >> .gitattributes
```

## 🚨 Emergency Procedures

### Accidental Secret Commit
```bash
# Remove from history (DANGEROUS)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch secret-file' \
  --prune-empty --tag-name-filter cat -- --all

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

### Repository Corruption
```bash
# Check integrity
git fsck --full --strict

# Recover from backup
git clone --mirror backup-url recovered.git
```

## 📊 Monitoring

### Daily Checks
```bash
# Repository health
git status
git fsck --no-full

# Performance
du -sh .git
git count-objects
```

### Weekly Reviews
```bash
# Run full audit
scripts/git-config-audit.sh

# Performance benchmark
scripts/benchmark-git-performance.sh

# Security scan
scripts/security-audit.sh
```

## 🔗 Resources

- **Full Guide**: `docs/GIT_BEST_PRACTICES.md`
- **Training**: `docs/GIT_TRAINING.md`
- **Custom Patterns**: `docs/CUSTOM_GIT_PATTERNS.md`
- **Workflow**: `docs/GIT_WORKFLOW.md`

## 📞 Support

### Common Issues
1. **Line endings**: Check `docs/GIT_BEST_PRACTICES.md#troubleshooting`
2. **Binary files**: See binary file detection section
3. **Performance**: Review repository optimization guide
4. **Security**: Contact security team for sensitive files

### Team Contacts
- **Git Configuration**: Development Team Lead
- **Security Issues**: Security Team
- **Performance**: DevOps Team
- **Training**: Technical Documentation Team

---

*Keep this reference handy for daily Git operations in Oracle Linux 9 development environments.*
