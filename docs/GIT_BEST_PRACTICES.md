# Git Configuration Best Practices for Oracle Linux 9 Development Container

This guide provides comprehensive best practices for maintaining and optimizing Git configuration in enterprise Oracle Linux development environments.

## 🔄 Maintenance and Updates

### Regular Review Schedule

**Monthly Reviews:**
```bash
# Create a maintenance script
cat > scripts/git-config-audit.sh << 'EOF'
#!/bin/bash
echo "=== Git Configuration Audit $(date) ==="
echo "Repository size: $(du -sh .git | cut -f1)"
echo "Total files tracked: $(git ls-files | wc -l)"
echo "Binary files: $(git ls-files | xargs git check-attr binary | grep -c 'binary: set')"
echo "Ignored files: $(git status --ignored --porcelain | wc -l)"
echo "Large files (>1MB): $(find . -type f -size +1M -not -path './.git/*' | wc -l)"
EOF
chmod +x scripts/git-config-audit.sh
```

**Quarterly Pattern Updates:**
```bash
# Update patterns based on new technologies
git log --name-only --since="3 months ago" | grep -E '\.[a-z]+$' | sort | uniq -c | sort -nr | head -20
```

### Version Control for Git Configuration

**Track Configuration Changes:**
```bash
# Create a dedicated branch for Git configuration updates
git checkout -b git-config-update
# Make changes to .gitattributes and .gitignore
git add .gitattributes .gitignore
git commit -m "Update Git configuration: Add support for new file types"
# Create PR for team review
```

**Configuration Templates:**
```bash
# Maintain templates for different project types
mkdir -p .git-templates/
cp .gitattributes .git-templates/oracle-linux-container.gitattributes
cp .gitignore .git-templates/oracle-linux-container.gitignore
```

### Automated Updates

**Pre-commit Hook for Validation:**
```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Validate Git configuration before commits
if ! git check-attr --all .gitattributes > /dev/null 2>&1; then
    echo "Error: Invalid .gitattributes syntax"
    exit 1
fi

# Check for common security patterns
if git diff --cached --name-only | grep -E '\.(key|pem|p12)$'; then
    echo "Warning: Security files detected in commit"
    echo "Ensure these files are properly configured as binary"
fi
EOF
chmod +x .git/hooks/pre-commit
```

## 👥 Team Collaboration

### Standardization Across Team

**Global Git Configuration Setup:**
```bash
# Create team setup script
cat > scripts/setup-git-config.sh << 'EOF'
#!/bin/bash
# Standardize Git configuration across team
git config --global core.autocrlf false
git config --global core.eol lf
git config --global core.filemode false
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.default simple

# Set up Git LFS if not already configured
if ! git lfs version > /dev/null 2>&1; then
    echo "Please install Git LFS: https://git-lfs.github.io/"
    exit 1
fi
git lfs install
EOF
```

**Onboarding Checklist:**
```markdown
## New Team Member Git Setup
- [ ] Run `scripts/setup-git-config.sh`
- [ ] Verify line ending configuration: `git config --list | grep -E "(autocrlf|eol)"`
- [ ] Test with sample file: `echo "test" > test.sh && git add test.sh && git ls-files --eol test.sh`
- [ ] Install recommended tools: `task install-dev-tools`
- [ ] Review Git configuration documentation
```

### Configuration Synchronization

**Shared Configuration Repository:**
```bash
# Create shared Git configuration repository
git submodule add https://github.com/company/git-config-oracle-linux .git-config
ln -sf .git-config/.gitattributes .gitattributes
ln -sf .git-config/.gitignore .gitignore
```

**Validation Scripts:**
```bash
# Team configuration validation
cat > scripts/validate-team-config.sh << 'EOF'
#!/bin/bash
EXPECTED_AUTOCRLF="false"
EXPECTED_EOL="lf"

ACTUAL_AUTOCRLF=$(git config core.autocrlf)
ACTUAL_EOL=$(git config core.eol)

if [[ "$ACTUAL_AUTOCRLF" != "$EXPECTED_AUTOCRLF" ]]; then
    echo "❌ core.autocrlf should be $EXPECTED_AUTOCRLF, got $ACTUAL_AUTOCRLF"
    exit 1
fi

if [[ "$ACTUAL_EOL" != "$EXPECTED_EOL" ]]; then
    echo "❌ core.eol should be $EXPECTED_EOL, got $ACTUAL_EOL"
    exit 1
fi

echo "✅ Git configuration is correct"
EOF
```

