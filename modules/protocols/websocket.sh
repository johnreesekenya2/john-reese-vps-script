#!/bin/bash

# JOHN REESE VPS - WebSocket Protocol Configuration
# WebSocket over HTTP/HTTPS configuration

# Configure WebSocket for user
configure_websocket() {
    local username="$1"
    
    # WebSocket configuration is handled by the main NGINX configuration
    # User-specific paths can be added here if needed
    
    local config_file="$DATA_DIR/configs/websocket_$username.conf"
    
    cat > "$config_file" << EOF
# WebSocket configuration for $username
# Path: /ws-$username
# Protocol: WebSocket over HTTP/HTTPS
# Target: SSH on port 22

upstream ssh_backend_$username {
    server 127.0.0.1:22;
}

# This configuration can be included in NGINX if per-user paths are needed
location /ws-$username {
    proxy_pass http://ssh_backend_$username;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
    
    # Custom handshake response for this user
    add_header X-WebSocket-Protocol "HTTP 101 Switching Protocols - KENYAN JOHN REESE PRIME";
    add_header X-User-Path "/ws-$username";
}
EOF
    
    log_success "WebSocket configured for user $username"
}