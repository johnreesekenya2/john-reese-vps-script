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
    
    # Ensure webroot directory exists and is accessible
    mkdir -p /var/www/html
    chown -R www-data:www-data /var/www/html 2>/dev/null || true
    chmod -R 755 /var/www/html
    
    local success=false
    local cert_path="/etc/ssl/certs/john-reese.crt"
    local key_path="/etc/ssl/private/john-reese.key"
    
    echo -e "${BLUE}🔄 Attempting webroot renewal first (no downtime)...${NC}"
    
    # Try webroot method first (no service interruption)
    if certbot certonly --webroot -w /var/www/html -d "$domain" --agree-tos --no-eff-email --register-unsafely-without-email --non-interactive --quiet; then
        echo -e "${GREEN}✅ Webroot renewal successful!${NC}"
        success=true
    else
        echo -e "${YELLOW}⚠️ Webroot renewal failed, trying standalone method...${NC}"
        
        # Backup current certificates
        local backup_dir="/tmp/ssl-backup-$(date +%s)"
        mkdir -p "$backup_dir"
        [[ -f "$cert_path" ]] && cp "$cert_path" "$backup_dir/"
        [[ -f "$key_path" ]] && cp "$key_path" "$backup_dir/"
        
        # Check if nginx is running and store state
        local nginx_was_running=false
        if systemctl is-active --quiet nginx 2>/dev/null; then
            nginx_was_running=true
            echo -e "${YELLOW}🔄 Temporarily stopping nginx for standalone renewal...${NC}"
            systemctl stop nginx
        fi
        
        # Try standalone method
        if timeout 60 certbot certonly --standalone -d "$domain" --agree-tos --no-eff-email --register-unsafely-without-email --non-interactive; then
            echo -e "${GREEN}✅ Standalone renewal successful!${NC}"
            success=true
        else
            echo -e "${RED}❌ Standalone renewal also failed!${NC}"
            # Restore backup certificates if they exist
            if [[ -f "$backup_dir/john-reese.crt" ]]; then
                cp "$backup_dir/john-reese.crt" "$cert_path"
                cp "$backup_dir/john-reese.key" "$key_path"
                echo -e "${BLUE}📥 Restored previous certificates${NC}"
            fi
        fi
        
        # Always restart nginx if it was running
        if [[ "$nginx_was_running" == true ]]; then
            echo -e "${BLUE}🔄 Restarting nginx...${NC}"
            systemctl start nginx
            
            # Verify nginx started successfully
            if ! systemctl is-active --quiet nginx; then
                log_error "Failed to restart nginx after SSL renewal attempt"
                echo -e "${RED}❌ Failed to restart nginx! Check configuration.${NC}"
            fi
        fi
        
        # Cleanup backup
        rm -rf "$backup_dir"
    fi
    
    if [[ "$success" == true ]]; then
        # Copy new certificates to our location
        if [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]]; then
            cp "/etc/letsencrypt/live/$domain/fullchain.pem" "$cert_path"
            cp "/etc/letsencrypt/live/$domain/privkey.pem" "$key_path"
            
            # Set proper permissions
            chmod 644 "$cert_path"
            chmod 600 "$key_path"
            chown root:root "$cert_path" "$key_path"
            
            # Test nginx configuration with new certificates
            if nginx -t 2>/dev/null; then
                systemctl reload nginx 2>/dev/null || systemctl restart nginx
                echo -e "${GREEN}✅ SSL certificate renewed and nginx reloaded successfully!${NC}"
                
                # Display certificate info
                local expiry=$(openssl x509 -in "$cert_path" -noout -enddate | cut -d'=' -f2)
                echo -e "${WHITE}📅 New certificate expires: ${YELLOW}$expiry${NC}"
                
                # Setup auto-renewal
                setup_ssl_auto_renewal "$domain"
                log_success "SSL certificate renewed for $domain"
            else
                echo -e "${RED}❌ New certificate is invalid! Nginx configuration test failed.${NC}"
                nginx -t
                return 1
            fi
        else
            echo -e "${RED}❌ Certificate files not found after renewal!${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ SSL certificate renewal failed!${NC}"
        echo -e "${WHITE}Please check that:${NC}"
        echo -e "${WHITE}1. Domain DNS points to this server (A record)${NC}"
        echo -e "${WHITE}2. Port 80 and 443 are accessible from internet${NC}"
        echo -e "${WHITE}3. No firewall is blocking the connection${NC}"
        echo -e "${WHITE}4. Domain is not already covered by another certificate${NC}"
        echo -e "${WHITE}5. Let's Encrypt rate limits are not exceeded${NC}"
        
        # Show more detailed error information
        echo -e "${BLUE}🔍 Checking domain connectivity...${NC}"
        if command -v curl >/dev/null 2>&1; then
            if curl -s --connect-timeout 5 "http://$domain/.well-known/acme-challenge/test" >/dev/null 2>&1; then
                echo -e "${GREEN}✅ Domain is reachable via HTTP${NC}"
            else
                echo -e "${RED}❌ Domain is not reachable via HTTP${NC}"
            fi
        fi
        
        log_error "SSL certificate renewal failed for $domain"
        return 1
    fi
    
    show_creator_credits
}

# Setup SSL auto-renewal
setup_ssl_auto_renewal() {
    local domain="$1"
    
    # Create improved renewal script with better error handling
    cat > "/etc/cron.daily/john-reese-ssl-renewal" << 'EOF'
#!/bin/bash
# JOHN REESE VPS - SSL Auto-renewal with error handling

set -euo pipefail

LOGFILE="/var/log/john-reese-ssl-renewal.log"
DOMAIN_CONFIG="/etc/john-reese-vps/domain.conf"
CERT_PATH="/etc/ssl/certs/john-reese.crt"
KEY_PATH="/etc/ssl/private/john-reese.key"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "$LOGFILE"
}

