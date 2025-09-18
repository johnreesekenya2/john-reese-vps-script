# 👑 JOHN REESE VPS SCRIPT

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Termux-blue.svg)](https://github.com/johnreesekenya2/john-reese-vps-script)

## 🚀 Premium Multi-Protocol VPS Management Solution

A comprehensive Linux VPS management bash script with beautiful colorized CLI menu system for managing multiple tunneling protocols including SSH, WebSocket, SSL, Trojan, VMESS, VLESS, SlowDNS, and more.

### ✨ Features

- 🎨 **Beautiful CLI Menu** - Colorized number-based interface accessible via `.menu` command
- 👥 **User Management** - Add, remove, suspend, unsuspend, ban users with ease
- 🔧 **Multi-Protocol Support** - SSH, WebSocket, SSL, Trojan, VMESS, VLESS, SlowDNS
- ⚡ **Auto-Installation** - NGINX, Dropbear, Stunnel, Xray-core setup
- 🎯 **Custom Banners** - HTML-styled SSH login banners
- 📊 **Monitoring** - Bandwidth tracking and user expiry management
- 🔒 **SSL Management** - Auto-renewal with Certbot
- 🌐 **Domain Binding** - WebSocket handshake customization
- 📱 **Cross-Platform** - Ubuntu, Debian, Termux compatible

### 🖥️ Compatibility

- ✅ Ubuntu 20.04, 22.04
- ✅ Debian 11+
- ✅ Termux on Android
- ✅ Any Linux distribution with bash support

### 🚀 Quick Start

**Method 1: One-line installation (Recommended)**
```bash
curl -fsSL https://raw.githubusercontent.com/johnreesekenya2/john-reese-vps-script/main/install.sh | sudo bash
```

**Method 2: Manual installation**
```bash
# Clone repository using GitHub API
curl -fsSL https://api.github.com/repos/johnreesekenya2/john-reese-vps-script/zipball/main -o john-reese-vps.zip
unzip john-reese-vps.zip
cd johnreesekenya2-john-reese-vps-script-*

# Install the system
sudo ./bin/john-reese-vps install

# Access the menu
.menu
```

**Method 3: Direct download (Legacy)**
```bash
# Download main script only
curl -fsSL https://raw.githubusercontent.com/johnreesekenya2/john-reese-vps-script/main/bin/john-reese-vps -o john-reese-vps
chmod +x john-reese-vps

# Install the system
sudo ./john-reese-vps install

# Access the menu
.menu
```

### 📋 Available Commands

```bash
john-reese-vps install     # Install and configure the system
john-reese-vps menu        # Show the main management menu  
john-reese-vps uninstall   # Remove the system
john-reese-vps --version   # Show version information
john-reese-vps --help      # Show help message
```

### 🎛️ Menu Options

1. **Add User** - Create new VPS accounts
2. **Remove User** - Delete user accounts
3. **Suspend User** - Temporarily disable accounts
4. **Unsuspend User** - Re-activate suspended accounts
5. **Ban User** - Permanently ban users
6. **Change Password** - Update user passwords
7. **Renew Account** - Extend account expiry
8. **Bandwidth Usage** - Monitor data usage
9. **Set Limits** - Configure usage limits
10. **Add Domain** - Bind custom domains
11. **Renew SSL** - Update SSL certificates
12. **Uninstall System** - Remove everything
13. **List Users** - View all accounts
14. **VPS Usage Report** - System statistics
15. **Exit** - Close the menu

### 🔧 Project Structure

```
john-reese-vps-script/
├── bin/
│   ├── john-reese-vps      # Main executable
│   └── github-upload       # GitHub API upload tool
├── lib/
│   ├── colors.sh           # Color definitions
│   ├── menu.sh             # Menu system
│   ├── users.sh            # User management
│   ├── bandwidth.sh        # Bandwidth monitoring
│   ├── domains.sh          # Domain management
│   ├── logging.sh          # Logging functions
│   ├── os.sh              # OS detection
│   ├── ports.sh           # Port management
│   └── services.sh        # Service management
├── modules/
│   └── protocols/
│       ├── ssh.sh         # SSH configuration
│       ├── websocket.sh   # WebSocket setup
│       └── xray.sh        # Xray protocols
├── templates/             # Configuration templates
└── etc/                  # System configurations
```

### 📞 Support & Contact

- 👑 **Creator**: John Reese
- 📱 **WhatsApp**: [wa.me/254745282166](https://wa.me/254745282166)
- 📧 **Email**: fsocietycipherrevolt@gmail.com
- 💬 **Motto**: "IN DUST WE TRUST"

### 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### ⭐ Star This Repository

If you find this script useful, please give it a star! ⭐

---

**"IN THE END WE ARE ALL ALONE AND NO ONE IS COMING TO SAVE YOU"** - John Reese
