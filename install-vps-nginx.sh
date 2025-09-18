
#!/bin/bash

# JOHN REESE VPS - VPS Nginx Installation Script
# For actual VPS deployment

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}ℹ️ $*${NC}"; }
log_success() { echo -e "${GREEN}✅ $*${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️ $*${NC}"; }
log_error() { echo -e "${RED}❌ $*${NC}"; }

# Show header
show_header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "╔════════════════════════════════════════╗"
    echo "║       🚀 JOHN REESE VPS NGINX          ║"
    echo "║         IN DUST WE TRUST               ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${WHITE}VPS Nginx Configuration Installer${NC}"
    echo
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        echo "Please run: sudo $0"
        exit 1
    fi
    log_success "Running as root"
}

# Install nginx if not present
install_nginx() {
    log_info "Checking nginx installation..."

    if ! command -v nginx &> /dev/null; then
        log_info "Installing nginx..."
        
        if [[ -f /etc/debian_version ]]; then
            apt-get update -qq
            apt-get install -y nginx
        elif [[ -f /etc/redhat-release ]]; then
            if command -v dnf &> /dev/null; then
                dnf install -y nginx
            else
                yum install -y nginx
            fi
        else
            log_error "Unsupported OS. Please install nginx manually."
            exit 1
        fi
        
        log_success "Nginx installed"
    else
        log_success "Nginx already installed"
    fi
}

# Setup directories
setup_directories() {
    log_info "Setting up directories..."

    # Create necessary directories
    mkdir -p /var/www/html
    mkdir -p /var/log/nginx
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    mkdir -p /etc/ssl/certs
    mkdir -p /etc/ssl/private

    # Set proper permissions
    chown -R www-data:www-data /var/www/html
    chmod 755 /var/www/html

    log_success "Directories created"
}

# Generate SSL certificate
generate_ssl() {
    log_info "Generating SSL certificate..."

    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/john-reese.key \
        -out /etc/ssl/certs/john-reese.crt \
        -subj "/C=KE/ST=Nairobi/L=Nairobi/O=JohnReeseVPS/CN=johnreesevps"

    chmod 600 /etc/ssl/private/john-reese.key
    chmod 644 /etc/ssl/certs/john-reese.crt

    log_success "SSL certificate generated"
}

