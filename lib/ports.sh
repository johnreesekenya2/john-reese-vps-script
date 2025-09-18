#!/bin/bash

# JOHN REESE VPS - Port Management
# Centralized port registry and conflict detection

PORT_REGISTRY="$DATA_DIR/ports.conf"

# Initialize port registry
init_port_registry() {
    cat > "$PORT_REGISTRY" << 'EOF'
# JOHN REESE VPS - Port Registry
# Format: service:port:protocol:status

ssh:22:tcp:system
nginx_http:80:tcp:active
nginx_https:443:tcp:active
dropbear:2222:tcp:active
stunnel_ssl:8443:tcp:active
xray_vmess:10001:tcp:active
xray_vless:10002:tcp:active  
xray_trojan:10003:tcp:active
EOF

    log_success "Port registry initialized"
}

# Check if port is available
check_port_available() {
    local port="$1"
    local protocol="${2:-tcp}"
    
    # Check if port is in use by system
    if netstat -ln | grep -q ":$port "; then
        return 1
    fi
    
    # Check if port is reserved in registry
    if grep -q ":$port:$protocol:" "$PORT_REGISTRY"; then
        return 1
    fi
    
    return 0
}

# Reserve port in registry
reserve_port() {
    local service="$1"
    local port="$2"
    local protocol="${3:-tcp}"
    local status="${4:-active}"
    
    if check_port_available "$port" "$protocol"; then
        echo "$service:$port:$protocol:$status" >> "$PORT_REGISTRY"
        log_success "Port $port reserved for $service"
        return 0
    else
        log_error "Port $port already in use"
        return 1
    fi
}

# Release port from registry
release_port() {
    local port="$1"
    local protocol="${2:-tcp}"
    
    sed -i "/:$port:$protocol:/d" "$PORT_REGISTRY"
    log_info "Port $port released"
}

# Show port registry
show_port_registry() {
    echo -e "${CYAN}🔌 Port Registry${NC}"
    echo -e "${GRAY}──────────────${NC}"
    echo -e "${WHITE}Service          Port    Protocol Status${NC}"
    echo -e "${GRAY}──────────────────────────────────────${NC}"
    
    while IFS=: read -r service port protocol status; do
        if [[ "$service" != "#"* && -n "$service" ]]; then
            local status_color=""
            case "$status" in
                "active") status_color="${GREEN}$status${NC}" ;;
                "inactive") status_color="${RED}$status${NC}" ;;
                "system") status_color="${YELLOW}$status${NC}" ;;
                *) status_color="${GRAY}$status${NC}" ;;
            esac
            
            printf "%-15s %-7s %-8s %s\n" "$service" "$port" "$protocol" "$status_color"
        fi
    done < "$PORT_REGISTRY"
}