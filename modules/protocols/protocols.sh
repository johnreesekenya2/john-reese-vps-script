#!/bin/bash

# JOHN REESE VPS - Protocol Coordination
# Main protocol configuration coordination

# Source all protocol modules
source "$SCRIPT_DIR/modules/protocols/ssh.sh"
source "$SCRIPT_DIR/modules/protocols/websocket.sh"  
source "$SCRIPT_DIR/modules/protocols/xray.sh"

# Configure all protocols for a user
configure_user_protocols() {
    local username="$1"
    local password="$2"
    local uuid="$3"
    
    echo -e "${BLUE}🔧 Configuring protocols for user $username...${NC}"
    
    # Configure SSH (automatic with system user creation)
    configure_ssh "$username" "$password"
    
    # Configure WebSocket
    configure_websocket "$username"
    
    # Configure Xray protocols (VMESS, VLESS, Trojan)
    configure_vmess "$username" "$uuid"
    configure_vless "$username" "$uuid" 
    configure_trojan "$username" "$password"
    
    log_success "All protocols configured for user $username"
}

# Remove all protocol configurations for a user
remove_user_configs() {
    local username="$1"
    
    echo -e "${BLUE}🧹 Removing protocol configurations for user $username...${NC}"
    
    # Remove SSH banner
    remove_ssh_banner "$username"
    
    # Remove WebSocket config
    rm -f "$DATA_DIR/configs/websocket_$username.conf"
    
    # Remove from Xray protocols
    remove_user_xray "$username"
    
    # Remove any other user-specific configs
    rm -f "$DATA_DIR/configs/"*"_$username"*
    
    log_success "All configurations removed for user $username"
}

# Initialize all protocol configurations
init_protocol_configs() {
    echo -e "${BLUE}🔧 Initializing protocol configurations...${NC}"
    
    # Initialize Xray configurations
    init_xray_configs
    
    # Start Xray service
    start_xray_service
    
    log_success "Protocol configurations initialized"
}