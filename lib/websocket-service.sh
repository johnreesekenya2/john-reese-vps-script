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
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        bridge_method="nodejs"
        setup_nodejs_bridge || {
            log_error "Failed to setup Node.js WebSocket bridge"
            return 1
        }
    elif command -v python3 >/dev/null 2>&1; then
        bridge_method="python"
        setup_python_bridge || {
            log_error "Failed to setup Python WebSocket bridge"
            return 1
        }
    else
        echo -e "${YELLOW}⚠️ Neither Node.js/npm nor Python3 found, installing Python3...${NC}"
        install_system_packages python3 python3-pip python3-venv
        bridge_method="python"
        setup_python_bridge || {
            log_error "Failed to setup Python WebSocket bridge after installation"
            return 1
        }
    fi
    
    # Create systemd service
    create_websocket_service "$bridge_method" || {
        log_error "Failed to create WebSocket bridge service"
        return 1
    }
    
    # Start the service
    start_websocket_bridge || {
        log_error "Failed to start WebSocket bridge service"
        return 1
    }
    
    log_success "WebSocket bridge configured using $bridge_method"
}

# Ensure Python and pip are available
ensure_python_and_pip() {
    echo -e "${BLUE}🔧 Ensuring Python and pip are available...${NC}"
    
    # Find Python3 executable (explicitly require Python 3)
    PYTHON_CMD=$(command -v python3 || true)
    
    if [ -z "$PYTHON_CMD" ]; then
        echo -e "${YELLOW}⚠️ Python not found, installing...${NC}"
        install_system_packages python3
        PYTHON_CMD=$(command -v python3)
    fi
    
    echo -e "${GREEN}✅ Python found: $PYTHON_CMD${NC}"
    
    # Ensure curl or wget is available for potential get-pip fallback
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        echo -e "${YELLOW}📦 Installing curl for get-pip fallback...${NC}"
        install_system_packages curl
    fi
    
    # Verify pip is available via python -m pip
    if ! $PYTHON_CMD -m pip --version >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ pip not available, installing...${NC}"
        
        # Try installing pip via package manager
        install_system_packages python3-pip python3-venv || true
        
        # If still not available, try to bootstrap with get-pip.py
        if ! $PYTHON_CMD -m pip --version >/dev/null 2>&1; then
            echo -e "${YELLOW}📥 Bootstrapping pip with get-pip.py...${NC}"
            curl -s https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py || wget -q https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py
            $PYTHON_CMD /tmp/get-pip.py --quiet
            rm -f /tmp/get-pip.py
        fi
    fi
    
    if $PYTHON_CMD -m pip --version >/dev/null 2>&1; then
        echo -e "${GREEN}✅ pip is available via python -m pip${NC}"
    else
        echo -e "${RED}❌ Failed to install pip${NC}"
        return 1
    fi
    
    # Create virtual environment directory
    mkdir -p /opt/websocket-bridge
    
    # Ensure python3-venv is available before creating virtual environment
    if ! $PYTHON_CMD -m venv --help >/dev/null 2>&1; then
        echo -e "${YELLOW}📦 Installing python3-venv...${NC}"
        install_system_packages python3-venv
    fi
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "/opt/websocket-bridge/venv" ]; then
        echo -e "${BLUE}🐍 Creating virtual environment...${NC}"
        $PYTHON_CMD -m venv /opt/websocket-bridge/venv || {
            echo -e "${YELLOW}⚠️ Standard venv creation failed, trying --without-pip...${NC}"
            $PYTHON_CMD -m venv --without-pip /opt/websocket-bridge/venv || {
                echo -e "${RED}❌ Failed to create virtual environment${NC}"
                return 1
            }
            # Manually install pip in the venv
            echo -e "${YELLOW}📥 Installing pip in virtual environment...${NC}"
            curl -s https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py || wget -q https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py
            /opt/websocket-bridge/venv/bin/python /tmp/get-pip.py --quiet
            rm -f /tmp/get-pip.py
        }
        
        # Verify virtual environment was created successfully
        if [ ! -f "/opt/websocket-bridge/venv/bin/python" ]; then
            echo -e "${RED}❌ Virtual environment creation failed${NC}"
            return 1
        fi
        
        echo -e "${GREEN}✅ Virtual environment created${NC}"
    fi
    
    return 0
}

