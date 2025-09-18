#!/bin/bash

# JOHN REESE VPS - Service Management
# Centralized service orchestration and management

# Initialize directories
init_directories() {
    mkdir -p "$DATA_DIR"
    mkdir -p "$DATA_DIR/configs"
    mkdir -p "$DATA_DIR/logs"
    mkdir -p "$DATA_DIR/secrets"
    mkdir -p "$DATA_DIR/templates"
    
    init_logging
    init_user_management
    init_port_registry
    
    log_success "Directories initialized"
}

# Install required packages
install_packages() {
    echo -e "${BLUE}📦 Installing required packages...${NC}"
    
    local packages
    case "$DETECTED_OS" in
        "ubuntu"|"debian")
            packages=(
                "nginx" "dropbear" "stunnel4" "openssl" "iptables" 
                "certbot" "wget" "curl" "jq" "net-tools" "uuid-runtime"
            )
            ;;
        "termux")
            packages=(
                "nginx" "dropbear" "stunnel" "openssl" "iptables" 
                "wget" "curl" "jq" "net-tools"
            )
            ;;
        *)
            log_error "Unsupported system: $DETECTED_OS"
            exit 1
            ;;
    esac
    
    install_system_packages "${packages[@]}"
    
    # Install Xray-core
    install_xray
    
    log_success "All packages installed"
}

# Install Xray-core
install_xray() {
    echo -e "${BLUE}🚀 Installing Xray-core...${NC}"
    
    if [[ "$DETECTED_OS" == "termux" ]]; then
        # Termux installation
        local arch=$(uname -m)
        case "$arch" in
            "aarch64") arch="arm64" ;;
            "armv7l") arch="arm32" ;;
            *) arch="64" ;;
        esac
        
        wget -O /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-android-${arch}.zip"
        unzip /tmp/xray.zip -d /data/data/com.termux/files/usr/bin/
        chmod +x /data/data/com.termux/files/usr/bin/xray
        rm /tmp/xray.zip
    else
        # Ubuntu/Debian installation
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    fi
    
    log_success "Xray-core installed"
}

# Setup all services
setup_services() {
    echo -e "${BLUE}🔧 Setting up services...${NC}"
    
    # Generate SSL certificate
    generate_ssl_certificate
    
    # Configure services
    configure_nginx
    configure_dropbear
    configure_stunnel
    configure_xray_base
    
    # Enable and start services
    enable_services
    
    log_success "All services configured and started"
}

# Generate SSL certificate
generate_ssl_certificate() {
    local cert_path="/etc/ssl/certs/john-reese.crt"
    local key_path="/etc/ssl/private/john-reese.key"
    
    if [[ ! -f "$cert_path" ]]; then
        echo -e "${BLUE}🔐 Generating SSL certificate...${NC}"
        
        mkdir -p /etc/ssl/certs /etc/ssl/private
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$key_path" \
            -out "$cert_path" \
            -subj "/C=UK/ST=London/L=London/O=John Reese VPS/CN=johnreese.vps" \
            2>/dev/null
            
        chmod 600 "$key_path"
        chmod 644 "$cert_path"
        
        log_success "SSL certificate generated"
    fi
}

# Configure NGINX
configure_nginx() {
    local config_file="/etc/nginx/sites-available/john-reese-default"
    
    cat > "$config_file" << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    
    # WebSocket upgrade header
    location / {
        if ($http_upgrade = websocket) {
            return 301 https://$host$request_uri;
        }
        
        # Default response with custom header
        add_header X-Protocol "HTTP 101 Switching Protocols - KENYAN JOHN REESE PRIME";
        return 200 "JOHN REESE VPS - WebSocket Ready\n";
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "OK";
        add_header Content-Type text/plain;
    }
}

server {
    listen 443 ssl http2 default_server;
    server_name _;
    
    ssl_certificate /etc/ssl/certs/john-reese.crt;
    ssl_certificate_key /etc/ssl/private/john-reese.key;
    
    # SSL optimizations
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    location / {
        # WebSocket proxy to SSH (Dropbear on 2222)
        proxy_pass http://127.0.0.1:2222;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Custom handshake response
        add_header X-WebSocket-Protocol "HTTP 101 Switching Protocols - KENYAN JOHN REESE PRIME";
    }
}
EOF
    
    # Enable the site
    ln -sf "$config_file" /etc/nginx/sites-enabled/john-reese-default
    rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration and reload
    if nginx -t; then
        systemctl reload nginx 2>/dev/null || true
        log_success "NGINX configured and reloaded"
    else
        log_error "NGINX configuration test failed"
        return 1
    fi
}

