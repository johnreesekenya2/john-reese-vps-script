#!/bin/bash

# JOHN REESE VPS - Enhanced Installation Script
# One-line installation for the VPS management system
# Creator: John Reese

set -euo pipefail

# Configuration
REPO_OWNER="johnreesekenya2"
REPO_NAME="john-reese-vps-script"
INSTALL_DIR="/opt/john-reese-vps"
GITHUB_API_URL="https://api.github.com"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}ℹ️ $*${NC}"; }
log_success() { echo -e "${GREEN}✅ $*${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️ $*${NC}"; }
log_error() { echo -e "${RED}❌ $*${NC}"; }

# Show header
show_header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "╔════════════════════════════════════════╗"
    echo "║       🚀 JOHN REESE VPS INSTALLER       ║"
    echo "║         GitHub API Installation         ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${WHITE}Creator: John Reese${NC}"
    echo -e "${WHITE}Motto: IN DUST WE TRUST${NC}"
    echo
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        echo "Please run: sudo $0"
        exit 1
    fi
    log_success "Running as root"
}

# Install required dependencies
install_dependencies() {
    log_info "Installing dependencies..."

    # Detect OS
    if [[ -f /etc/debian_version ]]; then
        apt-get update -qq
        apt-get install -y curl wget jq unzip bash
    elif [[ -f /etc/redhat-release ]]; then
        yum install -y curl wget jq unzip bash || dnf install -y curl wget jq unzip bash
    else
        log_warn "Unknown OS, assuming dependencies are available"
    fi

    log_success "Dependencies installed"
}

# Download and install the VPS script
install_vps_script() {
    log_info "Downloading John Reese VPS script..."

    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    # Download repository as ZIP using GitHub API
    local download_url="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/main.zip"

    if curl -fsSL "$download_url" -o john-reese-vps.zip; then
        log_success "Repository downloaded"
    else
        log_error "Failed to download repository"
        exit 1
    fi

    # Extract files
    log_info "Extracting files..."
    if unzip -q john-reese-vps.zip; then
        # Move files from extracted directory
        mv john-reese-vps-script-main/* .
        rmdir john-reese-vps-script-main
        rm john-reese-vps.zip
        log_success "Files extracted"
    else
        log_error "Failed to extract files"
        exit 1
    fi

    # Make scripts executable
    chmod +x bin/* 2>/dev/null || true
    chmod +x *.sh 2>/dev/null || true
    chmod +x modules/protocols/*.sh 2>/dev/null || true

    log_success "Scripts made executable"
}

# Create system symlinks
create_symlinks() {
    log_info "Creating system symlinks..."

    # Create symlink for main script
    if [[ -f "$INSTALL_DIR/bin/john-reese-vps" ]]; then
        ln -sf "$INSTALL_DIR/bin/john-reese-vps" /usr/local/bin/john-reese-vps
        ln -sf "$INSTALL_DIR/bin/john-reese-vps" /usr/local/bin/jrvps
        log_success "Main script symlinks created"
    fi

    # Create symlink for GitHub API client
    if [[ -f "$INSTALL_DIR/bin/github-api-client" ]]; then
        ln -sf "$INSTALL_DIR/bin/github-api-client" /usr/local/bin/github-api-client
        log_success "GitHub API client symlink created"
    fi
}

# Run initial setup
run_initial_setup() {
    log_info "Running initial setup..."

    # Set ownership
    chown -R root:root "$INSTALL_DIR"

    # Create logs directory
    mkdir -p /var/log/john-reese-vps

    log_success "Initial setup completed"
}

# Show completion message
show_completion() {
    echo
    log_success "🎉 Installation completed successfully!"
    echo
    echo -e "${WHITE}Available commands:${NC}"
    echo -e "  ${GREEN}john-reese-vps${NC}     - Start the VPS management system"
    echo -e "  ${GREEN}jrvps${NC}              - Shortcut for john-reese-vps"
    echo -e "  ${GREEN}github-api-client${NC}  - GitHub API management tool"
    echo
    echo -e "${WHITE}Installation directory: ${CYAN}$INSTALL_DIR${NC}"
    echo -e "${WHITE}Logs directory: ${CYAN}/var/log/john-reese-vps${NC}"
    echo
    echo -e "${BOLD}${CYAN}Ready to use! Run 'john-reese-vps' to get started.${NC}"
    echo
    echo -e "${WHITE}Support: ${GREEN}wa.me/254745282166${NC}"
    echo -e "${WHITE}Email: ${GREEN}fsocietycipherrevolt@gmail.com${NC}"
}

# Main installation function
main() {
    show_header

    log_info "Starting John Reese VPS installation..."

    check_root
    install_dependencies
    install_vps_script
    create_symlinks
    run_initial_setup
    show_completion
}

# Handle script interruption
trap 'log_error "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"