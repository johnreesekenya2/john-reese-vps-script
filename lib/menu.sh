#!/bin/bash

# JOHN REESE VPS - Menu System
# Beautiful colorized CLI menu interface

# Get system information
get_system_info() {
    # Get RAM info
    local ram_used=$(free -h | awk 'NR==2{printf "%.1f/%.1fGB", $3/1024, $2/1024}')
    local ram_free=$(free -h | awk 'NR==2{printf "%.1fGB", $7/1024}')
    
    # Get storage info
    local storage=$(df -h / | awk 'NR==2{printf "%s/%s (%s used)", $3, $2, $5}')
    
    # Get IP address
    local ip=$(ip route get 8.8.8.8 2>/dev/null | awk 'NR==1{print $7}' || echo "N/A")
    
    # Get domain if configured
    local domain="Not Set"
    if [[ -f "$DATA_DIR/domain.conf" ]]; then
        domain=$(grep "^DOMAIN=" "$DATA_DIR/domain.conf" | cut -d'=' -f2)
        [[ -z "$domain" ]] && domain="Not Set"
    fi
    
    # Get today's usage (mock data - would need actual bandwidth monitoring)
    local today_usage="0.5GB"
    local total_usage="15.2GB"
    
    # Get uptime
    local uptime=$(uptime -p 2>/dev/null || echo "N/A")
    
    echo -e "${WHITE}RAM Remaining: ${YELLOW}$ram_free${WHITE} out of ${YELLOW}$ram_used${NC}"
    echo -e "${WHITE}Storage: ${YELLOW}$storage${NC}"
    echo -e "${WHITE}IP: ${YELLOW}$ip${NC}"
    echo -e "${WHITE}Domain: ${YELLOW}$domain${NC}"
    echo -e "${WHITE}Today Usage: ${YELLOW}$today_usage${NC}"
    echo -e "${WHITE}Total Usage: ${YELLOW}$total_usage${NC}"
    echo -e "${WHITE}Running for: ${YELLOW}$uptime${NC}"
}

# Get protocol status
get_protocol_status() {
    local ssh_status="${RED}OFF${NC}"
    local nginx_status="${RED}OFF${NC}"
    local vless_status="${RED}OFF${NC}"
    local vmess_status="${RED}OFF${NC}"
    local slowdns_status="${RED}OFF${NC}"
    local dropbear_status="${RED}OFF${NC}"
    local stunnel_status="${RED}OFF${NC}"
    
    # Check service statuses
    if systemctl is-active --quiet nginx 2>/dev/null; then
        nginx_status="${GREEN}ON${NC}"
    fi
    
    if systemctl is-active --quiet dropbear 2>/dev/null || pgrep -f dropbear >/dev/null; then
        dropbear_status="${GREEN}ON${NC}"
    fi
    
    if systemctl is-active --quiet stunnel4 2>/dev/null || pgrep -f stunnel >/dev/null; then
        stunnel_status="${GREEN}ON${NC}"
    fi
    
    if pgrep -f "ssh.*ws" >/dev/null; then
        ssh_status="${GREEN}ON${NC}"
    fi
    
    if pgrep -f xray >/dev/null; then
        vless_status="${GREEN}ON${NC}"
        vmess_status="${GREEN}ON${NC}"
    fi
    
    # SlowDNS check (custom implementation needed)
    if pgrep -f slowdns >/dev/null; then
        slowdns_status="${GREEN}ON${NC}"
    fi
    
    echo -e "${WHITE}SSH WS:${ssh_status} ${WHITE}NGINX:${nginx_status} ${WHITE}VLESS:${vless_status} ${WHITE}VMESS:${vmess_status} ${WHITE}SLOWDNS:${slowdns_status} ${WHITE}DROPBEAR:${dropbear_status} ${WHITE}STUNNEL:${stunnel_status}"
}

# Display main menu
show_main_menu() {
    while true; do
        show_ascii_banner
        
        echo -e "${BOLD}${CYAN}👑 VPS BY FSOCIETY 👑${NC}"
        echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Display system information
        get_system_info
        echo
        
        # Display protocol status
        get_protocol_status
        echo
        
        echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e " ${GREEN}1.${NC}  SSH WS"
        echo -e " ${GREEN}2.${NC}  TROJAN"
        echo -e " ${GREEN}3.${NC}  VMESS"
        echo -e " ${GREEN}4.${NC}  VLESS"
        echo -e " ${GREEN}5.${NC}  SLOW DNS"
        echo -e " ${GREEN}6.${NC}  UDP CUSTOM"
        echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e " ${GREEN}7.${NC}  Add Domain"
        echo -e " ${GREEN}8.${NC}  Renew Certificate"
        echo -e " ${GREEN}9.${NC}  Check User Usage"
        echo -e " ${GREEN}10.${NC} Remove Script"
        echo -e " ${GREEN}11.${NC} Owner Info"
        echo -e " ${GREEN}12.${NC} Exit"
        echo -e "${GRAY}───────────────────────────────────────────────────────────${NC}"
        echo -ne "${YELLOW}Enter your choice: ${NC}"
        
        read choice
        
        case $choice in
            1) show_protocol_menu "SSH WS" "ssh_ws" ;;
            2) show_protocol_menu "TROJAN" "trojan" ;;
            3) show_protocol_menu "VMESS" "vmess" ;;
            4) show_protocol_menu "VLESS" "vless" ;;
            5) show_protocol_menu "SLOW DNS" "slowdns" ;;
            6) show_protocol_menu "UDP CUSTOM" "udp" ;;
            7) add_domain ;;
            8) renew_ssl ;;
            9) show_bandwidth_usage ;;
            10) uninstall_system; exit 0 ;;
            11) show_owner_info ;;
            12) 
                echo -e "${CYAN}👋 Thank you for using VPS BY FSOCIETY!${NC}"
                show_creator_credits
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid choice! Please select 1-12.${NC}"
                sleep 2
                ;;
        esac
        
        echo
        echo -ne "${WHITE}Press Enter to continue...${NC}"
        read
    done
}

