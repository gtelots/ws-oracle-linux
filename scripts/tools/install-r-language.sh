#!/bin/bash

# =============================================================================
# Install R Language and Essential Packages
# R is a programming language for statistical computing and graphics
# =============================================================================

set -euo pipefail

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly COMMON_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/common"

# Source common functions
if [[ -f "$COMMON_DIR/functions.sh" ]]; then
    # shellcheck source=../../common/functions.sh
    source "$COMMON_DIR/functions.sh"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[SUCCESS] ✅ $1"; }
    log_error() { echo "[ERROR] ❌ $1"; }
    log_warning() { echo "[WARNING] ⚠️ $1"; }
fi

# Configuration
readonly TOOL_NAME="R"
readonly VERSION="${R_VERSION:-latest}"
readonly LOCK_FILE="/tmp/install-r-language.lock"

# Lock file management
cleanup() {
    if [[ -f "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE"
    fi
}
trap cleanup EXIT

install_r_base() {
    log_info "Installing R Language base system..."
    
    # Create lock file
    if [[ -f "$LOCK_FILE" ]]; then
        log_error "R Language installation already in progress"
        return 1
    fi
    echo $$ > "$LOCK_FILE"
    
    # Check if already installed
    if command -v R >/dev/null 2>&1; then
        local current_version
        current_version=$(R --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        log_success "R v${current_version} is already installed"
        return 0
    fi
    
    # Enable EPEL repository if not already enabled
    log_info "Enabling EPEL repository for R packages..."
    if [[ $EUID -eq 0 ]]; then
        dnf install -y epel-release || {
            log_warning "EPEL repository may already be enabled"
        }
        dnf config-manager --set-enabled crb || {
            log_warning "CRB repository may already be enabled"
        }
    else
        sudo dnf install -y epel-release || {
            log_warning "EPEL repository may already be enabled"
        }
        sudo dnf config-manager --set-enabled crb || {
            log_warning "CRB repository may already be enabled"
        }
    fi
    
    # Install R and essential dependencies
    log_info "Installing R and essential packages..."
    local r_packages=(
        "R"                          # R base system
        "R-devel"                    # R development headers
        "R-core-devel"               # R core development
        "libcurl-devel"              # For RCurl package
        "openssl-devel"              # For OpenSSL support
        "libxml2-devel"              # For XML package
        "harfbuzz-devel"             # For text shaping
        "fribidi-devel"              # For text rendering
        "freetype-devel"             # For fonts
        "png-devel"                  # For PNG support
        "libtiff-devel"              # For TIFF support
        "libjpeg-turbo-devel"        # For JPEG support
        "cairo-devel"                # For graphics
        "pango-devel"                # For text layout
        "gfortran"                   # Fortran compiler for R packages
        "blas-devel"                 # Basic Linear Algebra Subprograms
        "lapack-devel"               # Linear Algebra PACKage
    )
    
    if [[ $EUID -eq 0 ]]; then
        dnf install -y "${r_packages[@]}" || {
            log_error "Failed to install R packages"
            return 1
        }
    else
        sudo dnf install -y "${r_packages[@]}" || {
            log_error "Failed to install R packages"
            return 1
        }
    fi
    
    # Verify R installation
    if command -v R >/dev/null 2>&1; then
        local installed_version
        installed_version=$(R --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        log_success "R v${installed_version} installed successfully!"
    else
        log_error "R installation verification failed"
        return 1
    fi
}

install_essential_r_packages() {
    log_info "Installing essential R packages..."
    
    # Create R script for package installation
    local r_script="/tmp/install_r_packages.R"
    cat > "$r_script" << 'EOF'
# Install essential R packages
essential_packages <- c(
    "devtools",      # Development tools
    "tidyverse",     # Data science ecosystem
    "data.table",    # Fast data manipulation
    "ggplot2",       # Advanced plotting
    "dplyr",         # Data manipulation
    "readr",         # Fast CSV reading
    "jsonlite",      # JSON handling
    "httr",          # HTTP requests
    "xml2",          # XML parsing
    "stringr",       # String manipulation
    "lubridate",     # Date/time handling
    "shiny",         # Web applications
    "knitr",         # Dynamic reports
    "rmarkdown",     # R Markdown
    "DBI",           # Database interface
    "RSQLite",       # SQLite interface
    "RPostgreSQL",   # PostgreSQL interface
    "RMySQL",        # MySQL interface
    "mongolite",     # MongoDB interface
    "curl",          # HTTP client
    "openssl",       # Cryptography
    "remotes",       # Remote package installation
    "testthat",      # Unit testing
    "roxygen2",      # Documentation
    "pkgdown",       # Package websites
    "lintr",         # Code linting
    "styler"         # Code formatting
)

# Function to install packages safely
install_package_safe <- function(pkg) {
    cat(paste("Installing", pkg, "...\n"))
    tryCatch({
        if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
            install.packages(pkg, repos = "https://cloud.r-project.org/", 
                           dependencies = TRUE, quiet = TRUE)
            cat(paste("✅", pkg, "installed successfully\n"))
        } else {
            cat(paste("✅", pkg, "already installed\n"))
        }
    }, error = function(e) {
        cat(paste("❌ Failed to install", pkg, ":", e$message, "\n"))
    })
}

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org/"))

# Install packages
cat("Installing essential R packages...\n")
for (pkg in essential_packages) {
    install_package_safe(pkg)
}

cat("\n✅ R package installation completed!\n")

# Print session info
cat("\nR Session Info:\n")
sessionInfo()
EOF
    
    log_info "Running R package installation script..."
    if R --slave --no-restore --file="$r_script"; then
        log_success "Essential R packages installed successfully!"
    else
        log_warning "Some R packages may have failed to install"
    fi
    
    # Cleanup
    rm -f "$r_script"
}

setup_r_environment() {
    log_info "Setting up R environment..."
    
    # Create R configuration directory
    local r_config_dir="$HOME/.config/R"
    mkdir -p "$r_config_dir"
    
    # Create .Rprofile for user customization
    local rprofile="$HOME/.Rprofile"
    if [[ ! -f "$rprofile" ]]; then
        cat > "$rprofile" << 'EOF'
# R Profile Configuration
# This file is executed when R starts

# Set default CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org/"))

# Set default library paths
.libPaths(c(.libPaths(), "~/R/library"))

# Load commonly used packages silently
suppressPackageStartupMessages({
    if (require(tidyverse, quietly = TRUE)) {
        cat("✅ tidyverse loaded\n")
    }
    if (require(data.table, quietly = TRUE)) {
        cat("✅ data.table loaded\n")
    }
})

# Custom functions
hello_r <- function() {
    cat("🎉 Welcome to R!\n")
    cat("📊 R version:", R.version.string, "\n")
    cat("📦 Installed packages:", length(installed.packages()[,1]), "\n")
}

# Automatically call hello function
hello_r()

# Set options for better output
options(
    width = 120,
    max.print = 1000,
    scipen = 999,  # Disable scientific notation
    digits = 4
)

cat("✅ R environment ready!\n")
EOF
        log_success "Created R profile: $rprofile"
    fi
    
    # Create R library directory
    local r_lib_dir="$HOME/R/library"
    mkdir -p "$r_lib_dir"
    log_success "Created R library directory: $r_lib_dir"
}

create_r_aliases() {
    log_info "Creating R aliases and shortcuts..."
    
    local alias_content='
# R Language aliases
alias r="R --no-save --no-restore"
alias R="R --no-save --no-restore"
alias rscript="Rscript"
alias rstudio="echo \"RStudio not installed. Use R in terminal or install RStudio separately.\""

# R development shortcuts
alias rcheck="R CMD check"
alias rbuild="R CMD build"
alias rinstall="R CMD INSTALL"

# R package management
alias rpkg-list="R -e \"installed.packages()[,c(1,3)]\""
alias rpkg-update="R -e \"update.packages(ask=FALSE)\""
alias rpkg-clean="R -e \"remove.packages(installed.packages()[,1])\""

# R data analysis shortcuts
alias rdata="R -e \"ls.str()\""
alias rhelp="R -e \"help.start()\""
'
    
    # Add to shell configurations
    for shell_config in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$shell_config" ]]; then
            if ! grep -q "R Language aliases" "$shell_config"; then
                echo "$alias_content" >> "$shell_config"
                log_success "Added R aliases to $(basename "$shell_config")"
            fi
        fi
    done
}

show_r_usage() {
    log_info "R Language installation completed! Here's how to use it:"
    
    echo
    echo "📊 Basic R Commands:"
    echo "  R                          # Start R interactive session"
    echo "  Rscript script.R           # Run R script"
    echo "  R CMD check package        # Check R package"
    echo "  R CMD build package        # Build R package"
    echo
    echo "📦 Package Management:"
    echo "  install.packages('pkg')    # Install package"
    echo "  library(pkg)               # Load package"
    echo "  remove.packages('pkg')     # Remove package"
    echo "  update.packages()          # Update all packages"
    echo
    echo "📈 Data Analysis Examples:"
    echo "  data(mtcars)               # Load sample dataset"
    echo "  summary(mtcars)            # Data summary"
    echo "  plot(mtcars\$mpg)          # Simple plot"
    echo "  ggplot(mtcars, aes(x=mpg, y=hp)) + geom_point()  # ggplot"
    echo
    echo "📚 Learning Resources:"
    echo "  help.start()               # R help system"
    echo "  vignette()                 # List vignettes"
    echo "  example(function_name)     # Function examples"
    echo
    echo "🔧 Configuration Files:"
    echo "  ~/.Rprofile                # R startup configuration"
    echo "  ~/R/library/               # User library directory"
    echo
}

# Main execution
main() {
    log_info "Starting R Language installation..."
    
    if install_r_base; then
        install_essential_r_packages
        setup_r_environment
        create_r_aliases
        show_r_usage
        
        log_success "R Language environment setup completed successfully!"
        
    else
        log_error "R Language installation failed!"
        return 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
