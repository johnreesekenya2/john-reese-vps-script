#!/bin/bash

# JOHN REESE VPS - Bandwidth Monitoring
# User bandwidth tracking and usage reports

BANDWIDTH_LOG="$DATA_DIR/bandwidth.log"
BANDWIDTH_CONFIG="$DATA_DIR/bandwidth.conf"

# Initialize bandwidth monitoring
init_bandwidth_monitoring() {
    if [[ ! -f "$BANDWIDTH_CONFIG" ]]; then
        cat > "$BANDWIDTH_CONFIG" << 'EOF'
# JOHN REESE VPS - Bandwidth Configuration
MONITORING_ENABLED=true
LOG_INTERVAL=300
ALERT_THRESHOLD_GB=50
EOF
    fi
    
    if [[ ! -f "$BANDWIDTH_LOG" ]]; then
        echo "# JOHN REESE VPS - Bandwidth Log" > "$BANDWIDTH_LOG"
        echo "# Format: timestamp:username:rx_bytes:tx_bytes:total_bytes" >> "$BANDWIDTH_LOG"
    fi
}

# Show user bandwidth usage
show_bandwidth_usage() {
    echo -e "${CYAN}📊 User Bandwidth Usage${NC}"
    echo -e "${GRAY}──────────────────────${NC}"
    
    local username
    prompt_input "Username (leave empty for all)" username
    
    if [[ -z "$username" ]]; then
        show_all_users_bandwidth
    else
        show_user_bandwidth "$username"
    fi
    
    show_creator_credits
}

# Show bandwidth for all users
show_all_users_bandwidth() {
    echo -e "${WHITE}📈 Bandwidth Usage Report - All Users${NC}"
    echo -e "${GRAY}═══════════════════════════════════════${NC}"
    
    if [[ ! -f "$USERS_DB" ]]; then
        echo -e "${YELLOW}📝 No users found.${NC}"
        return 0
    fi
    
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║ ${BOLD}Username${NC}${WHITE}     │ ${BOLD}Downloaded${NC}${WHITE}    │ ${BOLD}Uploaded${NC}${WHITE}      │ ${BOLD}Total${NC}${WHITE}        ║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════╣${NC}"
    
    while IFS=: read -r username expiry status protocols uuid; do
        if [[ "$username" != "#"* && -n "$username" ]]; then
            local rx_mb tx_mb total_mb
            get_user_bandwidth_data "$username" rx_mb tx_mb total_mb
            
            printf "${WHITE}║ %-12s │ %-12s │ %-12s │ %-12s ║${NC}\n" \
                "$username" "${rx_mb} MB" "${tx_mb} MB" "${total_mb} MB"
        fi
    done < "$USERS_DB"
    
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
}

# Show bandwidth for specific user
show_user_bandwidth() {
    local username="$1"
    
    if ! grep -q "^$username:" "$USERS_DB"; then
        log_error "User '$username' not found"
        return 1
    fi
    
    echo -e "${WHITE}📈 Bandwidth Usage Report - $username${NC}"
    echo -e "${GRAY}═══════════════════════════════════════${NC}"
    
    local rx_mb tx_mb total_mb
    get_user_bandwidth_data "$username" rx_mb tx_mb total_mb
    
    echo -e "${WHITE}Downloaded: ${GREEN}${rx_mb} MB${NC}"
    echo -e "${WHITE}Uploaded: ${GREEN}${tx_mb} MB${NC}"
    echo -e "${WHITE}Total: ${YELLOW}${total_mb} MB${NC}"
    
    # Show recent usage history
    echo -e "\n${WHITE}Recent Usage History:${NC}"
    show_user_bandwidth_history "$username"
}

