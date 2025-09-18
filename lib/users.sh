#!/bin/bash

# JOHN REESE VPS - User Management
# Secure user account management functions

USERS_DB="$DATA_DIR/users.db"
SECRETS_DIR="$DATA_DIR/secrets"

# Initialize user management
init_user_management() {
    mkdir -p "$SECRETS_DIR"
    
    if [[ ! -f "$USERS_DB" ]]; then
        cat > "$USERS_DB" << 'EOF'
# JOHN REESE VPS - User Database
# Format: username:expiry_date:status:protocols:uuid
EOF
    fi
}

# Generate secure random password
generate_password() {
    openssl rand -base64 12 | tr -d "=+/" | cut -c1-12
}

# Generate UUID for protocols
generate_uuid() {
    if command_exists uuidgen; then
        uuidgen
    else
        # Fallback UUID generation
        cat /proc/sys/kernel/random/uuid 2>/dev/null || \
        python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || \
        openssl rand -hex 16 | sed 's/\(..\)/\1-/g; s/.\{3\}$/&-/; s/.\{8\}$/&-/; s/.\{13\}$/&-/'
    fi
}

# Add user
add_user() {
    echo -e "${CYAN}➕ Adding New User${NC}"
    echo -e "${GRAY}─────────────────${NC}"
    
    local username password days expiry_date uuid
    
    prompt_input "Username" username
    prompt_input "Password" password true
    prompt_input "Expiry (days)" days
    
    if [[ -z "$username" || -z "$password" || -z "$days" ]]; then
        log_error "All fields are required"
        return 1
    fi
    
    # Validate username
    if [[ ! "$username" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Username contains invalid characters"
        return 1
    fi
    
    # Check if user already exists
    if grep -q "^$username:" "$USERS_DB"; then
        log_error "User '$username' already exists"
        return 1
    fi
    
    # Calculate expiry date
    expiry_date=$(date -d "+$days days" '+%Y-%m-%d')
    uuid=$(generate_uuid)
    
    # Create system user
    useradd -m -s /bin/bash "$username"
    echo "$username:$password" | chpasswd
    
    # Store user data (no plaintext passwords stored)
    echo "$username:$expiry_date:active:ssh,websocket,ssl,trojan,vmess,vless:$uuid" >> "$USERS_DB"
    
    # Store only non-sensitive data
    mkdir -p "$SECRETS_DIR/$username"
    echo "$uuid" > "$SECRETS_DIR/$username/uuid"
    chmod 600 "$SECRETS_DIR/$username"/*
    
    # Password is only stored in system shadow file via chpasswd above
    
    # Create SSH banner
    create_ssh_banner "$username" "$expiry_date"
    
    # Configure protocols
    configure_user_protocols "$username" "$password" "$uuid"
    
    echo -e "${GREEN}✅ User '$username' created successfully!${NC}"
    echo -e "${CYAN}📋 User Credentials:${NC}"
    echo -e "${WHITE}Username: ${YELLOW}$username${NC}"
    echo -e "${WHITE}Password: ${YELLOW}$password${NC}"
    echo -e "${WHITE}Expires: ${YELLOW}$expiry_date${NC}"
    echo -e "${WHITE}UUID: ${YELLOW}$uuid${NC}"
    echo -e "${WHITE}Protocols: ${YELLOW}SSH, WebSocket, SSL, Trojan, VMESS, VLESS${NC}"
    
    show_creator_credits
    log_success "User '$username' created with expiry $expiry_date"
}

# Remove user
remove_user() {
    echo -e "${RED}❌ Removing User${NC}"
    echo -e "${GRAY}────────────────${NC}"
    
    local username
    prompt_input "Username to remove" username
    
    if [[ -z "$username" ]]; then
        log_error "Username is required"
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$USERS_DB"; then
        log_error "User '$username' not found"
        return 1
    fi
    
    # Remove system user
    userdel -r "$username" 2>/dev/null || true
    
    # Remove from database
    sed -i "/^$username:/d" "$USERS_DB"
    
    # Remove secrets
    rm -rf "$SECRETS_DIR/$username"
    
    # Remove configurations
    remove_user_configs "$username"
    
    echo -e "${GREEN}✅ User '$username' removed successfully!${NC}"
    show_creator_credits
    log_success "User '$username' removed"
}

# Suspend user
suspend_user() {
    echo -e "${YELLOW}🔒 Suspending User${NC}"
    echo -e "${GRAY}───────────────────${NC}"
    
    local username
    prompt_input "Username to suspend" username
    
    if [[ -z "$username" ]]; then
        log_error "Username is required"
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$USERS_DB"; then
        log_error "User '$username' not found"
        return 1
    fi
    
    # Lock system user
    usermod -L "$username"
    
    # Update status in database
    sed -i "s/^$username:\\([^:]*\\):[^:]*:\\(.*\\)$/$username:\\1:suspended:\\2/" "$USERS_DB"
    
    echo -e "${GREEN}✅ User '$username' suspended successfully!${NC}"
    show_creator_credits
    log_success "User '$username' suspended"
}

# Unsuspend user
unsuspend_user() {
    echo -e "${GREEN}🔓 Unsuspending User${NC}"
    echo -e "${GRAY}─────────────────────${NC}"
    
    local username
    prompt_input "Username to unsuspend" username
    
    if [[ -z "$username" ]]; then
        log_error "Username is required"
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$USERS_DB"; then
        log_error "User '$username' not found"
        return 1
    fi
    
    # Unlock system user
    usermod -U "$username"
    
    # Update status in database
    sed -i "s/^$username:\\([^:]*\\):suspended:\\(.*\\)$/$username:\\1:active:\\2/" "$USERS_DB"
    
    echo -e "${GREEN}✅ User '$username' unsuspended successfully!${NC}"
    show_creator_credits
    log_success "User '$username' unsuspended"
}

# Ban user
ban_user() {
    echo -e "${RED}🚫 Banning User${NC}"
    echo -e "${GRAY}──────────────${NC}"
    
    local username
    prompt_input "Username to ban" username
    
    if [[ -z "$username" ]]; then
        log_error "Username is required"
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$USERS_DB"; then
        log_error "User '$username' not found"
        return 1
    fi
    
    # Lock and expire system user
    usermod -L -e 1 "$username"
    
    # Update status in database
    sed -i "s/^$username:\\([^:]*\\):[^:]*:\\(.*\\)$/$username:\\1:banned:\\2/" "$USERS_DB"
    
    echo -e "${GREEN}✅ User '$username' banned successfully!${NC}"
    show_creator_credits
    log_success "User '$username' banned"
}

# Change password
change_password() {
    echo -e "${BLUE}🔑 Changing User Password${NC}"
    echo -e "${GRAY}─────────────────────────${NC}"
    
    local username new_password
    prompt_input "Username" username
    prompt_input "New Password" new_password true
    
    if [[ -z "$username" || -z "$new_password" ]]; then
        log_error "Username and password are required"
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$USERS_DB"; then
        log_error "User '$username' not found"
        return 1
    fi
    
    # Change system password (stored securely in /etc/shadow)
    echo "$username:$new_password" | chpasswd
    
    # No plaintext password storage - only in system shadow file
    
    echo -e "${GREEN}✅ Password changed successfully for user '$username'!${NC}"
    show_creator_credits
    log_success "Password changed for user '$username'"
}

# Renew account
renew_account() {
    echo -e "${PURPLE}♻️ Renewing User Account${NC}"
    echo -e "${GRAY}──────────────────────${NC}"
    
    local username days current_expiry new_expiry
    prompt_input "Username" username
    prompt_input "Extend by (days)" days
    
    if [[ -z "$username" || -z "$days" ]]; then
        log_error "Username and days are required"
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$USERS_DB"; then
        log_error "User '$username' not found"
        return 1
    fi
    
    # Calculate new expiry date
    current_expiry=$(grep "^$username:" "$USERS_DB" | cut -d: -f2)
    if [[ $(date -d "$current_expiry" +%s) -gt $(date +%s) ]]; then
        # Extend from current expiry
        new_expiry=$(date -d "$current_expiry +$days days" '+%Y-%m-%d')
    else
        # Extend from today
        new_expiry=$(date -d "+$days days" '+%Y-%m-%d')
    fi
    
    # Update expiry in database
    sed -i "s/^$username:[^:]*:\\(.*\\)$/$username:$new_expiry:\\1/" "$USERS_DB"
    
    # Update SSH banner
    create_ssh_banner "$username" "$new_expiry"
    
    echo -e "${GREEN}✅ Account renewed successfully for user '$username'!${NC}"
    echo -e "${WHITE}New expiry date: ${YELLOW}$new_expiry${NC}"
    show_creator_credits
    log_success "Account renewed for user '$username', new expiry: $new_expiry"
}

# List all users
list_users() {
    echo -e "${CYAN}👥 All Users${NC}"
    echo -e "${GRAY}───────────${NC}"
    
    if [[ ! -f "$USERS_DB" || ! -s "$USERS_DB" ]]; then
        echo -e "${YELLOW}📝 No users found.${NC}"
        return 0
    fi
    
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║ ${BOLD}Username${NC}${WHITE}     │ ${BOLD}Status${NC}${WHITE}     │ ${BOLD}Expiry Date${NC}${WHITE} │ ${BOLD}Protocols${NC}${WHITE}                    ║${NC}"
    echo -e "${WHITE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    
    while IFS=: read -r username expiry status protocols uuid; do
        if [[ "$username" != "#"* && -n "$username" ]]; then
            # Color code status
            local status_color=""
            case "$status" in
                "active") status_color="${GREEN}$status${NC}" ;;
                "suspended") status_color="${YELLOW}$status${NC}" ;;
                "banned") status_color="${RED}$status${NC}" ;;
                *) status_color="${GRAY}$status${NC}" ;;
            esac
            
            # Check if expired
            local expiry_color="${WHITE}"
            if [[ $(date -d "$expiry" +%s) -lt $(date +%s) ]]; then
                expiry_color="${RED}"
            fi
            
            printf "${WHITE}║ %-12s │ %-10s │ ${expiry_color}%-11s${WHITE} │ %-20s ║${NC}\n" \
                "$username" "$status_color" "$expiry" "$protocols"
        fi
    done < "$USERS_DB"
    
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    show_creator_credits
}

# Check for expired users
check_expired_users() {
    while IFS=: read -r username expiry status protocols uuid; do
        if [[ "$username" != "#"* && -n "$username" && "$status" == "active" ]]; then
            if [[ $(date -d "$expiry" +%s) -lt $(date +%s) ]]; then
                # User expired, suspend them
                usermod -L "$username" 2>/dev/null || true
                sed -i "s/^$username:\\([^:]*\\):active:\\(.*\\)$/$username:\\1:expired:\\2/" "$USERS_DB"
                log_info "User '$username' automatically suspended due to expiry"
            fi
        fi
    done < "$USERS_DB" 2>/dev/null || true
}