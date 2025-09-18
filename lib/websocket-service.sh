#!/bin/bash

# JOHN REESE VPS - WebSocket Bridge Service Management
# Manages the WebSocket to SSH bridge service

BRIDGE_PORT=3000
SSH_HOST="127.0.0.1"
SSH_PORT=2222

# Install WebSocket bridge dependencies and setup service
setup_websocket_bridge() {
    echo -e "${BLUE}🌐 Setting up WebSocket to SSH bridge...${NC}"
    
    local bridge_method=""
    
    # Determine which bridge to use based on available runtime
    if command -v node >/dev/null 2>&1; then
        bridge_method="nodejs"
        setup_nodejs_bridge
    elif command -v python3 >/dev/null 2>&1; then
        bridge_method="python"
        setup_python_bridge
    else
        echo -e "${YELLOW}⚠️ Neither Node.js nor Python3 found, installing Python3...${NC}"
        install_system_packages python3 python3-pip
        bridge_method="python"
        setup_python_bridge
    fi
    
    # Create systemd service
    create_websocket_service "$bridge_method"
    
    # Start the service
    start_websocket_bridge
    
    log_success "WebSocket bridge configured using $bridge_method"
}

# Setup Node.js WebSocket bridge
setup_nodejs_bridge() {
    echo -e "${BLUE}📦 Setting up Node.js WebSocket bridge...${NC}"
    
    # Install Node.js WebSocket library
    if ! npm list ws >/dev/null 2>&1; then
        npm install ws
    fi
    
    # Make the bridge executable
    chmod +x "$SCRIPT_DIR/lib/websocket-bridge.js"
    
    # Create wrapper script
    cat > "/usr/local/bin/websocket-bridge" << 'EOF'
#!/bin/bash
export WS_PORT=3000
export SSH_HOST=127.0.0.1
export SSH_PORT=2222
cd "$(dirname "$0")"
exec node "SCRIPT_DIR_PLACEHOLDER/lib/websocket-bridge.js"
EOF
    
    # Replace placeholder
    sed -i "s|SCRIPT_DIR_PLACEHOLDER|$SCRIPT_DIR|g" "/usr/local/bin/websocket-bridge"
    chmod +x "/usr/local/bin/websocket-bridge"
}

# Setup Python WebSocket bridge
setup_python_bridge() {
    echo -e "${BLUE}📦 Setting up Python WebSocket bridge...${NC}"
    
    # Install Python WebSocket library
    pip3 install websockets >/dev/null 2>&1 || {
        echo -e "${YELLOW}Installing websockets library...${NC}"
        pip3 install websockets
    }
    
    # Make the bridge executable
    chmod +x "$SCRIPT_DIR/lib/websocket-bridge.py"
    
    # Create wrapper script
    cat > "/usr/local/bin/websocket-bridge" << 'EOF'
#!/bin/bash
export WS_PORT=3000
export SSH_HOST=127.0.0.1
export SSH_PORT=2222
cd "$(dirname "$0")"
exec python3 "SCRIPT_DIR_PLACEHOLDER/lib/websocket-bridge.py"
EOF
    
    # Replace placeholder
    sed -i "s|SCRIPT_DIR_PLACEHOLDER|$SCRIPT_DIR|g" "/usr/local/bin/websocket-bridge"
    chmod +x "/usr/local/bin/websocket-bridge"
}

# Create systemd service for WebSocket bridge
create_websocket_service() {
    local bridge_method="$1"
    
    cat > "/etc/systemd/system/websocket-bridge.service" << 'EOF'
[Unit]
Description=John Reese VPS WebSocket to SSH Bridge
After=network.target
Wants=dropbear.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/websocket-bridge
Restart=always
RestartSec=5
Environment=WS_PORT=3000
Environment=SSH_HOST=127.0.0.1
Environment=SSH_PORT=2222

# Security settings
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=websocket-bridge

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable websocket-bridge.service
}

# Start WebSocket bridge service
start_websocket_bridge() {
    echo -e "${BLUE}🚀 Starting WebSocket bridge service...${NC}"
    
    systemctl start websocket-bridge.service
    sleep 2
    
    if systemctl is-active --quiet websocket-bridge.service; then
        echo -e "${GREEN}✅ WebSocket bridge service started successfully${NC}"
        log_success "WebSocket bridge service started"
        
        # Test the bridge
        test_websocket_bridge
    else
        echo -e "${RED}❌ WebSocket bridge service failed to start${NC}"
        systemctl status websocket-bridge.service
        log_error "WebSocket bridge service failed to start"
        return 1
    fi
}

# Test WebSocket bridge connectivity
test_websocket_bridge() {
    echo -e "${BLUE}🔍 Testing WebSocket bridge connectivity...${NC}"
    
    # Test if bridge port is listening
    if ss -tlnp | grep -q ":3000 "; then
        echo -e "${GREEN}✅ WebSocket bridge is listening on port 3000${NC}"
    else
        echo -e "${YELLOW}⚠️ WebSocket bridge port not detected${NC}"
    fi
    
    # Test if SSH target is reachable
    if nc -z 127.0.0.1 2222 2>/dev/null; then
        echo -e "${GREEN}✅ SSH service is reachable on port 2222${NC}"
    else
        echo -e "${YELLOW}⚠️ SSH service on port 2222 not reachable${NC}"
    fi
}

# Stop WebSocket bridge service
stop_websocket_bridge() {
    if systemctl is-active --quiet websocket-bridge.service; then
        systemctl stop websocket-bridge.service
        log_info "WebSocket bridge service stopped"
    fi
}

# Remove WebSocket bridge service
remove_websocket_bridge() {
    stop_websocket_bridge
    systemctl disable websocket-bridge.service 2>/dev/null || true
    rm -f /etc/systemd/system/websocket-bridge.service
    rm -f /usr/local/bin/websocket-bridge
    systemctl daemon-reload
    log_info "WebSocket bridge service removed"
}

# Get WebSocket bridge status
get_websocket_bridge_status() {
    if systemctl is-active --quiet websocket-bridge.service; then
        echo "✅ WebSocket Bridge: Running"
        local pid=$(systemctl show -p MainPID --value websocket-bridge.service)
        echo "   PID: $pid"
        echo "   Port: 3000"
    else
        echo "❌ WebSocket Bridge: Stopped"
    fi
}