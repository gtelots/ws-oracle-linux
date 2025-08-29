#!/usr/bin/env bash
# =============================================================================
# Java OpenJDK Installation
# =============================================================================
# DESCRIPTION: Install Java OpenJDK with multiple version support
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly JAVA_VERSION="${JAVA_VERSION:-21}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/java.installed"

is_installed() { command -v java >/dev/null 2>&1 || [[ -f "$TOOL_LOCK_FILE" ]]; }

install_java() {
    log_info "Installing Java OpenJDK ${JAVA_VERSION}..."
    
    # Install Java OpenJDK based on version
    case "${JAVA_VERSION}" in
        "8")
            dnf -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel
            ;;
        "11")
            dnf -y install java-11-openjdk java-11-openjdk-devel
            ;;
        "17")
            dnf -y install java-17-openjdk java-17-openjdk-devel
            ;;
        "21"|*)
            dnf -y install java-21-openjdk java-21-openjdk-devel
            ;;
    esac
    
    # Install Maven
    dnf -y install maven
    
    # Install Gradle
    local gradle_version="8.11.1"
    local temp_dir="$(mktemp -d)"
    trap "rm -rf '${temp_dir}'" EXIT
    
    curl -fsSL "https://services.gradle.org/distributions/gradle-${gradle_version}-bin.zip" -o "${temp_dir}/gradle.zip"
    unzip -q "${temp_dir}/gradle.zip" -d /opt/
    ln -sf "/opt/gradle-${gradle_version}/bin/gradle" /usr/local/bin/gradle
    
    # Set JAVA_HOME
    local java_home
    case "${JAVA_VERSION}" in
        "8")
            java_home="/usr/lib/jvm/java-1.8.0-openjdk"
            ;;
        "11")
            java_home="/usr/lib/jvm/java-11-openjdk"
            ;;
        "17")
            java_home="/usr/lib/jvm/java-17-openjdk"
            ;;
        "21"|*)
            java_home="/usr/lib/jvm/java-21-openjdk"
            ;;
    esac
    
    # Add JAVA_HOME to environment
    echo "export JAVA_HOME=${java_home}" >> /etc/environment
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/environment
    
    # Verify installation
    export JAVA_HOME="${java_home}"
    export PATH="$JAVA_HOME/bin:$PATH"
    
    if command -v java >/dev/null 2>&1; then
        log_success "Java installed successfully: $(java -version 2>&1 | head -n1)"
    else
        log_error "Java installation verification failed"
        return 1
    fi
    
    if command -v mvn >/dev/null 2>&1; then
        log_success "Maven installed successfully: $(mvn -version | head -n1)"
    fi
    
    if command -v gradle >/dev/null 2>&1; then
        log_success "Gradle installed successfully: $(gradle --version | head -n1)"
    fi
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Setting up Java development environment..."
    
    is_installed && { log_info "Java is already installed"; return 0; }
    
    install_java
    
    log_success "Java OpenJDK ${JAVA_VERSION} development environment installed successfully"
}

main "$@"
