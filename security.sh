#!/bin/bash

# Cobra Security Configuration
# Handles security features, anonymity tools, and system hardening

# Exit on any error
set -e

# Color definitions
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to handle errors
handle_error() {
    echo -e "${RED}[!] Error: $1${NC}"
    exit 1
}

# Function to handle warnings
handle_warning() {
    echo -e "${YELLOW}[!] Warning: $1${NC}"
}

# Function to check if a service is running
check_service() {
    if ! systemctl is-active --quiet "$1"; then
        handle_error "Service $1 failed to start"
    fi
}

# Function to verify file creation
verify_file() {
    if [ ! -f "$1" ]; then
        handle_error "Failed to create file: $1"
    fi
}

echo -e "${GREEN}[*] Configuring security features...${NC}"

# Verify system requirements
if ! command -v systemctl &> /dev/null; then
    handle_error "This script requires systemd"
fi

# Install security tools with error handling
echo -e "${CYAN}[*] Installing security packages...${NC}"
apt install -y --no-install-recommends \
    ufw \
    fail2ban \
    macchanger \
    tor \
    proxychains4 \
    secure-delete \
    apparmor \
    apparmor-utils \
    rkhunter

# Install and configure Anonsurf with error handling
echo -e "${CYAN}[*] Setting up Anonsurf...${NC}"
cd /tmp || handle_error "Failed to change to /tmp directory"
git clone https://github.com/Und3rf10w/kali-anonsurf.git || handle_error "Failed to clone Anonsurf repository"
cd kali-anonsurf || handle_error "Failed to change to kali-anonsurf directory"
chmod +x installer.sh || handle_error "Failed to make installer executable"
./installer.sh || handle_warning "Anonsurf installation encountered issues"

# Configure MAC address randomization with error handling
echo -e "${CYAN}[*] Configuring MAC address randomization...${NC}"
MAC_SERVICE="/etc/systemd/system/macspoof@.service"
cat > "$MAC_SERVICE" << 'EOF' || handle_error "Failed to create MAC spoofing service file"
[Unit]
Description=MAC Address Change %I
Wants=network-pre.target
Before=network-pre.target
BindsTo=sys-subsystem-net-devices-%i.device
After=sys-subsystem-net-devices-%i.device

[Service]
Type=oneshot
ExecStart=/usr/bin/macchanger -r %I
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable MAC spoofing for all network interfaces with error handling
for interface in $(ls /sys/class/net | grep -v lo); do
    systemctl enable macspoof@${interface}.service || handle_warning "Failed to enable MAC spoofing for $interface"
done
verify_file "$MAC_SERVICE"

# Configure UFW (Uncomplicated Firewall) with error handling
echo -e "${CYAN}[*] Configuring firewall...${NC}"
ufw default deny incoming || handle_error "Failed to set UFW default incoming policy"
ufw default allow outgoing || handle_error "Failed to set UFW default outgoing policy"
ufw allow ssh || handle_error "Failed to allow SSH in UFW"
ufw --force enable || handle_error "Failed to enable UFW"

# Configure fail2ban with error handling
echo -e "${CYAN}[*] Setting up fail2ban...${NC}"
FAIL2BAN_CONFIG="/etc/fail2ban/jail.local"
cat > "$FAIL2BAN_CONFIG" << 'EOF' || handle_error "Failed to create fail2ban configuration"
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 3
EOF

# Setup Tor configuration
echo -e "${CYAN}[*] Configuring Tor...${NC}"
cat > /etc/tor/torrc << 'EOF'
VirtualAddrNetwork 10.192.0.0/10
AutomapHostsOnResolve 1
TransPort 9040
DNSPort 5353
EOF

# Configure proxychains
echo -e "${CYAN}[*] Configuring proxychains...${NC}"
cat > /etc/proxychains4.conf << 'EOF'
strict_chain
proxy_dns
remote_dns_subnet 224
tcp_read_time_out 15000
tcp_connect_time_out 8000

[ProxyList]
socks5 127.0.0.1 9050
EOF

# Create lockdown mode script
echo -e "${CYAN}[*] Creating lockdown mode script...${NC}"
cat > /opt/cobra/scripts/lockdown << 'EOF'
#!/bin/bash
if [ "$1" = "on" ]; then
    echo "Enabling lockdown mode..."
    anonsurf start
    for interface in $(ls /sys/class/net | grep -v lo); do
        macchanger -r $interface
    done
    ufw enable
    systemctl start tor
elif [ "$1" = "off" ]; then
    echo "Disabling lockdown mode..."
    anonsurf stop
    ufw disable
    systemctl stop tor
else
    echo "Usage: lockdown [on|off]"
    exit 1
fi
EOF

chmod +x /opt/cobra/scripts/lockdown

# System hardening
echo -e "${CYAN}[*] Applying system hardening...${NC}"

# Secure shared memory
echo "tmpfs     /run/shm     tmpfs     defaults,noexec,nosuid     0     0" >> /etc/fstab

# Secure sysctl settings
cat > /etc/sysctl.d/99-security.conf << 'EOF'
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Disable IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

# Apply sysctl settings
sysctl -p /etc/sysctl.d/99-security.conf

# Enable and start services with verification
echo -e "${CYAN}[*] Starting security services...${NC}"
systemctl enable fail2ban || handle_error "Failed to enable fail2ban"
systemctl start fail2ban || handle_error "Failed to start fail2ban"
check_service fail2ban

systemctl enable tor || handle_error "Failed to enable Tor"
systemctl start tor || handle_error "Failed to start Tor"
check_service tor

# Verify all configurations
verify_file "/etc/tor/torrc"
verify_file "/etc/proxychains4.conf"
verify_file "/opt/cobra/scripts/lockdown"

echo -e "${GREEN}[*] Security configuration complete!${NC}"
