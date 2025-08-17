#!/bin/bash
# -----------------------------------------------------------------------------
# Crontab Service Installation Script
# -----------------------------------------------------------------------------
# This script installs and configures crontab service using cronie package
# -----------------------------------------------------------------------------

set -euo pipefail

# Function to log messages
log() {
    echo "==> $1"
}

# Install Crontab service (using cronie)
install_crontab() {
    if [ "${INSTALL_CRONTAB:-0}" = "1" ]; then
        log "Installing crontab service"
        
        # Install cronie package for cron functionality
        dnf -y install --setopt=install_weak_deps=False --nodocs cronie
        
        # Create cron directories with proper permissions
        mkdir -p /var/spool/cron /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.monthly /etc/cron.weekly
        chmod 755 /var/spool/cron
        
        log "Crontab service installed successfully"
    else
        log "Skipping crontab installation"
    fi
}

# Run installation
install_crontab