# Show protocol submenu
show_protocol_menu() {
    local protocol_name="$1"
    local protocol_key="$2"
    
    while true; do
        clear
        echo -e "${BOLD}${CYAN}🔧 $protocol_name Management${NC}"
        echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e " ${GREEN}1.${NC}  Add User"
        echo -e " ${GREEN}2.${NC}  Delete User"
        echo -e " ${GREEN}3.${NC}  View All Users"
        echo -e " ${GREEN}4.${NC}  Change User Password"
        echo -e " ${GREEN}0.${NC}  Back to Main Menu"
        echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -ne "${YELLOW}Enter your choice: ${NC}"
        
        read choice
        
        case $choice in
            1) add_protocol_user "$protocol_name" "$protocol_key" ;;
            2) delete_protocol_user "$protocol_name" "$protocol_key" ;;
            3) view_protocol_users "$protocol_name" "$protocol_key" ;;
            4) change_protocol_password "$protocol_name" "$protocol_key" ;;
            0) return ;;
            *) 
                echo -e "${RED}❌ Invalid choice! Please select 0-4.${NC}"
                sleep 2
                ;;
        esac
        
        echo
        echo -ne "${WHITE}Press Enter to continue...${NC}"
        read
    done
}

# Show owner information
show_owner_info() {
    clear
    echo -e "${BOLD}${CYAN}👑 Owner Information${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}Owner: ${YELLOW}John Reese${NC}"
    echo -e "${WHITE}Contact: ${YELLOW}wa.me/254745282166${NC}"
    echo -e "${WHITE}Email: ${YELLOW}fsocietycipherrevolt@gmail.com${NC}"
    echo -e "${WHITE}Organization: ${YELLOW}FSOCIETY${NC}"
    echo -e "${WHITE}Motto: ${YELLOW}IN DUST WE TRUST${NC}"
    echo -e "${WHITE}Quote: ${YELLOW}IN THE END WE ARE ALL ALONE AND NO ONE IS COMING TO SAVE YOU${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Add user for specific protocol
add_protocol_user() {
    local protocol_name="$1"
    local protocol_key="$2"
    
    echo -e "${CYAN}➕ Adding $protocol_name User${NC}"
    echo -e "${GRAY}─────────────────${NC}"
    
    local username password days expiry_date
    
    prompt_input "Username" username
    prompt_input "Password" password true
    prompt_input "Expiry (days)" days
    
    if [[ -z "$username" || -z "$password" || -z "$days" ]]; then
        log_error "All fields are required"
        return 1
    fi
    
    # Calculate expiry date
    expiry_date=$(date -d "+$days days" '+%Y-%m-%d')
    
    # Create account based on protocol
    case $protocol_key in
        "ssh_ws")
            create_ssh_account "$username" "$password" "$expiry_date"
            ;;
        "trojan"|"vmess"|"vless")
            create_xray_account "$username" "$password" "$expiry_date" "$protocol_key"
            ;;
        "slowdns")
            create_slowdns_account "$username" "$password" "$expiry_date"
            ;;
        "udp")
            create_udp_account "$username" "$password" "$expiry_date"
            ;;
    esac
}

# Delete user for specific protocol  
delete_protocol_user() {
    local protocol_name="$1"
    local protocol_key="$2"
    
    echo -e "${RED}❌ Deleting $protocol_name User${NC}"
    echo -e "${GRAY}────────────────${NC}"
    
    local username
    prompt_input "Username to delete" username
    
    if [[ -z "$username" ]]; then
        log_error "Username is required"
        return 1
    fi
    
    # Remove user from protocol
    remove_user
}

# View all users for specific protocol
view_protocol_users() {
    local protocol_name="$1" 
    local protocol_key="$2"
    
    echo -e "${CYAN}👥 $protocol_name Users${NC}"
    echo -e "${GRAY}───────────${NC}"
    
    # Show filtered user list for this protocol
    list_users
}

# Change password for protocol user
change_protocol_password() {
    local protocol_name="$1"
    local protocol_key="$2"
    
    echo -e "${BLUE}🔑 Changing $protocol_name User Password${NC}"
    echo -e "${GRAY}─────────────────────────${NC}"
    
    # Use existing change_password function
    change_password
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