## 🔐 Security Considerations

### Sensitive File Auditing

**Security Scan Script:**
```bash
cat > scripts/security-audit.sh << 'EOF'
#!/bin/bash
echo "=== Security Audit for Git Repository ==="

# Check for accidentally committed secrets
echo "Checking for potential secrets..."
git log --all --full-history -- "*.key" "*.pem" "*.p12" "*.env.production" || echo "No security files in history"

# Verify binary attribute for security files
echo "Verifying security file attributes..."
find . -name "*.key" -o -name "*.pem" -o -name "*.p12" | while read file; do
    if [[ -f "$file" ]]; then
        attr=$(git check-attr binary "$file" | cut -d: -f3)
        if [[ "$attr" != " set" ]]; then
            echo "⚠️  $file should be marked as binary"
        fi
    fi
done

# Check for ignored files that might contain secrets
echo "Checking ignored files for secrets..."
git status --ignored --porcelain | grep -E '\.(env|key|pem|secret)' || echo "No suspicious ignored files"
EOF
chmod +x scripts/security-audit.sh
```

**Automated Secret Detection:**
```bash
# Install and configure git-secrets
git secrets --register-aws
git secrets --install
git secrets --scan

# Add custom patterns for Oracle Linux environments
git secrets --add 'oracle_[a-zA-Z0-9_]*_password'
git secrets --add 'ORACLE_[A-Z_]*_KEY'
```

### Access Control Integration

**Enterprise LDAP Integration:**
```bash
# Configure Git with enterprise identity
git config --global user.name "$(ldapsearch -x -LLL uid=$USER cn | grep cn: | cut -d' ' -f2-)"
git config --global user.email "$USER@company.com"
```

## ⚡ Performance Optimization

### Repository Size Management

**Large File Detection:**
```bash
cat > scripts/find-large-files.sh << 'EOF'
#!/bin/bash
echo "Files larger than 1MB not in Git LFS:"
git ls-files | xargs ls -la | awk '$5 > 1048576 {print $5/1048576 "MB", $9}' | sort -nr

echo "Largest objects in Git history:"
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
    awk '/^blob/ {print substr($0,6)}' | sort --numeric-sort --key=2 | tail -20
EOF
```

**Git LFS Migration:**
```bash
# Migrate large files to Git LFS
git lfs migrate import --include="*.iso,*.img,*.vmdk" --everything
git lfs migrate info --everything
```

### Optimization Strategies

**Repository Maintenance:**
```bash
# Weekly maintenance script
cat > scripts/git-maintenance.sh << 'EOF'
#!/bin/bash
echo "Running Git maintenance..."
git gc --aggressive --prune=now
git repack -ad
git prune
echo "Repository optimized: $(du -sh .git | cut -f1)"
EOF
```

**Shallow Clone Configuration:**
```bash
# For CI/CD environments
git config --global clone.defaultRemoteName origin
git config --global fetch.prune true
git config --global fetch.prunetags true
```

## 🏢 Enterprise Integration

### CI/CD Pipeline Integration

**GitLab CI Configuration:**
```yaml
# .gitlab-ci.yml
variables:
  GIT_STRATEGY: clone
  GIT_CLEAN_FLAGS: -ffdx
  GIT_SUBMODULE_STRATEGY: recursive

before_script:
  - git config --global core.autocrlf false
  - git config --global core.eol lf
  - scripts/validate-team-config.sh

git-config-validation:
  stage: validate
  script:
    - scripts/security-audit.sh
    - scripts/git-config-audit.sh
  artifacts:
    reports:
      junit: git-audit-report.xml
```

**GitHub Actions Configuration:**
```yaml
# .github/workflows/git-validation.yml
name: Git Configuration Validation
on: [push, pull_request]

jobs:
  validate-git-config:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - name: Validate Git Configuration
        run: |
          chmod +x scripts/*.sh
          scripts/validate-team-config.sh
          scripts/security-audit.sh
```

### Code Review Integration

**Pre-receive Hook:**
```bash
# Server-side validation
cat > hooks/pre-receive << 'EOF'
#!/bin/bash
while read oldrev newrev refname; do
    # Check for large files
    git diff --name-only $oldrev..$newrev | while read file; do
        size=$(git cat-file -s "$newrev:$file" 2>/dev/null || echo 0)
        if [[ $size -gt 10485760 ]]; then  # 10MB
            echo "Error: $file is larger than 10MB. Use Git LFS."
            exit 1
        fi
    done
done
EOF
```

