#!/usr/bin/env bash
# =============================================================================
# Python Extras Installation
# =============================================================================
# DESCRIPTION: Install additional Python packages and development tools
# AUTHOR: Truong Thanh Tung <ttungbmt@gmail.com>
# =============================================================================

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Configuration
readonly PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
readonly TOOL_FOLDER="${TOOL_FOLDER:-/opt/laragis/tools}"
readonly TOOL_LOCK_FILE="${TOOL_FOLDER}/python-extras.installed"

is_installed() { [[ -f "$TOOL_LOCK_FILE" ]]; }

install_python_extras() {
    log_info "Installing Python ${PYTHON_VERSION} extras and development tools..."

    # Install additional Python packages via dnf
    dnf -y install \
        python${PYTHON_VERSION}-devel \
        python3-devel \
        python3-setuptools \
        python3-wheel \
        python3-virtualenv \
        python3-pytest \
        python3-requests \
        python3-numpy \
        python3-scipy \
        python3-matplotlib \
        python3-pandas

    # Install Poetry (Python dependency management) using specific Python version
    curl -sSL https://install.python-poetry.org | python${PYTHON_VERSION} -
    ln -sf ~/.local/bin/poetry /usr/local/bin/poetry
    
    # Install common Python development tools via pipx
    pipx install --global black
    pipx install --global flake8
    pipx install --global mypy
    pipx install --global isort
    pipx install --global bandit
    pipx install --global autopep8
    pipx install --global pylint
    pipx install --global jupyter
    pipx install --global ipython
    pipx install --global cookiecutter
    
    # Install Python web frameworks
    pipx install --global django
    pipx install --global flask
    pipx install --global fastapi
    
    # Install Python data science tools
    pipx install --global pandas-profiling
    pipx install --global streamlit
    
    # Install Python testing tools
    pipx install --global pytest
    pipx install --global tox
    pipx install --global coverage
    
    # Verify installations
    if command -v poetry >/dev/null 2>&1; then
        log_success "Poetry installed successfully: $(poetry --version)"
    fi
    
    if command -v black >/dev/null 2>&1; then
        log_success "Black code formatter installed successfully"
    fi
    
    if command -v jupyter >/dev/null 2>&1; then
        log_success "Jupyter installed successfully"
    fi
    
    if command -v django-admin >/dev/null 2>&1; then
        log_success "Django installed successfully"
    fi
    
    # Create Python virtual environment template
    mkdir -p /opt/python-templates
    cat > /opt/python-templates/create-venv.sh << EOF
#!/bin/bash
# Python Virtual Environment Creator
VENV_NAME=\${1:-venv}
python${PYTHON_VERSION} -m venv "\$VENV_NAME"
source "\$VENV_NAME/bin/activate"
pip install --upgrade pip setuptools wheel
echo "Virtual environment '\$VENV_NAME' created and activated"
echo "To activate: source \$VENV_NAME/bin/activate"
echo "To deactivate: deactivate"
EOF
    chmod +x /opt/python-templates/create-venv.sh
    ln -sf /opt/python-templates/create-venv.sh /usr/local/bin/create-venv
    
    # Create Python project template
    cat > /opt/python-templates/init-project.sh << 'EOF'
#!/bin/bash
# Python Project Initializer
PROJECT_NAME=${1:-my-python-project}
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create basic project structure
mkdir -p src tests docs
touch README.md requirements.txt setup.py
touch src/__init__.py tests/__init__.py

# Create basic files
cat > requirements.txt << 'REQS'
# Production dependencies

# Development dependencies
pytest>=7.0.0
black>=22.0.0
flake8>=4.0.0
mypy>=0.950
REQS

cat > setup.py << 'SETUP'
from setuptools import setup, find_packages

setup(
    name="PROJECT_NAME",
    version="0.1.0",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.8",
)
SETUP

sed -i "s/PROJECT_NAME/$PROJECT_NAME/g" setup.py

echo "Python project '$PROJECT_NAME' initialized"
echo "Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. create-venv venv"
echo "3. source venv/bin/activate"
echo "4. pip install -r requirements.txt"
EOF
    chmod +x /opt/python-templates/init-project.sh
    ln -sf /opt/python-templates/init-project.sh /usr/local/bin/init-python-project
    
    log_success "Python development templates created"
    
    # Create lock file
    mkdir -p "${TOOL_FOLDER}" && touch "${TOOL_LOCK_FILE}"
}

# Main function
main() {
    log_info "Setting up Python extras and development tools..."
    
    is_installed && { log_info "Python extras are already installed"; return 0; }
    
    install_python_extras
    
    log_success "Python ${PYTHON_VERSION} extras and development tools installed successfully"
}

main "$@"
