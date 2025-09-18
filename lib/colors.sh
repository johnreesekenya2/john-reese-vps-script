#!/bin/bash

# JOHN REESE VPS - Color Definitions
# Provides consistent color output across all modules

# Color definitions
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export GRAY='\033[0;37m'
export BOLD='\033[1m'
export NC='\033[0m' # No Color

# Creator credits display
show_creator_credits() {
    echo -e "\n${GRAY}──────────────────────────────────────────${NC}"
    echo -e "${GREEN}✅ Action completed by: ${BOLD}JOHN REESE VPS SCRIPT${NC}"
    echo -e "${CYAN}👑 Creator: ${WHITE}John Reese${NC}"
    echo -e "${YELLOW}📞 ${WHITE}wa.me/254745282166${NC}"
    echo -e "${BLUE}📧 ${WHITE}fsocietycipherrevolt@gmail.com${NC}"
    echo -e "${GRAY}──────────────────────────────────────────${NC}\n"
}

# ASCII banner
show_ascii_banner() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "████████╗██╗  ██╗███████╗    ██████╗ ███████╗███████╗███████╗███████╗"
    echo "╚══██╔══╝██║  ██║██╔════╝    ██╔══██╗██╔════╝██╔════╝██╔════╝██╔════╝"
    echo "   ██║   ███████║█████╗      ██████╔╝█████╗  █████╗  ███████╗█████╗  "
    echo "   ██║   ██╔══██║██╔══╝      ██╔══██╗██╔══╝  ██╔══╝  ╚════██║██╔══╝  "
    echo "   ██║   ██║  ██║███████╗    ██║  ██║███████╗███████╗███████║███████╗"
    echo "   ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝"
    echo -e "${NC}"
}