### Compliance and Auditing

**Audit Trail Generation:**
```bash
cat > scripts/generate-audit-report.sh << 'EOF'
#!/bin/bash
REPORT_FILE="git-audit-$(date +%Y%m%d).json"
cat > $REPORT_FILE << EOJ
{
  "timestamp": "$(date -Iseconds)",
  "repository": "$(git remote get-url origin)",
  "branch": "$(git branch --show-current)",
  "commit": "$(git rev-parse HEAD)",
  "git_config": {
    "autocrlf": "$(git config core.autocrlf)",
    "eol": "$(git config core.eol)",
    "filemode": "$(git config core.filemode)"
  },
  "file_stats": {
    "total_files": $(git ls-files | wc -l),
    "binary_files": $(git ls-files | xargs git check-attr binary | grep -c 'binary: set'),
    "ignored_files": $(git status --ignored --porcelain | wc -l)
  },
  "security_check": "$(scripts/security-audit.sh > /dev/null 2>&1 && echo 'PASS' || echo 'FAIL')"
}
EOJ
echo "Audit report generated: $REPORT_FILE"
EOF
```

## 🔧 Troubleshooting

### Common Issues and Solutions

**Line Ending Problems:**
```bash
# Diagnose line ending issues
git ls-files --eol | grep -v "i/lf"

# Fix mixed line endings
git add --renormalize .
git status  # Review changes
git commit -m "Normalize line endings"
```

**Binary File Detection Issues:**
```bash
# Check if file is properly detected as binary
git check-attr binary filename
git show HEAD:filename | file -  # Should show "binary" for binary files

# Force binary treatment
echo "filename binary" >> .gitattributes
```

**Performance Issues:**
```bash
# Identify repository bloat
git count-objects -vH
git for-each-ref --format='%(refname:short) %(objectsize)' refs/heads | sort -k2 -nr

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

### Emergency Procedures

**Accidental Secret Commit:**
```bash
# Remove secret from history (use with caution)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/secret/file' \
  --prune-empty --tag-name-filter cat -- --all

# Alternative using BFG Repo-Cleaner
java -jar bfg.jar --delete-files secret-file.key
git reflog expire --expire=now --all && git gc --prune=now --aggressive
```

**Repository Corruption:**
```bash
# Verify repository integrity
git fsck --full --strict

# Recover from backup
git clone --mirror backup-url recovered-repo.git
cd recovered-repo.git
git push --mirror origin
```

## ✅ Validation and Testing

### Automated Testing Framework

**Git Configuration Test Suite:**
```bash
cat > scripts/test-git-config.sh << 'EOF'
#!/bin/bash
set -e

echo "=== Git Configuration Test Suite ==="

# Test 1: Line ending normalization
echo "Testing line ending normalization..."
echo -e "line1\r\nline2\r\n" > test-crlf.txt
git add test-crlf.txt
if git ls-files --eol test-crlf.txt | grep -q "i/crlf"; then
    echo "❌ CRLF line endings not normalized"
    exit 1
fi
echo "✅ Line ending normalization works"
rm test-crlf.txt

# Test 2: Binary file detection
echo "Testing binary file detection..."
echo -e "\x00\x01\x02\x03" > test-binary.bin
git add test-binary.bin
if ! git check-attr binary test-binary.bin | grep -q "binary: set"; then
    echo "❌ Binary file not detected"
    exit 1
fi
echo "✅ Binary file detection works"
rm test-binary.bin

# Test 3: Ignore patterns
echo "Testing ignore patterns..."
mkdir -p node_modules test-dir
touch node_modules/package.json test-dir/file.txt
if git check-ignore node_modules/package.json > /dev/null; then
    echo "✅ Ignore patterns work"
else
    echo "❌ Ignore patterns not working"
    exit 1
fi
rm -rf node_modules test-dir

# Test 4: Security file handling
echo "Testing security file handling..."
touch test.key
git add test.key
if git check-attr binary test.key | grep -q "binary: set"; then
    echo "✅ Security files handled as binary"
else
    echo "❌ Security files not handled as binary"
    exit 1
fi
rm test.key