# Setup Node.js WebSocket bridge
setup_nodejs_bridge() {
    echo -e "${BLUE}📦 Setting up Node.js WebSocket bridge...${NC}"
    
    # Verify npm is available
    if ! npm --version >/dev/null 2>&1; then
        echo -e "${RED}❌ npm not available${NC}"
        return 1
    fi
    
    # Create Node.js app directory
    mkdir -p /opt/websocket-bridge || {
        echo -e "${RED}❌ Failed to create /opt/websocket-bridge directory${NC}"
        return 1
    }
    
    # Install the bridge script to /opt
    install -D -m 755 "$SCRIPT_DIR/lib/websocket-bridge.js" "/opt/websocket-bridge/websocket-bridge.js" || {
        echo -e "${RED}❌ Failed to install bridge script${NC}"
        return 1
    }
    
    # Install Node.js WebSocket library in deterministic location
    echo -e "${BLUE}📦 Installing ws library...${NC}"
    cd /opt/websocket-bridge
    npm install ws --silent || {
        echo -e "${RED}❌ Failed to install ws library via npm${NC}"
        return 1
    }
    
    # Verify installation
    if node -e "require('ws')" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ ws library installed successfully${NC}"
    else
        echo -e "${RED}❌ Failed to import ws library${NC}"
        return 1
    fi
    
    # Create wrapper script with absolute paths
    cat > "/usr/local/bin/websocket-bridge" << 'EOF'
#!/bin/bash
# John Reese VPS WebSocket Bridge Wrapper
cd /opt/websocket-bridge
exec node /opt/websocket-bridge/websocket-bridge.js
EOF
    
    chmod +x "/usr/local/bin/websocket-bridge" || {
        echo -e "${RED}❌ Failed to make wrapper script executable${NC}"
        return 1
    }
    
    echo -e "${GREEN}✅ Node.js WebSocket bridge setup complete${NC}"
    return 0
}

# Setup Python WebSocket bridge
setup_python_bridge() {
    echo -e "${BLUE}📦 Setting up Python WebSocket bridge...${NC}"
    
    # Ensure Python and pip are available
    ensure_python_and_pip || {
        echo -e "${RED}❌ Failed to setup Python environment${NC}"
        return 1
    }
    
    # Install the bridge script to /opt
    install -D -m 755 "$SCRIPT_DIR/lib/websocket-bridge.py" "/opt/websocket-bridge/websocket-bridge.py"
    
    # Upgrade pip and install websockets in virtual environment
    echo -e "${BLUE}📦 Installing websockets library in virtual environment...${NC}"
    /opt/websocket-bridge/venv/bin/python -m pip install --upgrade pip --quiet
    /opt/websocket-bridge/venv/bin/python -m pip install websockets --quiet
    
    # Verify installation
    if /opt/websocket-bridge/venv/bin/python -c "import websockets; print('websockets version:', websockets.__version__)" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ websockets library installed successfully${NC}"
    else
        echo -e "${RED}❌ Failed to install websockets library${NC}"
        return 1
    fi
    
    # Create wrapper script with absolute paths
    cat > "/usr/local/bin/websocket-bridge" << 'EOF'
#!/bin/bash
# John Reese VPS WebSocket Bridge Wrapper
exec /opt/websocket-bridge/venv/bin/python /opt/websocket-bridge/websocket-bridge.py
EOF
    
    chmod +x "/usr/local/bin/websocket-bridge"
    
    echo -e "${GREEN}✅ Python WebSocket bridge setup complete${NC}"
}

# Create systemd service for WebSocket bridge
create_websocket_service() {
    local bridge_method="$1"
    
    # Create the base service configuration
    cat > "/etc/systemd/system/websocket-bridge.service" << EOF
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
EOF

    # Add working directory only for Python bridge
    if [ "$bridge_method" = "python" ]; then
        echo "" >> "/etc/systemd/system/websocket-bridge.service"
        echo "# Working directory" >> "/etc/systemd/system/websocket-bridge.service"
        echo "WorkingDirectory=/opt/websocket-bridge" >> "/etc/systemd/system/websocket-bridge.service"
    fi
    
    # Add the rest of the configuration
    cat >> "/etc/systemd/system/websocket-bridge.service" << 'EOF'

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