# Get user bandwidth data
get_user_bandwidth_data() {
    local username="$1"
    local -n rx_ref=$2
    local -n tx_ref=$3
    local -n total_ref=$4
    
    # Try to get data from vnstat if available
    if command_exists vnstat; then
        local rx_bytes=$(vnstat -i eth0 --json 2>/dev/null | jq -r ".interfaces[0].traffic.total.rx" 2>/dev/null || echo "0")
        local tx_bytes=$(vnstat -i eth0 --json 2>/dev/null | jq -r ".interfaces[0].traffic.total.tx" 2>/dev/null || echo "0")
        
        rx_ref=$((rx_bytes / 1024 / 1024))
        tx_ref=$((tx_bytes / 1024 / 1024))
        total_ref=$((rx_ref + tx_ref))
    else
        # Fallback to network interface statistics
        local interface=$(ip route | grep default | awk '{print $5}' | head -n1)
        if [[ -n "$interface" && -f "/sys/class/net/$interface/statistics/rx_bytes" ]]; then
            local rx_bytes=$(cat "/sys/class/net/$interface/statistics/rx_bytes")
            local tx_bytes=$(cat "/sys/class/net/$interface/statistics/tx_bytes")
            
            rx_ref=$((rx_bytes / 1024 / 1024))
            tx_ref=$((tx_bytes / 1024 / 1024))
            total_ref=$((rx_ref + tx_ref))
        else
            # If no interface stats available, use placeholder values
            rx_ref=0
            tx_ref=0
            total_ref=0
        fi
    fi
    
    # Log bandwidth data
    log_bandwidth_usage "$username" "$rx_ref" "$tx_ref" "$total_ref"
}

# Log bandwidth usage
log_bandwidth_usage() {
    local username="$1"
    local rx_mb="$2"
    local tx_mb="$3"
    local total_mb="$4"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp:$username:$rx_mb:$tx_mb:$total_mb" >> "$BANDWIDTH_LOG"
}

# Show user bandwidth history
show_user_bandwidth_history() {
    local username="$1"
    
    if [[ -f "$BANDWIDTH_LOG" ]]; then
        echo -e "${GRAY}Last 10 entries:${NC}"
        grep ":$username:" "$BANDWIDTH_LOG" | tail -n 10 | while IFS=: read -r timestamp user rx tx total; do
            echo -e "${GRAY}$timestamp${NC} - Down: ${GREEN}${rx}MB${NC}, Up: ${GREEN}${tx}MB${NC}, Total: ${YELLOW}${total}MB${NC}"
        done
    else
        echo -e "${GRAY}No bandwidth history available.${NC}"
    fi
}

# Set bandwidth or expiry limits
set_limits() {
    echo -e "${PURPLE}🎚 Set Bandwidth or Expiry Limits${NC}"
    echo -e "${GRAY}─────────────────────────────────${NC}"
    
    local username
    prompt_input "Username" username
    
    if [[ -z "$username" ]]; then
        log_error "Username is required"
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$USERS_DB"; then
        log_error "User '$username' not found"
        return 1
    fi
    
    echo -e "${WHITE}Choose limit type:${NC}"
    echo -e " ${GREEN}1.${NC} Set bandwidth limit"
    echo -e " ${GREEN}2.${NC} Set expiry date"
    echo -ne "${WHITE}Choice: ${NC}"
    read choice
    
    case $choice in
        1)
            local limit_gb
            prompt_input "Bandwidth limit (GB)" limit_gb
            if [[ "$limit_gb" =~ ^[0-9]+$ ]]; then
                echo "bandwidth_limit_$username=$limit_gb" >> "$BANDWIDTH_CONFIG"
                echo -e "${GREEN}✅ Bandwidth limit set to ${limit_gb}GB for user '$username'!${NC}"
                log_success "Bandwidth limit set to ${limit_gb}GB for user '$username'"
            else
                log_error "Invalid bandwidth limit. Please enter a number."
                return 1
            fi
            ;;
        2)
            local new_expiry
            prompt_input "New expiry date (YYYY-MM-DD)" new_expiry
            if [[ "$new_expiry" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                sed -i "s/^$username:[^:]*:\\(.*\\)$/$username:$new_expiry:\\1/" "$USERS_DB"
                create_ssh_banner "$username" "$new_expiry"
                echo -e "${GREEN}✅ Expiry date set to $new_expiry for user '$username'!${NC}"
                log_success "Expiry date set to $new_expiry for user '$username'"
            else
                log_error "Invalid date format. Please use YYYY-MM-DD."
                return 1
            fi
            ;;
        *)
            log_error "Invalid choice"
            return 1
            ;;
    esac
    
    show_creator_credits
}