echo "🎉 All tests passed!"
EOF
chmod +x scripts/test-git-config.sh
```

**Continuous Validation:**
```bash
# Add to CI/CD pipeline
cat > .github/workflows/git-config-test.yml << 'EOF'
name: Git Configuration Tests
on:
  push:
    paths:
      - '.gitattributes'
      - '.gitignore'
  pull_request:
    paths:
      - '.gitattributes'
      - '.gitignore'

jobs:
  test-git-config:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Test Git Configuration
        run: scripts/test-git-config.sh
      - name: Validate Syntax
        run: |
          git check-attr --all .gitattributes
          git status --ignored --porcelain > /dev/null
EOF
```

### Performance Testing

**Repository Performance Benchmarks:**
```bash
cat > scripts/benchmark-git-performance.sh << 'EOF'
#!/bin/bash
echo "=== Git Performance Benchmark ==="

# Benchmark 1: Clone performance
echo "Testing clone performance..."
time git clone --depth 1 . test-clone
rm -rf test-clone

# Benchmark 2: Status performance
echo "Testing status performance..."
time git status > /dev/null

# Benchmark 3: Add performance
echo "Testing add performance..."
find . -name "*.md" -exec touch {} \;
time git add .
git reset HEAD

# Benchmark 4: Diff performance
echo "Testing diff performance..."
time git diff HEAD~1 > /dev/null

echo "Benchmark complete"
EOF
```

### Integration Testing

**Multi-Platform Testing:**
```bash
# Docker-based testing for different platforms
cat > scripts/test-cross-platform.sh << 'EOF'
#!/bin/bash
platforms=("ubuntu:latest" "centos:8" "alpine:latest")

for platform in "${platforms[@]}"; do
    echo "Testing on $platform..."
    docker run --rm -v $(pwd):/workspace -w /workspace $platform sh -c "
        git config --global core.autocrlf false
        git config --global core.eol lf
        git status
        scripts/test-git-config.sh
    "
done
EOF
```

## 📚 Documentation

### Pattern Documentation

**Custom Pattern Registry:**
```bash
# Create documentation for custom patterns
cat > docs/CUSTOM_GIT_PATTERNS.md << 'EOF'
# Custom Git Patterns Documentation

## Custom .gitattributes Patterns

### Oracle Linux Specific
```gitattributes
*.repo text eol=lf          # YUM/DNF repository files
*.spec text eol=lf          # RPM spec files
*.ks text eol=lf            # Kickstart configuration
```

### Enterprise Security
```gitattributes
*.p12 binary                # PKCS#12 certificates
*.jks binary                # Java keystores
krb5.conf text eol=lf       # Kerberos configuration
```

## Custom .gitignore Patterns

### Development Environment
```gitignore
.oracle-dev/                # Oracle development tools
*.ora                       # Oracle configuration files
tnsnames.ora               # Oracle network configuration
```

### Container Specific
```gitignore
.container-*               # Container runtime files
docker-build/              # Docker build context
k8s-secrets/              # Kubernetes secrets
```

## Pattern Justification

| Pattern | Reason | Impact |
|---------|--------|--------|
| `*.key binary` | Prevents line ending corruption | Security |
| `node_modules/` | Large dependency directory | Performance |
| `.env.local` | Contains local secrets | Security |

## Change Log

- 2024-01-15: Added Oracle Linux specific patterns
- 2024-01-10: Enhanced security file handling
- 2024-01-05: Initial custom patterns
EOF
```

### Team Guidelines

**Git Workflow Documentation:**
```bash
cat > docs/GIT_WORKFLOW.md << 'EOF'
# Git Workflow Guidelines

## Branch Naming Convention
- `feature/JIRA-123-description`
- `bugfix/JIRA-456-description`
- `hotfix/JIRA-789-description`
- `release/v1.2.3`

## Commit Message Format
```
type(scope): subject

body

footer
```

Types: feat, fix, docs, style, refactor, test, chore

## Pre-commit Checklist
- [ ] Run `scripts/test-git-config.sh`
- [ ] Verify no secrets in commit: `git diff --cached | grep -i password`
- [ ] Check file sizes: `git diff --cached --stat`
- [ ] Validate commit message format

## Code Review Requirements
- All changes to `.gitattributes` and `.gitignore` require review
- Security-related changes require security team approval
- Performance impact assessment for large changes
EOF
```

### Training Materials

**Git Configuration Training:**
```bash
cat > docs/GIT_TRAINING.md << 'EOF'
# Git Configuration Training

