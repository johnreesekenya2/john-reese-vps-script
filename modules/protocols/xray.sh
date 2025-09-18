#!/bin/bash

# JOHN REESE VPS - Xray Protocol Configuration  
# VMESS, VLESS, and Trojan protocol management via Xray-core

XRAY_CONFIG="$DATA_DIR/configs/xray-main.json"
VMESS_USERS="$DATA_DIR/vmess_users.json"
VLESS_USERS="$DATA_DIR/vless_users.json"
TROJAN_USERS="$DATA_DIR/trojan_users.json"

# Initialize Xray configurations
init_xray_configs() {
    mkdir -p "$DATA_DIR/configs"
    
    # Create main Xray configuration
    create_main_xray_config
    
    # Initialize user databases
    echo "[]" > "$VMESS_USERS"
    echo "[]" > "$VLESS_USERS" 
    echo "[]" > "$TROJAN_USERS"
    
    log_success "Xray configurations initialized"
}

# Create main Xray configuration
create_main_xray_config() {
    cat > "$XRAY_CONFIG" << 'EOF'
{
    "log": {
        "loglevel": "warning",
        "access": "/var/log/xray-access.log",
        "error": "/var/log/xray-error.log"
    },
    "inbounds": [
        {
            "port": 10001,
            "protocol": "vmess",
            "settings": {
                "clients": []
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/vmess"
                }
            },
            "tag": "vmess-in"
        },
        {
            "port": 10002,
            "protocol": "vless",
            "settings": {
                "clients": [],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/vless"
                }
            },
            "tag": "vless-in"
        },
        {
            "port": 10003,
            "protocol": "trojan",
            "settings": {
                "clients": []
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none"
            },
            "tag": "trojan-in"
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {},
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "settings": {},
            "tag": "blocked"
        }
    ],
    "routing": {
        "rules": [
            {
                "type": "field",
                "ip": ["geoip:private"],
                "outboundTag": "blocked"
            }
        ]
    }
}
EOF
}

# Configure VMESS for user
configure_vmess() {
    local username="$1"
    local uuid="$2"
    
    # Add user to VMESS clients
    add_vmess_client "$username" "$uuid"
    
    # Update main Xray config
    update_xray_config
    
    log_success "VMESS configured for user $username"
}

# Configure VLESS for user
configure_vless() {
    local username="$1"
    local uuid="$2"
    
    # Add user to VLESS clients
    add_vless_client "$username" "$uuid"
    
    # Update main Xray config
    update_xray_config
    
    log_success "VLESS configured for user $username"
}

# Configure Trojan for user
configure_trojan() {
    local username="$1"
    local password="$2"
    
    # Add user to Trojan clients
    add_trojan_client "$username" "$password"
    
    # Update main Xray config
    update_xray_config
    
    log_success "Trojan configured for user $username"
}

# Add VMESS client
add_vmess_client() {
    local username="$1"
    local uuid="$2"
    
    local client_data=$(cat << EOF
{
    "id": "$uuid",
    "level": 1,
    "alterId": 0,
    "email": "$username@johnreese.vps"
}
EOF
)
    
    # Add to users database
    jq --argjson client "$client_data" '. += [$client]' "$VMESS_USERS" > "$VMESS_USERS.tmp" && mv "$VMESS_USERS.tmp" "$VMESS_USERS"
}

# Add VLESS client
add_vless_client() {
    local username="$1"
    local uuid="$2"
    
    local client_data=$(cat << EOF
{
    "id": "$uuid",
    "level": 0,
    "email": "$username@johnreese.vps"
}
EOF
)
    
    # Add to users database
    jq --argjson client "$client_data" '. += [$client]' "$VLESS_USERS" > "$VLESS_USERS.tmp" && mv "$VLESS_USERS.tmp" "$VLESS_USERS"
}

# Add Trojan client
add_trojan_client() {
    local username="$1"
    local password="$2"
    
    local client_data=$(cat << EOF
{
    "password": "$password",
    "email": "$username@johnreese.vps"
}
EOF
)
    
    # Add to users database
    jq --argjson client "$client_data" '. += [$client]' "$TROJAN_USERS" > "$TROJAN_USERS.tmp" && mv "$TROJAN_USERS.tmp" "$TROJAN_USERS"
}

# Update Xray main configuration with current users
update_xray_config() {
    local temp_config="/tmp/xray-config.json"
    
    # Read current config
    cp "$XRAY_CONFIG" "$temp_config"
    
    # Update VMESS clients
    jq --slurpfile vmess_clients "$VMESS_USERS" \
       '.inbounds[0].settings.clients = $vmess_clients' "$temp_config" > "$temp_config.1" && mv "$temp_config.1" "$temp_config"
    
    # Update VLESS clients
    jq --slurpfile vless_clients "$VLESS_USERS" \
       '.inbounds[1].settings.clients = $vless_clients' "$temp_config" > "$temp_config.2" && mv "$temp_config.2" "$temp_config"
    
    # Update Trojan clients
    jq --slurpfile trojan_clients "$TROJAN_USERS" \
       '.inbounds[2].settings.clients = $trojan_clients' "$temp_config" > "$temp_config.3" && mv "$temp_config.3" "$temp_config"
    
    # Move to final location
    mv "$temp_config" "$XRAY_CONFIG"
    
    # Restart Xray service
    restart_xray_service
}

# Remove user from all Xray protocols
remove_user_xray() {
    local username="$1"
    
    # Remove from VMESS
    jq --arg email "$username@johnreese.vps" 'map(select(.email != $email))' "$VMESS_USERS" > "$VMESS_USERS.tmp" && mv "$VMESS_USERS.tmp" "$VMESS_USERS"
    
    # Remove from VLESS
    jq --arg email "$username@johnreese.vps" 'map(select(.email != $email))' "$VLESS_USERS" > "$VLESS_USERS.tmp" && mv "$VLESS_USERS.tmp" "$VLESS_USERS"
    
    # Remove from Trojan
    jq --arg email "$username@johnreese.vps" 'map(select(.email != $email))' "$TROJAN_USERS" > "$TROJAN_USERS.tmp" && mv "$TROJAN_USERS.tmp" "$TROJAN_USERS"
    
    # Update main config
    update_xray_config
    
    log_success "User $username removed from all Xray protocols"
}

# Start Xray service
start_xray_service() {
    if command_exists xray; then
        # Kill existing Xray processes
        pkill -f xray 2>/dev/null || true
        
        # Start Xray with our configuration
        nohup xray -config "$XRAY_CONFIG" > /var/log/xray-service.log 2>&1 &
        
        local xray_pid=$!
        echo "$xray_pid" > "$DATA_DIR/xray.pid"
        
        log_success "Xray service started with PID $xray_pid"
    else
        log_error "Xray binary not found"
        return 1
    fi
}

# Restart Xray service
restart_xray_service() {
    stop_xray_service
    sleep 2
    start_xray_service
}

# Stop Xray service
stop_xray_service() {
    if [[ -f "$DATA_DIR/xray.pid" ]]; then
        local pid=$(cat "$DATA_DIR/xray.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_info "Xray service stopped (PID $pid)"
        fi
        rm -f "$DATA_DIR/xray.pid"
    fi
    
    # Fallback: kill all xray processes
    pkill -f xray 2>/dev/null || true
}