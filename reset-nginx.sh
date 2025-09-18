
#!/bin/bash

echo "🔧 Completely resetting nginx configuration..."

# Stop nginx
systemctl stop nginx 2>/dev/null || true

# Backup existing configuration
mkdir -p /tmp/nginx-backup-$(date +%s)
cp -r /etc/nginx/* /tmp/nginx-backup-$(date +%s)/ 2>/dev/null || true

# Remove all site configurations
rm -f /etc/nginx/sites-enabled/* 2>/dev/null || true
rm -f /etc/nginx/sites-available/john-reese-* 2>/dev/null || true

# Create a minimal working nginx configuration
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
}
EOF

# Enable default site
ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Ensure SSL directory and certificates exist
mkdir -p /etc/ssl/certs /etc/ssl/private

if [[ ! -f "/etc/ssl/certs/john-reese.crt" ]]; then
    echo "Creating temporary self-signed certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/john-reese.key \
        -out /etc/ssl/certs/john-reese.crt \
        -subj "/C=US/ST=State/L=City/O=JohnReese/CN=localhost" 2>/dev/null
    
    chmod 600 /etc/ssl/private/john-reese.key
    chmod 644 /etc/ssl/certs/john-reese.crt
fi

# Create webroot directory
mkdir -p /var/www/html
echo "Welcome to John Reese VPS" > /var/www/html/index.html

# Test and start nginx
if nginx -t; then
    systemctl start nginx
    systemctl enable nginx
    echo "✅ Nginx reset and running successfully"
else
    echo "❌ Nginx configuration still has issues:"
    nginx -t
    exit 1
fi

echo "🎉 Nginx has been completely reset and is working!"
