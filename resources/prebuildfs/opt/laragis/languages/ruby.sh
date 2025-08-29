#!/usr/bin/env bash
# =============================================================================
# Ruby Installation with rbenv and Bundler
# =============================================================================
# DESCRIPTION: Install Ruby programming language with rbenv version manager and Bundler
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly RUBY_VERSION="${RUBY_VERSION:-3.3.6}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/ruby.installed"

is_installed() { command -v ruby >/dev/null 2>&1 || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_ruby_dependencies() {
    log_info "Installing Ruby build dependencies..."
    
    # Install Ruby build dependencies
    dnf -y install \
        gcc \
        gcc-c++ \
        make \
        patch \
        autoconf \
        automake \
        bison \
        libtool \
        # Ruby-specific dependencies
        openssl-devel \
        libyaml-devel \
        libffi-devel \
        readline-devel \
        zlib-devel \
        gdbm-devel \
        ncurses-devel \
        # Additional libraries
        sqlite-devel \
        mysql-devel \
        postgresql-devel \
        # Image processing libraries
        ImageMagick-devel \
        # XML libraries
        libxml2-devel \
        libxslt-devel
    
    log_success "Ruby build dependencies installed successfully"
}

install_rbenv() {
    log_info "Installing rbenv (Ruby version manager)..."
    
    # Clone rbenv
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    
    # Clone ruby-build plugin
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
    
    # Add rbenv to PATH
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    
    # Make rbenv available system-wide
    ln -sf ~/.rbenv/bin/rbenv /usr/local/bin/rbenv
    
    # Set up rbenv environment for current session
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    
    log_success "rbenv installed successfully"
}

install_ruby() {
    log_info "Installing Ruby ${RUBY_VERSION}..."
    
    # Install Ruby using rbenv
    ~/.rbenv/bin/rbenv install "${RUBY_VERSION}"
    ~/.rbenv/bin/rbenv global "${RUBY_VERSION}"
    ~/.rbenv/bin/rbenv rehash
    
    # Make Ruby available system-wide
    ln -sf ~/.rbenv/versions/"${RUBY_VERSION}"/bin/ruby /usr/local/bin/ruby
    ln -sf ~/.rbenv/versions/"${RUBY_VERSION}"/bin/gem /usr/local/bin/gem
    ln -sf ~/.rbenv/versions/"${RUBY_VERSION}"/bin/irb /usr/local/bin/irb
    
    # Set up Ruby environment variables
    echo "export RBENV_ROOT=\"\$HOME/.rbenv\"" >> /etc/environment
    echo "export PATH=\"\$RBENV_ROOT/bin:\$PATH\"" >> /etc/environment
    echo "eval \"\$(rbenv init -)\"" >> /etc/environment
    
    log_success "Ruby ${RUBY_VERSION} installed successfully"
}

install_bundler_and_gems() {
    log_info "Installing Bundler and common Ruby gems..."
    
    # Set up Ruby environment
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    
    # Install Bundler
    gem install bundler
    
    # Install common Ruby gems
    gem install \
        rake \
        rails \
        sinatra \
        rspec \
        minitest \
        pry \
        rubocop \
        yard \
        nokogiri \
        json \
        httparty \
        faraday \
        sidekiq \
        redis \
        pg \
        mysql2 \
        sqlite3
    
    # Update RubyGems
    gem update --system
    
    # Rehash rbenv
    ~/.rbenv/bin/rbenv rehash
    
    # Make gem binaries available system-wide
    ln -sf ~/.rbenv/versions/"${RUBY_VERSION}"/bin/bundle /usr/local/bin/bundle
    ln -sf ~/.rbenv/versions/"${RUBY_VERSION}"/bin/rails /usr/local/bin/rails
    ln -sf ~/.rbenv/versions/"${RUBY_VERSION}"/bin/rake /usr/local/bin/rake
    ln -sf ~/.rbenv/versions/"${RUBY_VERSION}"/bin/rspec /usr/local/bin/rspec
    ln -sf ~/.rbenv/versions/"${RUBY_VERSION}"/bin/rubocop /usr/local/bin/rubocop
    
    log_success "Bundler and common gems installed successfully"
}

configure_ruby_environment() {
    log_info "Configuring Ruby development environment..."
    
    # Create Ruby project directories
    mkdir -p /opt/ruby-templates
    
    # Create Ruby project template
    cat > /opt/ruby-templates/init-project.sh << 'EOF'
#!/bin/bash
# Ruby Project Initializer
PROJECT_NAME=${1:-my-ruby-project}
PROJECT_TYPE=${2:-gem}

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

case "$PROJECT_TYPE" in
    "rails")
        rails new . --skip-git
        ;;
    "sinatra")
        # Create basic Sinatra app structure
        mkdir -p lib public views
        cat > Gemfile << 'GEMFILE'
source 'https://rubygems.org'

gem 'sinatra'
gem 'sinatra-contrib'
gem 'puma'

group :development do
  gem 'rerun'
end

group :test do
  gem 'rspec'
  gem 'rack-test'
end
GEMFILE
        
        cat > app.rb << 'APP'
require 'sinatra'

get '/' do
  'Hello, World!'
end
APP
        ;;
    "gem"|*)
        # Create basic gem structure
        bundle gem "$PROJECT_NAME" --no-exe --no-coc --no-mit
        cd "$PROJECT_NAME"
        ;;
esac

echo "Ruby $PROJECT_TYPE project '$PROJECT_NAME' initialized"
echo "Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. bundle install"
echo "3. Start developing!"
EOF
    chmod +x /opt/ruby-templates/init-project.sh
    ln -sf /opt/ruby-templates/init-project.sh /usr/local/bin/init-ruby-project
    
    # Configure gem settings
    cat > ~/.gemrc << 'EOF'
gem: --no-document
install: --no-document
update: --no-document
EOF
    
    log_success "Ruby development environment configured successfully"
}

verify_ruby_installation() {
    log_info "Verifying Ruby installation..."
    
    # Set up environment
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    
    # Verify Ruby
    if command -v ruby >/dev/null 2>&1; then
        log_success "✅ Ruby: $(ruby --version)"
    else
        log_error "❌ Ruby installation failed"
        return 1
    fi
    
    # Verify rbenv
    if command -v rbenv >/dev/null 2>&1; then
        log_success "✅ rbenv: $(rbenv --version)"
    else
        log_error "❌ rbenv installation failed"
        return 1
    fi
    
    # Verify Bundler
    if command -v bundle >/dev/null 2>&1; then
        log_success "✅ Bundler: $(bundle --version)"
    else
        log_error "❌ Bundler installation failed"
        return 1
    fi
    
    # Verify Rails
    if command -v rails >/dev/null 2>&1; then
        log_success "✅ Rails: $(rails --version)"
    else
        log_warn "⚠️  Rails not available (install with: gem install rails)"
    fi
}

# Main function
main() {
    log_info "Setting up Ruby development environment..."
    
    is_installed && { log_info "Ruby is already installed"; return 0; }
    
    install_ruby_dependencies
    install_rbenv
    install_ruby
    install_bundler_and_gems
    configure_ruby_environment
    verify_ruby_installation
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
    
    log_success "Ruby ${RUBY_VERSION} development environment installed successfully"
}

main "$@"