# Configure Dropbear
configure_dropbear() {
    local config_file="/etc/default/dropbear"
    
    # Configure Dropbear options
    cat > "$config_file" << 'EOF'
# Dropbear SSH server configuration
NO_START=0
DROPBEAR_PORT=2222
DROPBEAR_EXTRA_ARGS="-w -s -g"
DROPBEAR_BANNER="/etc/dropbear/banner"
DROPBEAR_RSAKEY="/etc/dropbear/dropbear_rsa_host_key"
DROPBEAR_DSSKEY="/etc/dropbear/dropbear_dss_host_key"
DROPBEAR_ECDSAKEY="/etc/dropbear/dropbear_ecdsa_host_key"
EOF
    
    # Generate host keys if they don't exist
    mkdir -p /etc/dropbear
    [[ ! -f /etc/dropbear/dropbear_rsa_host_key ]] && dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
    [[ ! -f /etc/dropbear/dropbear_dss_host_key ]] && dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
    [[ ! -f /etc/dropbear/dropbear_ecdsa_host_key ]] && dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key
    
    log_success "Dropbear configured"
}

# Configure Stunnel
configure_stunnel() {
    local config_file="/etc/stunnel/john-reese.conf"
    
    mkdir -p /etc/stunnel
    
    cat > "$config_file" << 'EOF'
; JOHN REESE VPS - Stunnel Configuration
cert = /etc/ssl/certs/john-reese.crt
key = /etc/ssl/private/john-reese.key
pid = /var/run/stunnel4/john-reese.pid

[ssh-ssl]
accept = 8443
connect = 127.0.0.1:2222
EOF
    
    # Configure stunnel service
    if [[ "$DETECTED_OS" != "termux" ]]; then
        systemctl enable stunnel4
    fi
    
    log_success "Stunnel configured"
}

# Configure base Xray configuration
configure_xray_base() {
    local config_file="$DATA_DIR/configs/xray-base.json"
    
    cat > "$config_file" << 'EOF'
{
    "log": {
        "loglevel": "warning",
        "access": "/var/log/xray-access.log",
        "error": "/var/log/xray-error.log"
    },
    "inbounds": [],
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
    
    log_success "Base Xray configuration created"
}

# Enable and start services
enable_services() {
    local services=("nginx")
    
    # Add services based on OS
    if [[ "$DETECTED_OS" != "termux" ]]; then
        services+=("dropbear" "stunnel4" "ssh")
    fi
    
    for service in "${services[@]}"; do
        if service_exists "$service"; then
            systemctl enable "$service" 2>/dev/null || true
            systemctl start "$service" 2>/dev/null || true
            
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                log_success "Service $service started"
            else
                log_warn "Service $service failed to start"
            fi
        else
            log_warn "Service $service not found"
        fi
    done
}

# Remove services
remove_services() {
    echo -e "${RED}🛑 Stopping and removing services...${NC}"
    
    local services=("nginx" "dropbear" "stunnel4")
    
    for service in "${services[@]}"; do
        if service_exists "$service"; then
            systemctl stop "$service" 2>/dev/null || true
            systemctl disable "$service" 2>/dev/null || true
            log_info "Service $service stopped and disabled"
        fi
    done
    
    # Remove Xray
    if command_exists xray; then
        pkill -f xray 2>/dev/null || true
        log_info "Xray processes terminated"
    fi
}

# Cleanup files
cleanup_files() {
    echo -e "${RED}🗑️ Cleaning up files...${NC}"
    
    # Remove data directory
    rm -rf "$DATA_DIR"
    
    # Remove log file
    rm -f "$LOG_FILE"
    
    # Remove NGINX configurations
    rm -f /etc/nginx/sites-available/john-reese-*
    rm -f /etc/nginx/sites-enabled/john-reese-*
    
    # Remove SSL certificates
    rm -f /etc/ssl/certs/john-reese.crt
    rm -f /etc/ssl/private/john-reese.key
    
    # Remove menu commands
    rm -f /usr/local/bin/menu
    rm -f /usr/local/bin/.menu
    
    log_info "Cleanup completed"
}