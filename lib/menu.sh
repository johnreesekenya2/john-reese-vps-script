#!/bin/bash

# JOHN REESE VPS - Menu System
# Beautiful colorized CLI menu interface

# Display main menu
show_main_menu() {
    while true; do
        show_ascii_banner
        
        echo -e "${BOLD}${WHITE}👑 JOHN REESE VPS SCRIPT MENU 👑${NC}"
        echo -e "${GRAY}───────────────────────────────────────────────────────────${NC}"
        echo -e " ${GREEN}1.${NC}  ➕ ${WHITE}Add User${NC}"
        echo -e " ${GREEN}2.${NC}  ❌ ${WHITE}Remove User${NC}"
        echo -e " ${GREEN}3.${NC}  🔒 ${WHITE}Suspend User${NC}"
        echo -e " ${GREEN}4.${NC}  🔓 ${WHITE}Unsuspend User${NC}"
        echo -e " ${GREEN}5.${NC}  🚫 ${WHITE}Ban User${NC}"
        echo -e " ${GREEN}6.${NC}  🔑 ${WHITE}Change Password${NC}"
        echo -e " ${GREEN}7.${NC}  ♻️  ${WHITE}Renew Account${NC}"
        echo -e " ${GREEN}8.${NC}  📊 ${WHITE}User Bandwidth Usage${NC}"
        echo -e " ${GREEN}9.${NC}  🎚  ${WHITE}Set Bandwidth or Expiry${NC}"
        echo -e " ${GREEN}10.${NC} 🌐 ${WHITE}Add Domain${NC}"
        echo -e " ${GREEN}11.${NC} 🔐 ${WHITE}Renew SSL Certificate${NC}"
        echo -e " ${GREEN}12.${NC} 🧹 ${WHITE}Remove Script${NC}"
        echo -e " ${GREEN}13.${NC} 👥 ${WHITE}List All Users${NC}"
        echo -e " ${GREEN}14.${NC} 📈 ${WHITE}VPS Usage Report${NC}"
        echo -e " ${GREEN}15.${NC} ❎ ${WHITE}Exit${NC}"
        echo -e "${GRAY}───────────────────────────────────────────────────────────${NC}"
        echo -ne "${YELLOW}Enter your choice: ${NC}"
        
        read choice
        
        case $choice in
            1) add_user ;;
            2) remove_user ;;
            3) suspend_user ;;
            4) unsuspend_user ;;
            5) ban_user ;;
            6) change_password ;;
            7) renew_account ;;
            8) show_bandwidth_usage ;;
            9) set_limits ;;
            10) add_domain ;;
            11) renew_ssl ;;
            12) uninstall_system; exit 0 ;;
            13) list_users ;;
            14) vps_usage_report ;;
            15) 
                echo -e "${CYAN}👋 Thank you for using JOHN REESE VPS Script!${NC}"
                show_creator_credits
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid choice! Please select 1-15.${NC}"
                sleep 2
                ;;
        esac
        
        echo
        echo -ne "${WHITE}Press Enter to continue...${NC}"
        read
    done
}

# Prompt for input with color
prompt_input() {
    local prompt="$1"
    local variable_name="$2"
    local is_password="${3:-false}"
    
    echo -ne "${WHITE}$prompt: ${NC}"
    if [[ "$is_password" == "true" ]]; then
        read -s "$variable_name"
        echo
    else
        read "$variable_name"
    fi
}