# Create web content
create_web_content() {
    log_info "Creating web content..."

    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>🚀 JOHN REESE VPS</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Courier New', monospace;
            background: linear-gradient(135deg, #000000, #1a1a1a);
            color: #00ff00;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            text-align: center;
            overflow-x: hidden;
        }
        
        .container {
            max-width: 800px;
            padding: 2rem;
            background: rgba(0, 0, 0, 0.8);
            border: 2px solid #00ff00;
            border-radius: 10px;
            box-shadow: 0 0 30px rgba(0, 255, 0, 0.3);
            animation: glow 2s ease-in-out infinite alternate;
        }
        
        @keyframes glow {
            from { box-shadow: 0 0 20px rgba(0, 255, 0, 0.3); }
            to { box-shadow: 0 0 40px rgba(0, 255, 0, 0.6); }
        }
        
        h1 {
            font-size: 3rem;
            margin-bottom: 1rem;
            text-shadow: 0 0 20px #00ff00;
            animation: pulse 1.5s infinite;
        }
        
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.7; }
        }
        
        .motto {
            font-size: 1.5rem;
            margin-bottom: 2rem;
            color: #ffffff;
            text-shadow: 0 0 10px #ffffff;
        }
        
        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1rem;
            margin: 2rem 0;
        }
        
        .status-box {
            background: rgba(0, 255, 0, 0.1);
            border: 1px solid #00ff00;
            border-radius: 8px;
            padding: 1rem;
            transition: all 0.3s ease;
        }
        
        .status-box:hover {
            background: rgba(0, 255, 0, 0.2);
            transform: translateY(-5px);
        }
        
        .status-indicator {
            font-size: 2rem;
            margin-bottom: 0.5rem;
        }
        
        .websocket-test {
            margin: 2rem 0;
            padding: 1rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 8px;
        }
        
        button {
            background: linear-gradient(45deg, #00ff00, #00cc00);
            color: black;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            font-weight: bold;
            margin: 0 10px;
            transition: all 0.3s ease;
        }
        
        button:hover {
            background: linear-gradient(45deg, #00cc00, #00ff00);
            transform: scale(1.05);
        }
        
        .footer {
            margin-top: 2rem;
            padding: 1rem;
            border-top: 1px solid #00ff00;
            color: #cccccc;
        }
        
        .terminal-output {
            background: #000;
            color: #00ff00;
            padding: 1rem;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            text-align: left;
            margin: 1rem 0;
            border: 1px solid #00ff00;
            min-height: 100px;
            white-space: pre-wrap;
        }
        
        @media (max-width: 768px) {
            h1 { font-size: 2rem; }
            .motto { font-size: 1.2rem; }
            .container { padding: 1rem; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 JOHN REESE VPS</h1>
        <div class="motto">IN DUST WE TRUST</div>
        
        <div class="status-grid">
            <div class="status-box">
                <div class="status-indicator">✅</div>
                <h3>Nginx Status</h3>
                <p>Running & Configured</p>
            </div>
            
            <div class="status-box">
                <div class="status-indicator">🔒</div>
                <h3>SSL Security</h3>
                <p>Certificate Active</p>
            </div>
            
            <div class="status-box">
                <div class="status-indicator">🌐</div>
                <h3>WebSocket Ready</h3>
                <p>SSH Tunnel Available</p>
            </div>
            
            <div class="status-box">
                <div class="status-indicator">⚡</div>
                <h3>VPS Performance</h3>
                <p>Optimized & Fast</p>
            </div>
        </div>
        
        <div class="websocket-test">
            <h3>WebSocket Connection Test</h3>
            <button onclick="testWebSocket()">Test WebSocket</button>
            <button onclick="testSSH()">Test SSH Tunnel</button>
            <button onclick="clearOutput()">Clear Output</button>
            <div id="terminal" class="terminal-output">WebSocket test output will appear here...</div>
        </div>
        
        <div class="footer">
            <p><strong>Creator:</strong> John Reese</p>
            <p><strong>Contact:</strong> fsocietycipherrevolt@gmail.com</p>
            <p><strong>WhatsApp:</strong> wa.me/254745282166</p>
            <p><strong>Server Time:</strong> <span id="serverTime"></span></p>
        </div>
    </div>

    <script>
        // Update server time
        function updateTime() {
            document.getElementById('serverTime').textContent = new Date().toLocaleString();
        }
        setInterval(updateTime, 1000);
        updateTime();

        // WebSocket test function
        function testWebSocket() {
            const terminal = document.getElementById('terminal');
            terminal.textContent = 'Testing WebSocket connection...\n';
            
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = `${protocol}//${window.location.host}/ssh-ws`;
            
            try {
                const ws = new WebSocket(wsUrl);
                
                ws.onopen = function(event) {
                    terminal.textContent += '✅ WebSocket connection opened successfully!\n';
                    terminal.textContent += `Connected to: ${wsUrl}\n`;
                    ws.close();
                };
                
                ws.onmessage = function(event) {
                    terminal.textContent += `📨 Message received: ${event.data}\n`;
                };
                
                ws.onerror = function(error) {
                    terminal.textContent += `❌ WebSocket error: ${error}\n`;
                };
                
                ws.onclose = function(event) {
                    terminal.textContent += '🔌 WebSocket connection closed\n';
                    terminal.textContent += `Code: ${event.code}, Reason: ${event.reason}\n`;
                };
                
            } catch (error) {
                terminal.textContent += `❌ Error creating WebSocket: ${error.message}\n`;
            }
        }
        
        function testSSH() {
            const terminal = document.getElementById('terminal');
            terminal.textContent = 'Testing SSH tunnel endpoint...\n';
            
            fetch('/ssh-ws', {
                method: 'GET',
                headers: {
                    'Connection': 'Upgrade',
                    'Upgrade': 'websocket'
                }
            })
            .then(response => {
                terminal.textContent += `✅ SSH tunnel endpoint response: ${response.status}\n`;
                terminal.textContent += `Headers: ${JSON.stringify([...response.headers], null, 2)}\n`;
            })
            .catch(error => {
                terminal.textContent += `❌ SSH tunnel test error: ${error.message}\n`;
            });
        }
        
        function clearOutput() {
            document.getElementById('terminal').textContent = 'Output cleared...\n';
        }
    </script>
</body>
</html>
EOF

    chown www-data:www-data /var/www/html/index.html
    log_success "Web content created"
}

# Configure nginx
configure_nginx() {
    log_info "Configuring nginx..."

    # Backup original config
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup 2>/dev/null || true

    # Copy our VPS nginx config
    cp vps-nginx.conf /etc/nginx/nginx.conf

    # Test configuration
    if nginx -t; then
        log_success "Nginx configuration test passed"
    else
        log_error "Nginx configuration test failed"
        nginx -t
        exit 1
    fi
}

# Start and enable nginx
start_nginx() {
    log_info "Starting nginx service..."

    systemctl enable nginx
    systemctl start nginx
    systemctl reload nginx

    if systemctl is-active --quiet nginx; then
        log_success "Nginx is running successfully"
    else
        log_error "Failed to start nginx"
        systemctl status nginx
        exit 1
    fi
}

# Show completion message
show_completion() {
    echo
    log_success "🎉 JOHN REESE VPS Nginx installation completed!"
    echo
    echo -e "${WHITE}Server Information:${NC}"
    echo -e "  ${GREEN}HTTP:${NC}  http://$(curl -s ifconfig.me || echo 'YOUR_SERVER_IP')"
    echo -e "  ${GREEN}HTTPS:${NC} https://$(curl -s ifconfig.me || echo 'YOUR_SERVER_IP')"
    echo -e "  ${GREEN}WebSocket:${NC} ws://$(curl -s ifconfig.me || echo 'YOUR_SERVER_IP')/ssh-ws"
    echo -e "  ${GREEN}Secure WebSocket:${NC} wss://$(curl -s ifconfig.me || echo 'YOUR_SERVER_IP')/ssh-ws"
    echo
    echo -e "${WHITE}Status Endpoints:${NC}"
    echo -e "  ${GREEN}Health:${NC} http://$(curl -s ifconfig.me || echo 'YOUR_SERVER_IP')/health"
    echo -e "  ${GREEN}Status:${NC} http://$(curl -s ifconfig.me || echo 'YOUR_SERVER_IP')/status"
    echo
    echo -e "${BOLD}${CYAN}JOHN REESE VPS is ready for action!${NC}"
    echo -e "${WHITE}IN DUST WE TRUST${NC}"
}

# Main installation function
main() {
    show_header
    check_root
    install_nginx
    setup_directories
    generate_ssl
    create_web_content
    configure_nginx
    start_nginx
    show_completion
}

# Handle script interruption
trap 'log_error "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"
