#!/bin/bash

# JOHN REESE VPS - Domain Management
# SSL certificate and domain configuration

DOMAIN_CONFIG="$DATA_DIR/domain.conf"

# Add domain
add_domain() {
    echo -e "${BLUE}🌐 Adding Domain${NC}"
    echo -e "${GRAY}──────────────${NC}"
    
    local domain
    prompt_input "Domain name" domain
    
    if [[ -z "$domain" ]]; then
        log_error "Domain name is required"
        return 1
    fi
    
    # Validate domain format
    if [[ ! "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Invalid domain format"
        return 1
    fi
    
    # Store domain configuration
    echo "DOMAIN=$domain" > "$DOMAIN_CONFIG"
    echo "SSL_METHOD=letsencrypt" >> "$DOMAIN_CONFIG"
    echo "CONFIGURED_DATE=$(date)" >> "$DOMAIN_CONFIG"
    
    # Configure NGINX for domain
    configure_domain_nginx "$domain"
    
    echo -e "${GREEN}✅ Domain '$domain' added successfully!${NC}"
    echo -e "${WHITE}Remember to point your domain DNS to this server's IP address.${NC}"
    echo -e "${WHITE}You can now run 'Renew SSL Certificate' to get a valid SSL certificate.${NC}"
    
    show_creator_credits
    log_success "Domain '$domain' configured"
}

# Configure NGINX for specific domain
configure_domain_nginx() {
    local domain="$1"
    local config_file="/etc/nginx/sites-available/john-reese-$domain"
    
    cat > "$config_file" << EOF
server {
    listen 80;
    server_name $domain;
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # WebSocket upgrade with custom header
    location /ws {
        if (\$http_upgrade = websocket) {
            proxy_pass http://127.0.0.1:2222;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            add_header X-WebSocket-Protocol "HTTP 101 Switching Protocols - KENYAN JOHN REESE PRIME";
        }
        return 426 "Upgrade Required";
    }
}

server {
    listen 443 ssl http2;
    server_name $domain;
    
    ssl_certificate /etc/ssl/certs/john-reese.crt;
    ssl_certificate_key /etc/ssl/private/john-reese.key;
    
    # SSL optimizations
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    
    location / {
        # WebSocket proxy to SSH with custom handshake (Dropbear on 2222)
        proxy_pass http://127.0.0.1:2222;
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
        
        # Custom handshake response
        add_header X-WebSocket-Protocol "HTTP 101 Switching Protocols - KENYAN JOHN REESE PRIME";
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "JOHN REESE VPS - SSL OK";
        add_header Content-Type text/plain;
    }
}
EOF
    
    # Enable the site
    ln -sf "$config_file" "/etc/nginx/sites-enabled/john-reese-$domain"
    
    # Test and reload NGINX
    if nginx -t; then
        systemctl reload nginx 2>/dev/null || true
        log_success "NGINX configured for domain $domain"
    else
        log_error "NGINX configuration test failed"
        rm -f "/etc/nginx/sites-enabled/john-reese-$domain"
        return 1
    fi
}

# Renew SSL certificate
renew_ssl() {
    echo -e "${GREEN}🔐 Renewing SSL Certificate${NC}"
    echo -e "${GRAY}─────────────────────────${NC}"
    
    # Get domain from config
    local domain=""
    if [[ -f "$DOMAIN_CONFIG" ]]; then
        domain=$(grep "^DOMAIN=" "$DOMAIN_CONFIG" | cut -d'=' -f2)
    fi
    
    if [[ -z "$domain" ]]; then
        echo -e "${RED}❌ No domain configured! Please add a domain first.${NC}"
        return 1
    fi
    
    echo -e "${WHITE}Renewing SSL certificate for domain: ${YELLOW}$domain${NC}"
    
    # Ensure webroot directory exists
    mkdir -p /var/www/html
    
    # Stop NGINX temporarily for standalone mode
    systemctl stop nginx
    
    # Request new certificate
    if certbot certonly --standalone -d "$domain" --agree-tos --no-eff-email --register-unsafely-without-email --non-interactive; then
        # Copy certificates to our location
        cp "/etc/letsencrypt/live/$domain/fullchain.pem" "/etc/ssl/certs/john-reese.crt"
        cp "/etc/letsencrypt/live/$domain/privkey.pem" "/etc/ssl/private/john-reese.key"
        
        # Set proper permissions
        chmod 644 /etc/ssl/certs/john-reese.crt
        chmod 600 /etc/ssl/private/john-reese.key
        
        # Start NGINX
        systemctl start nginx
        
        # Setup auto-renewal
        setup_ssl_auto_renewal "$domain"
        
        echo -e "${GREEN}✅ SSL certificate renewed successfully!${NC}"
        log_success "SSL certificate renewed for $domain"
    else
        # Start NGINX even if renewal failed
        systemctl start nginx
        echo -e "${RED}❌ SSL certificate renewal failed!${NC}"
        echo -e "${WHITE}Please check that:${NC}"
        echo -e "${WHITE}1. Domain DNS points to this server${NC}"
        echo -e "${WHITE}2. Port 80 and 443 are accessible${NC}"
        echo -e "${WHITE}3. No firewall is blocking the connection${NC}"
        log_error "SSL certificate renewal failed for $domain"
        return 1
    fi
    
    show_creator_credits
}

# Setup SSL auto-renewal
setup_ssl_auto_renewal() {
    local domain="$1"
    
    # Create renewal script
    cat > "/etc/cron.daily/john-reese-ssl-renewal" << EOF
#!/bin/bash
# JOHN REESE VPS - SSL Auto-renewal

certbot renew --quiet --deploy-hook "
    cp /etc/letsencrypt/live/$domain/fullchain.pem /etc/ssl/certs/john-reese.crt
    cp /etc/letsencrypt/live/$domain/privkey.pem /etc/ssl/private/john-reese.key
    chmod 644 /etc/ssl/certs/john-reese.crt
    chmod 600 /etc/ssl/private/john-reese.key
    systemctl reload nginx
    echo \"\$(date): SSL certificate auto-renewed\" >> /var/log/john-reese-vps.log
"
EOF
    
    chmod +x "/etc/cron.daily/john-reese-ssl-renewal"
    log_success "SSL auto-renewal configured"
}

# Get configured domain
get_configured_domain() {
    if [[ -f "$DOMAIN_CONFIG" ]]; then
        grep "^DOMAIN=" "$DOMAIN_CONFIG" | cut -d'=' -f2
    fi
}