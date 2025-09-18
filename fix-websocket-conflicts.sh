#!/bin/bash

# JOHN REESE VPS - WebSocket Configuration Fix Script
# This script fixes WebSocket configuration conflicts

echo "🔧 Fixing WebSocket configuration conflicts..."

# Fix the typo in domains.sh - proxy_Set_header should be proxy_set_header
sed -i 's/proxy_Set_header/proxy_set_header/g' /etc/nginx/sites-available/john-reese-*

# Fix inconsistent WebSocket upgrade policies by updating existing configs
for config_file in /etc/nginx/sites-available/john-reese-*; do
    if [[ -f "$config_file" ]]; then
        echo "Updating WebSocket configuration in $config_file"
        
        # Create backup
        cp "$config_file" "${config_file}.backup"
        
        # Replace inconsistent WebSocket upgrade checks
        sed -i 's/if ($http_upgrade = websocket)/if ($http_upgrade = "websocket")/g' "$config_file"
        sed -i 's/if ($http_upgrade != websocket)/if ($http_upgrade != "websocket")/g' "$config_file"
        
        # Ensure consistent timeout values
        sed -i 's/proxy_connect_timeout [0-9]*s/proxy_connect_timeout 60s/g' "$config_file"
        sed -i 's/proxy_send_timeout [0-9]*s/proxy_send_timeout 60s/g' "$config_file" 
        sed -i 's/proxy_read_timeout [0-9]*s/proxy_read_timeout 60s/g' "$config_file"
    fi
done

# Test nginx configuration
if nginx -t 2>/dev/null; then
    echo "✅ WebSocket configuration fixed successfully"
    systemctl reload nginx 2>/dev/null || systemctl restart nginx
    echo "✅ Nginx reloaded with fixed configuration"
else
    echo "❌ Configuration test failed, restoring backups"
    for config_file in /etc/nginx/sites-available/john-reese-*; do
        if [[ -f "${config_file}.backup" ]]; then
            mv "${config_file}.backup" "$config_file"
        fi
    done
    nginx -t
    exit 1
fi

# Clean up backups if successful
rm -f /etc/nginx/sites-available/john-reese-*.backup

echo "🎉 WebSocket configuration conflicts resolved!"