## Learning Objectives
1. Understand Git attributes and ignore patterns
2. Implement security best practices
3. Optimize repository performance
4. Troubleshoot common issues

## Hands-on Exercises

### Exercise 1: Line Ending Normalization
1. Create a file with CRLF line endings
2. Add to Git and observe normalization
3. Verify with `git ls-files --eol`

### Exercise 2: Binary File Handling
1. Create a binary file (image, certificate)
2. Verify binary attribute detection
3. Test diff behavior

### Exercise 3: Security File Protection
1. Create a mock SSH key
2. Verify it's treated as binary
3. Test ignore patterns for secrets

## Assessment Questions
1. What happens when a binary file is treated as text?
2. How do you fix mixed line endings in a repository?
3. What's the difference between `binary` and `text eol=lf`?

## Resources
- [Git Attributes Documentation](https://git-scm.com/docs/gitattributes)
- [Git Ignore Documentation](https://git-scm.com/docs/gitignore)
- Internal Wiki: Git Best Practices
EOF
```

## 🎯 Implementation Roadmap

### Phase 1: Foundation (Week 1)
```bash
# Immediate implementation steps
echo "Phase 1: Foundation Setup"
echo "1. Deploy .gitattributes and .gitignore to all repositories"
echo "2. Set up team Git configuration script"
echo "3. Create validation scripts"
echo "4. Document custom patterns"

# Implementation checklist
cat > IMPLEMENTATION_CHECKLIST.md << 'EOF'
# Git Configuration Implementation Checklist

## Week 1: Foundation
- [ ] Deploy .gitattributes to all active repositories
- [ ] Deploy .gitignore to all active repositories
- [ ] Create team setup script (scripts/setup-git-config.sh)
- [ ] Set up validation scripts (scripts/test-git-config.sh)
- [ ] Document custom patterns (docs/CUSTOM_GIT_PATTERNS.md)
- [ ] Train team leads on new configuration

## Week 2: Automation
- [ ] Implement CI/CD validation pipelines
- [ ] Set up pre-commit hooks
- [ ] Create security audit scripts
- [ ] Deploy monitoring dashboards
- [ ] Configure automated testing

## Week 3: Integration
- [ ] Integrate with code review process
- [ ] Set up compliance reporting
- [ ] Configure performance monitoring
- [ ] Implement emergency procedures
- [ ] Create troubleshooting guides

## Week 4: Optimization
- [ ] Conduct performance analysis
- [ ] Optimize patterns based on usage
- [ ] Set up maintenance automation
- [ ] Complete team training
- [ ] Establish ongoing review process
EOF
```

### Phase 2: Automation (Week 2-3)
```bash
# Automation implementation
echo "Phase 2: Automation Setup"
echo "1. Set up CI/CD validation"
echo "2. Implement pre-commit hooks"
echo "3. Create monitoring dashboards"
echo "4. Deploy security scanning"

# Automation deployment script
cat > scripts/deploy-automation.sh << 'EOF'
#!/bin/bash
echo "Deploying Git configuration automation..."

# Deploy pre-commit hooks
if [ -d .git ]; then
    cp scripts/pre-commit .git/hooks/
    chmod +x .git/hooks/pre-commit
    echo "✅ Pre-commit hooks deployed"
fi

# Set up CI/CD validation
if [ ! -f .github/workflows/git-validation.yml ]; then
    mkdir -p .github/workflows
    cp templates/git-validation.yml .github/workflows/
    echo "✅ CI/CD validation configured"
fi

# Deploy security scanning
if command -v git-secrets >/dev/null 2>&1; then
    git secrets --install
    git secrets --register-aws
    echo "✅ Security scanning configured"
fi

echo "Automation deployment complete"
EOF
```

### Phase 3: Optimization (Week 4)
```bash
# Performance and security optimization
echo "Phase 3: Optimization"
echo "1. Implement Git LFS for large files"
echo "2. Set up repository maintenance automation"
echo "3. Create audit reporting"
echo "4. Conduct team training"
```

### Phase 4: Monitoring (Ongoing)
```bash
# Continuous improvement
echo "Phase 4: Ongoing Monitoring"
echo "1. Monthly configuration reviews"
echo "2. Quarterly pattern updates"
echo "3. Performance monitoring"
echo "4. Security audits"

# Monthly review script
cat > scripts/monthly-review.sh << 'EOF'
#!/bin/bash
echo "=== Monthly Git Configuration Review ==="
echo "Date: $(date)"
echo "Repository: $(git remote get-url origin)"

# Generate metrics
echo "## Repository Metrics"
echo "- Total files: $(git ls-files | wc -l)"
echo "- Binary files: $(git ls-files | xargs git check-attr binary | grep -c 'binary: set')"
echo "- Repository size: $(du -sh .git | cut -f1)"
echo "- Ignored files: $(git status --ignored --porcelain | wc -l)"

# Security check
echo "## Security Status"
scripts/security-audit.sh > /dev/null 2>&1 && echo "- Security: ✅ PASS" || echo "- Security: ❌ FAIL"

# Performance check
echo "## Performance Metrics"
echo "- Clone time: $(time git clone --depth 1 . /tmp/perf-test 2>&1 | grep real | awk '{print $2}')"
rm -rf /tmp/perf-test

# Recommendations
echo "## Recommendations"
large_files=$(find . -type f -size +1M -not -path './.git/*' | wc -l)
if [ $large_files -gt 0 ]; then
    echo "- Consider Git LFS for $large_files large files"
fi

echo "Review complete"
EOF
```

## 📊 Success Metrics

### Key Performance Indicators
```bash
# KPI tracking script
cat > scripts/track-kpis.sh << 'EOF'
#!/bin/bash
echo "=== Git Configuration KPIs ==="

# Repository Size Tracking
repo_size=$(du -sh .git | cut -f1)
echo "Repository Size: $repo_size"

# Clone Time Tracking
clone_time=$(time git clone --depth 1 . /tmp/clone-test 2>&1 | grep real | awk '{print $2}')
rm -rf /tmp/clone-test
echo "Clone Time: $clone_time"

# Security Metrics
security_files=$(find . -name "*.key" -o -name "*.pem" -o -name "*.p12" | wc -l)
echo "Security Files: $security_files"

# Team Compliance
team_members=$(git log --format='%ae' --since="1 month ago" | sort -u | wc -l)
compliant_configs=$(git log --format='%ae' --since="1 month ago" | sort -u | while read email; do
    if git config --global core.autocrlf | grep -q false; then echo 1; fi
done | wc -l)
compliance_rate=$((compliant_configs * 100 / team_members))
echo "Team Compliance: $compliance_rate%"

# Build Success Rate (from CI/CD)
echo "Build Success Rate: Check CI/CD dashboard"
EOF
```

### Monitoring Commands
```bash
# Weekly metrics collection
cat > scripts/weekly-metrics.sh << 'EOF'
#!/bin/bash
echo "Weekly Git metrics for $(date):"
echo "Repository metrics:"
echo "  Size: $(du -sh .git | cut -f1)"
echo "  Files: $(git ls-files | wc -l)"
echo "  Binary files: $(git ls-files | xargs git check-attr binary | grep -c 'binary: set')"
echo "  Last security audit: $(stat -c %y scripts/security-audit.sh 2>/dev/null || echo 'Never')"

# Performance metrics
echo "Performance metrics:"
echo "  Average commit size: $(git log --oneline --since="1 week ago" | wc -l) commits"
echo "  Repository growth: $(git count-objects -vH | grep size-pack | awk '{print $2}')"

# Security metrics
echo "Security metrics:"
echo "  Secrets prevented: Check git-secrets logs"
echo "  Binary files protected: $(git ls-files | xargs git check-attr binary | grep -c 'binary: set')"
EOF
```

## 🚀 Quick Start Implementation

### Immediate Actions (Today)
```bash
# 1. Deploy basic configuration
cp .gitattributes /path/to/your/project/
cp .gitignore /path/to/your/project/

# 2. Set up team configuration
scripts/setup-git-config.sh

# 3. Run initial validation
scripts/test-git-config.sh

# 4. Create first audit report
scripts/security-audit.sh
```

### This Week
```bash
# 1. Set up automation
scripts/deploy-automation.sh

# 2. Train team members
# Share docs/GIT_TRAINING.md

# 3. Implement monitoring
scripts/weekly-metrics.sh

# 4. Document custom patterns
# Update docs/CUSTOM_GIT_PATTERNS.md
```

---

*This comprehensive best practices guide ensures enterprise-grade Git configuration management for Oracle Linux 9 development environments, focusing on security, performance, team collaboration, and continuous improvement.*