# VPS usage report
vps_usage_report() {
    echo -e "${CYAN}📈 VPS Usage Report${NC}"
    echo -e "${GRAY}──────────────────${NC}"
    
    # System information
    echo -e "${WHITE}🖥️ System Information:${NC}"
    echo -e "   ${GRAY}OS: $DETECTED_OS $(uname -r)${NC}"
    echo -e "   ${GRAY}Uptime: $(uptime -p 2>/dev/null || echo "Unknown")${NC}"
    echo -e "   ${GRAY}Load Average: $(uptime | awk -F'load average:' '{print $2}' 2>/dev/null || echo "Unknown")${NC}"
    
    # Memory usage
    echo -e "\n${WHITE}💾 Memory Usage:${NC}"
    if command_exists free; then
        free -h | grep -E "^Mem|^Swap" | while read line; do
            echo -e "   ${GRAY}$line${NC}"
        done
    else
        echo -e "   ${GRAY}Memory information not available${NC}"
    fi
    
    # Disk usage
    echo -e "\n${WHITE}💿 Disk Usage:${NC}"
    if command_exists df; then
        df -h | head -1
        df -h | grep -vE '^Filesystem|tmpfs|cdrom|udev' | awk '{print "   " $1 " " $2 " " $3 " " $4 " " $5 " " $6}' | head -5
    else
        echo -e "   ${GRAY}Disk information not available${NC}"
    fi
    
    # Network usage (if vnstat is available)
    if command_exists vnstat; then
        echo -e "\n${WHITE}🌐 Network Usage (Today):${NC}"
        vnstat -d | tail -n 5 | head -n 3 | while read line; do
            echo -e "   ${GRAY}$line${NC}"
        done
    else
        echo -e "\n${WHITE}🌐 Network Usage:${NC}"
        echo -e "   ${GRAY}Install vnstat for detailed network statistics${NC}"
    fi
    
    # Service status
    echo -e "\n${WHITE}🔧 Service Status:${NC}"
    local services=("nginx" "dropbear" "stunnel4" "ssh")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "   ${GREEN}✓${NC} $service: ${GREEN}Running${NC}"
        else
            echo -e "   ${RED}✗${NC} $service: ${RED}Stopped${NC}"
        fi
    done
    
    # User count and status
    if [[ -f "$USERS_DB" ]]; then
        local total_users=$(grep -c "^[^#].*:" "$USERS_DB" 2>/dev/null || echo "0")
        local active_users=$(grep -c ":active:" "$USERS_DB" 2>/dev/null || echo "0")
        local suspended_users=$(grep -c ":suspended:" "$USERS_DB" 2>/dev/null || echo "0")
        local banned_users=$(grep -c ":banned:" "$USERS_DB" 2>/dev/null || echo "0")
        
        echo -e "\n${WHITE}👥 User Statistics:${NC}"
        echo -e "   ${WHITE}Total Users: ${YELLOW}$total_users${NC}"
        echo -e "   ${WHITE}Active: ${GREEN}$active_users${NC} | Suspended: ${YELLOW}$suspended_users${NC} | Banned: ${RED}$banned_users${NC}"
    fi
    
    # Server IP information
    echo -e "\n${WHITE}🌍 Server Information:${NC}"
    local public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "Unknown")
    echo -e "   ${WHITE}Public IP: ${CYAN}$public_ip${NC}"
    
    # Domain information
    local domain=$(get_configured_domain)
    if [[ -n "$domain" ]]; then
        echo -e "   ${WHITE}Configured Domain: ${CYAN}$domain${NC}"
    fi
    
    show_creator_credits
}