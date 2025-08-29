#!/usr/bin/env bash
# =============================================================================
# PHP Installation with Composer
# =============================================================================
# DESCRIPTION: Install PHP with Composer package manager and common extensions
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly PHP_VERSION="${PHP_VERSION:-8.3}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/php.installed"

is_installed() { command -v php >/dev/null 2>&1 || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_php() {
    log_info "Installing PHP ${PHP_VERSION} with Composer..."
    
    # Install PHP and common extensions
    dnf -y install \
        php \
        php-cli \
        php-fpm \
        php-json \
        php-common \
        php-mysql \
        php-zip \
        php-gd \
        php-mbstring \
        php-curl \
        php-xml \
        php-pear \
        php-bcmath \
        php-intl \
        php-opcache \
        php-soap \
        php-xmlrpc \
        php-devel
    
    # Install Composer
    local temp_dir="$(mktemp -d)"
    trap "rm -rf '${temp_dir}'" EXIT
    
    curl -fsSL https://getcomposer.org/installer -o "${temp_dir}/composer-setup.php"
    php "${temp_dir}/composer-setup.php" --install-dir=/usr/local/bin --filename=composer
    
    # Make Composer executable
    chmod +x /usr/local/bin/composer
    
    # Verify PHP installation
    if command -v php >/dev/null 2>&1; then
        log_success "PHP installed successfully: $(php --version | head -n1)"
    else
        log_error "PHP installation verification failed"
        return 1
    fi
    
    # Verify Composer installation
    if command -v composer >/dev/null 2>&1; then
        log_success "Composer installed successfully: $(composer --version)"
    else
        log_error "Composer installation verification failed"
        return 1
    fi
    
    # Install common PHP tools globally via Composer
    composer global require \
        phpunit/phpunit \
        squizlabs/php_codesniffer \
        friendsofphp/php-cs-fixer \
        phpstan/phpstan \
        laravel/installer \
        symfony/console
    
    # Add Composer global bin to PATH
    echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> /etc/environment
    
    # Configure PHP settings
    local php_ini="/etc/php.ini"
    if [[ -f "$php_ini" ]]; then
        # Increase memory limit
        sed -i 's/memory_limit = .*/memory_limit = 512M/' "$php_ini"
        # Increase upload limits
        sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' "$php_ini"
        sed -i 's/post_max_size = .*/post_max_size = 64M/' "$php_ini"
        # Enable opcache
        sed -i 's/;opcache.enable=.*/opcache.enable=1/' "$php_ini"
        log_info "PHP configuration optimized"
    fi
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Setting up PHP development environment..."
    
    is_installed && { log_info "PHP is already installed"; return 0; }
    
    install_php
    
    log_success "PHP ${PHP_VERSION} development environment installed successfully"
}

main "$@"
