#!/usr/bin/env bash
# =============================================================================
# Additional System Utilities Installation
# =============================================================================
# DESCRIPTION: Install additional system tools and utilities
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

install_system_monitoring_tools() {
    log_info "Installing system monitoring and performance tools..."
    
    # Install system monitoring tools
    dnf -y install \
        # System monitoring
        htop \
        iotop \
        nethogs \
        iftop \
        nload \
        # Performance analysis
        sysstat \
        perf \
        strace \
        ltrace \
        # Process management
        psmisc \
        procps-ng \
        # System information
        dmidecode \
        lshw \
        lscpu \
        lsblk \
        lsusb \
        lspci \
        # Disk utilities
        smartmontools \
        hdparm \
        # Memory analysis
        memtester \
        # Network monitoring
        tcpdump \
        nmap \
        netstat-nat \
        ss \
        # Log analysis
        logrotate \
        rsyslog
    
    log_success "System monitoring tools installed successfully"
}

install_file_system_tools() {
    log_info "Installing file system and storage tools..."
    
    # Install file system tools
    dnf -y install \
        # File system utilities
        e2fsprogs \
        xfsprogs \
        btrfs-progs \
        # Archive and compression
        p7zip \
        p7zip-plugins \
        lz4 \
        zstd \
        # File synchronization
        rsync \
        rclone \
        # File search and management
        locate \
        mlocate \
        findutils \
        # Disk usage analysis
        ncdu \
        # File permissions and attributes
        acl \
        attr \
        # Mount utilities
        fuse \
        sshfs
    
    # Update locate database
    updatedb || true
    
    log_success "File system tools installed successfully"
}

install_network_utilities() {
    log_info "Installing network utilities and tools..."
    
    # Install network utilities
    dnf -y install \
        # Network configuration
        NetworkManager \
        NetworkManager-tui \
        # Network testing
        ping \
        traceroute \
        mtr \
        # Network analysis
        wireshark-cli \
        tcpdump \
        ngrep \
        # Network services
        openssh-server \
        openssh-clients \
        # VPN and tunneling
        openvpn \
        wireguard-tools \
        # Web utilities
        lynx \
        elinks \
        # Download utilities
        aria2 \
        youtube-dl \
        # Network security
        nftables \
        firewalld
    
    log_success "Network utilities installed successfully"
}

install_security_tools() {
    log_info "Installing security and encryption tools..."
    
    # Install security tools
    dnf -y install \
        # Encryption and certificates
        openssl \
        gnupg2 \
        # Password management
        pwgen \
        # System security
        aide \
        rkhunter \
        chkrootkit \
        # Access control
        policycoreutils \
        selinux-policy \
        selinux-policy-targeted \
        # Audit tools
        audit \
        auditd \
        # Intrusion detection
        fail2ban \
        # Secure communication
        stunnel
    
    log_success "Security tools installed successfully"
}

install_multimedia_tools() {
    log_info "Installing multimedia and graphics tools..."
    
    # Install multimedia tools
    dnf -y install \
        # Image processing
        ImageMagick \
        GraphicsMagick \
        # Media tools
        ffmpeg \
        # Graphics libraries
        cairo-devel \
        pango-devel \
        gdk-pixbuf2-devel \
        # Font management
        fontconfig \
        # Screen capture
        scrot
    
    log_success "Multimedia tools installed successfully"
}

configure_system_utilities() {
    log_info "Configuring system utilities..."
    
    # Configure system services
    systemctl enable rsyslog
    systemctl enable firewalld
    
    # Configure log rotation
    cat > /etc/logrotate.d/container-logs << 'EOF'
/var/log/container/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF
    
    # Create utility directories
    mkdir -p /opt/utilities/{scripts,configs,logs}
    chown -R "${USER_UID}:${USER_GID}" /opt/utilities
    
    # Create system information script
    cat > /opt/utilities/scripts/sysinfo.sh << 'EOF'
#!/bin/bash
# System Information Script
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
echo "Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5" used)"}')"
echo "CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
echo "Processes: $(ps aux | wc -l)"
EOF
    chmod +x /opt/utilities/scripts/sysinfo.sh
    ln -sf /opt/utilities/scripts/sysinfo.sh /usr/local/bin/sysinfo
    
    log_success "System utilities configured successfully"
}

verify_system_utilities() {
    log_info "Verifying system utilities installation..."
    
    # Verify essential utilities
    local utilities=(
        "htop" "rsync" "openssl" "ImageMagick"
        "ffmpeg" "nmap" "tcpdump" "firewalld"
    )
    
    local missing_utilities=()
    
    for util in "${utilities[@]}"; do
        if ! command -v "$util" >/dev/null 2>&1; then
            missing_utilities+=("$util")
        fi
    done
    
    if [[ ${#missing_utilities[@]} -eq 0 ]]; then
        log_success "✅ All system utilities are installed"
    else
        log_warn "⚠️  Some optional utilities are missing: ${missing_utilities[*]}"
    fi
    
    # Verify specific tools
    if command -v htop >/dev/null 2>&1; then
        log_success "✅ htop: System monitor available"
    fi
    
    if command -v rsync >/dev/null 2>&1; then
        log_success "✅ rsync: $(rsync --version | head -n1)"
    fi
    
    if command -v openssl >/dev/null 2>&1; then
        log_success "✅ OpenSSL: $(openssl version)"
    fi
}

# Main function
main() {
    log_info "Installing additional system utilities..."
    
    install_system_monitoring_tools
    install_file_system_tools
    install_network_utilities
    install_security_tools
    install_multimedia_tools
    configure_system_utilities
    verify_system_utilities
    
    log_success "Additional system utilities installation completed successfully"
}

main "$@"