# Function to send notification (can be extended)
notify() {
    local message="$1"
    log "$message"
    echo "$message" | logger -t john-reese-ssl
}

# Get configured domain
get_domain() {
    if [[ -f "$DOMAIN_CONFIG" ]]; then
        grep "^DOMAIN=" "$DOMAIN_CONFIG" | cut -d'=' -f2
    fi
}

# Main renewal function
main() {
    local domain=$(get_domain)
    
    if [[ -z "$domain" ]]; then
        log "ERROR: No domain configured, skipping renewal"
        exit 0
    fi
    
    log "Starting SSL certificate renewal check for domain: $domain"
    
    # Check if certificate needs renewal (less than 30 days remaining)
    if [[ -f "$CERT_PATH" ]]; then
        if openssl x509 -in "$CERT_PATH" -noout -checkend 2592000 2>/dev/null; then
            log "Certificate is still valid for more than 30 days, skipping renewal"
            exit 0
        fi
        log "Certificate expires within 30 days, proceeding with renewal"
    else
        log "Certificate file not found, proceeding with renewal"
    fi
    
    # Try webroot renewal first
    if certbot renew --webroot -w /var/www/html --quiet --no-random-sleep-on-renew; then
        log "Webroot renewal successful"
        copy_certificates "$domain"
    else
        log "Webroot renewal failed, trying alternative method"
        
        # Backup existing certificates
        local backup_dir="/tmp/ssl-backup-$(date +%s)"
        mkdir -p "$backup_dir"
        [[ -f "$CERT_PATH" ]] && cp "$CERT_PATH" "$backup_dir/"
        [[ -f "$KEY_PATH" ]] && cp "$KEY_PATH" "$backup_dir/"
        
        # Try standalone renewal
        if systemctl stop nginx && \
           timeout 60 certbot renew --standalone --quiet --no-random-sleep-on-renew && \
           systemctl start nginx; then
            log "Standalone renewal successful"
            copy_certificates "$domain"
        else
            log "ERROR: All renewal methods failed"
            systemctl start nginx 2>/dev/null || true
            
            # Restore backup if available
            if [[ -f "$backup_dir/john-reese.crt" ]]; then
                cp "$backup_dir/john-reese.crt" "$CERT_PATH"
                cp "$backup_dir/john-reese.key" "$KEY_PATH"
                log "Restored backup certificates"
            fi
            
            notify "SSL certificate renewal failed for domain: $domain"
            exit 1
        fi
        
        rm -rf "$backup_dir"
    fi
    
    log "SSL certificate renewal completed successfully"
}

# Copy certificates from Let's Encrypt to our location
copy_certificates() {
    local domain="$1"
    local letsencrypt_cert="/etc/letsencrypt/live/$domain/fullchain.pem"
    local letsencrypt_key="/etc/letsencrypt/live/$domain/privkey.pem"
    
    if [[ -f "$letsencrypt_cert" && -f "$letsencrypt_key" ]]; then
        cp "$letsencrypt_cert" "$CERT_PATH"
        cp "$letsencrypt_key" "$KEY_PATH"
        chmod 644 "$CERT_PATH"
        chmod 600 "$KEY_PATH"
        chown root:root "$CERT_PATH" "$KEY_PATH"
        
        # Test and reload nginx
        if nginx -t 2>/dev/null; then
            systemctl reload nginx
            log "Certificates updated and nginx reloaded"
            
            # Log new expiry date
            local expiry=$(openssl x509 -in "$CERT_PATH" -noout -enddate | cut -d'=' -f2)
            log "New certificate expires: $expiry"
            notify "SSL certificate successfully renewed for domain: $domain (expires: $expiry)"
        else
            log "ERROR: Nginx configuration test failed after certificate update"
            notify "SSL certificate renewal completed but nginx configuration is invalid"
            exit 1
        fi
    else
        log "ERROR: New certificate files not found after renewal"
        exit 1
    fi
}

# Run main function
main "$@"
EOF
    
    chmod +x "/etc/cron.daily/john-reese-ssl-renewal"
    
    # Also create a systemd timer as backup (more reliable than cron)
    if command -v systemctl >/dev/null 2>&1; then
        create_systemd_renewal_timer "$domain"
    fi
    
    log_success "SSL auto-renewal configured with both cron and systemd"
}

# Create systemd timer for SSL renewal (more reliable than cron)
create_systemd_renewal_timer() {
    local domain="$1"
    
    # Create service file
    cat > "/etc/systemd/system/john-reese-ssl-renewal.service" << 'EOF'
[Unit]
Description=John Reese VPS SSL Certificate Renewal
After=network.target

[Service]
Type=oneshot
ExecStart=/etc/cron.daily/john-reese-ssl-renewal
User=root
StandardOutput=journal
StandardError=journal
EOF

    # Create timer file
    cat > "/etc/systemd/system/john-reese-ssl-renewal.timer" << 'EOF'
[Unit]
Description=Run John Reese VPS SSL renewal twice daily
Requires=john-reese-ssl-renewal.service

[Timer]
OnCalendar=*-*-* 00,12:00:00
RandomizedDelaySec=1800
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Enable and start the timer
    systemctl daemon-reload
    systemctl enable john-reese-ssl-renewal.timer
    systemctl start john-reese-ssl-renewal.timer
    
    log_success "Systemd renewal timer created and enabled"
}

# Get configured domain
get_configured_domain() {
    if [[ -f "$DOMAIN_CONFIG" ]]; then
        grep "^DOMAIN=" "$DOMAIN_CONFIG" | cut -d'=' -f2
    fi
}