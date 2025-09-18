#!/bin/bash

# JOHN REESE VPS - OS Detection and Utilities
# Cross-platform compatibility functions

# Global OS variables
export DETECTED_OS=""
export OS_VERSION=""
export PACKAGE_MANAGER=""

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root!${NC}"
        echo -e "${YELLOW}Please run: sudo $0${NC}"
        exit 1
    fi
}

# Detect operating system
detect_system() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DETECTED_OS=$ID
        OS_VERSION=$VERSION_ID
    elif [[ -f /etc/debian_version ]]; then
        DETECTED_OS="debian"
        OS_VERSION=$(cat /etc/debian_version)
    elif [[ -n "$PREFIX" && "$PREFIX" == *"com.termux"* ]]; then
        DETECTED_OS="termux"
        OS_VERSION="android"
    else
        DETECTED_OS="unknown"
        OS_VERSION="unknown"
    fi
    
    # Set package manager
    case "$DETECTED_OS" in
        "ubuntu"|"debian")
            PACKAGE_MANAGER="apt"
            ;;
        "termux")
            PACKAGE_MANAGER="pkg"
            ;;
        *)
            log_error "Unsupported operating system: $DETECTED_OS"
            exit 1
            ;;
    esac
    
    echo -e "${CYAN}🔍 Detected System: $DETECTED_OS $OS_VERSION${NC}"
    log_info "System detected: $DETECTED_OS $OS_VERSION"
}

# Install packages based on OS
install_system_packages() {
    local packages=("$@")
    
    echo -e "${BLUE}📦 Installing packages: ${packages[*]}${NC}"
    
    case "$PACKAGE_MANAGER" in
        "apt")
            apt update
            apt install -y "${packages[@]}"
            ;;
        "pkg")
            pkg update
            pkg install -y "${packages[@]}"
            ;;
        *)
            log_error "Unknown package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
    
    log_success "Packages installed: ${packages[*]}"
}

# Check if a service exists
service_exists() {
    local service="$1"
    systemctl list-unit-files | grep -q "^$service.service" 2>/dev/null
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}