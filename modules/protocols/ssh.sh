#!/bin/bash

# JOHN REESE VPS - SSH Protocol Configuration
# SSH and SSH banner management

# Create SSH login banner
create_ssh_banner() {
    local username="$1"
    local expiry="$2"
    
    local banner_file="/etc/ssh/banner_$username"
    
    cat > "$banner_file" << EOF
<body bgcolor="#000000" text="#ffffff">
<center>
<h1><font color="#00ffcc"> 👑JOHN REESE VPS</font></h1>
<h3><font color="fuchsia">PREMIUM SSH ACCOUNT</font></h3>
<h3><font color="#ffff00">wa.me/254745282166</font></h3>
<p><font color="#00ff00">IN DUST WE TRUST</font></p>
<p><font color="#ff00ff"><b>Expires:</b> $expiry</font></p>
<p><font color="#00ffcc">Powered by 👑John Reese</font></p>
<p><font color="#ffffff">IN THE END WE ARE ALL ALONE AND NO ONE IS COMING TO SAVE YOU</font></p>
</center>
</body>
EOF
    
    chmod 644 "$banner_file"
    log_success "SSH banner created for user $username"
}

# Configure SSH for user
configure_ssh() {
    local username="$1"
    local password="$2"
    
    # SSH is configured automatically when system user is created
    # Additional SSH configuration can be added here
    
    log_success "SSH configured for user $username"
}

# Remove SSH banner for user
remove_ssh_banner() {
    local username="$1"
    
    rm -f "/etc/ssh/banner_$username"
    log_info "SSH banner removed for user $username"
}