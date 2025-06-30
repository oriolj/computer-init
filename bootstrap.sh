#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            VER=${VERSION_ID:-"unknown"}
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        VER="unknown"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    log_info "Detected OS: $OS (version: $VER)"
}

# Install Python and pip
install_python() {
    log_info "Checking Python installation..."
    
    if command -v python3 &> /dev/null; then
        log_info "Python3 is already installed"
    else
        log_info "Installing Python3..."
        case $OS in
            ubuntu|debian)
                sudo apt-get update
                sudo apt-get install -y python3 python3-pip python3-venv
                ;;
            fedora)
                sudo dnf install -y python3 python3-pip
                ;;
            arch)
                sudo pacman -S --noconfirm python python-pip
                ;;
            macos)
                if ! command -v brew &> /dev/null; then
                    log_info "Installing Homebrew..."
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                fi
                brew install python3
                ;;
            *)
                log_error "Unsupported OS for Python installation"
                exit 1
                ;;
        esac
    fi
}

# Install Ansible
install_ansible() {
    log_info "Installing Ansible..."
    
    # Check if Ansible is already installed
    if command -v ansible &> /dev/null; then
        ANSIBLE_VERSION=$(ansible --version | head -n 1 | awk '{print $2}')
        log_info "Ansible $ANSIBLE_VERSION is already installed"
        read -p "Do you want to upgrade Ansible? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Install Ansible based on OS
    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y software-properties-common
            sudo add-apt-repository --yes --update ppa:ansible/ansible
            sudo apt-get install -y ansible
            ;;
        fedora)
            sudo dnf install -y ansible
            ;;
        arch)
            sudo pacman -S --noconfirm ansible
            ;;
        macos)
            brew install ansible
            ;;
        *)
            # Fallback to pip installation
            log_warning "Using pip to install Ansible"
            python3 -m pip install --user ansible
            ;;
    esac
    
    # Verify installation
    if command -v ansible &> /dev/null; then
        log_info "Ansible installed successfully"
        ansible --version
    else
        log_error "Ansible installation failed"
        exit 1
    fi
}

# Install additional dependencies
install_dependencies() {
    log_info "Installing additional dependencies..."
    
    case $OS in
        ubuntu|debian)
            sudo apt-get install -y git curl wget
            ;;
        fedora)
            sudo dnf install -y git curl wget
            ;;
        arch)
            sudo pacman -S --noconfirm git curl wget
            ;;
        macos)
            brew install git curl wget
            ;;
    esac
}

# Setup Ansible Galaxy requirements
setup_galaxy_requirements() {
    log_info "Installing Ansible Galaxy requirements..."
    
    if [ -f requirements.yml ]; then
        ansible-galaxy install -r requirements.yml
    else
        log_warning "No requirements.yml found, skipping Galaxy installation"
    fi
}

# Main function
main() {
    log_info "Starting Ansible Computer Init Bootstrap"
    
    # Change to script directory
    cd "$(dirname "${BASH_SOURCE[0]}")"
    
    # Detect OS
    detect_os
    
    # Install prerequisites
    install_python
    install_ansible
    install_dependencies
    
    # Setup Ansible Galaxy requirements
    setup_galaxy_requirements
    
    log_info "Bootstrap completed successfully!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Review and customize group_vars/all/main.yml"
    log_info "2. Run: ansible-playbook playbooks/site.yml --ask-become-pass"
    log_info "3. Or run specific tags: ansible-playbook playbooks/site.yml --tags \"shell,development\""
}

# Run main function
main "$@"