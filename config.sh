#!/bin/bash

# Cobra Configuration Script
# Handles theme settings and system configurations

# Exit on any error
set -e

# Color definitions
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}[*] Applying system configurations...${NC}"

# Create theme switcher script
echo -e "${CYAN}[*] Creating theme switcher...${NC}"
cat > /opt/cobra/scripts/theme << 'EOF'
#!/bin/bash

THEME_CONFIG="/opt/cobra/config/themes/config.json"
XRESOURCES="/etc/skel/.Xresources"

show_themes() {
    echo "Available themes:"
    jq -r '.themes | keys[]' "$THEME_CONFIG"
}

set_theme() {
    local theme=$1
    if ! jq -e ".themes[\"$theme\"]" "$THEME_CONFIG" > /dev/null; then
        echo "Theme '$theme' not found"
        return 1
    fi

    # Update current theme in config
    jq ".current_theme = \"$theme\"" "$THEME_CONFIG" > "$THEME_CONFIG.tmp"
    mv "$THEME_CONFIG.tmp" "$THEME_CONFIG"

    # Get theme colors
    local primary=$(jq -r ".themes[\"$theme\"].primary" "$THEME_CONFIG")
    local background=$(jq -r ".themes[\"$theme\"].background" "$THEME_CONFIG")
    local text=$(jq -r ".themes[\"$theme\"].text" "$THEME_CONFIG")

    # Update terminal colors
    sed -i "s/URxvt\*foreground:.*/URxvt*foreground: $text/" "$XRESOURCES"
    sed -i "s/URxvt\*background:.*/URxvt*background: $background/" "$XRESOURCES"

    # Update i3 colors
    local i3config="/etc/skel/.config/i3/config"
    sed -i "s/statusline #.*$/statusline $text/" "$i3config"
    sed -i "s/focused_workspace.*$/focused_workspace  $text $background $text/" "$i3config"

    echo "Theme set to $theme"
    echo "Please restart your terminal or reload Xresources for changes to take effect"
}

case "$1" in
    "list")
        show_themes
        ;;
    "set")
        if [ -z "$2" ]; then
            echo "Usage: theme set <theme-name>"
            exit 1
        fi
        set_theme "$2"
        ;;
    *)
        echo "Usage: theme [list|set <theme-name>]"
        exit 1
        ;;
esac
EOF

chmod +x /opt/cobra/scripts/theme

# Create system configuration script
echo -e "${CYAN}[*] Creating system configuration utility...${NC}"
cat > /opt/cobra/scripts/cobra-config << 'EOF'
#!/bin/bash

show_menu() {
    clear
    echo "╔══ COBRA CONFIGURATION ══╗"
    echo "║                        ║"
    echo "║ 1. Change Theme       ║"
    echo "║ 2. Network Settings   ║"
    echo "║ 3. Security Options   ║"
    echo "║ 4. System Info        ║"
    echo "║ 5. Exit              ║"
    echo "║                        ║"
    echo "╚════════════════════════╝"
    echo
    echo "Select an option:"
}

theme_menu() {
    clear
    echo "=== Theme Settings ==="
    theme list
    echo
    read -p "Enter theme name to apply (or 'back'): " theme
    if [ "$theme" != "back" ]; then
        theme set "$theme"
        read -p "Press Enter to continue..."
    fi
}

network_menu() {
    clear
    echo "=== Network Settings ==="
    echo "1. Show Network Interfaces"
    echo "2. Toggle MAC Randomization"
    echo "3. Toggle Anonsurf"
    echo "4. Back"
    
    read -p "Select option: " opt
    case $opt in
        1) ip addr show; read -p "Press Enter to continue..." ;;
        2) macchanger -s $(ip link | grep -o "eth[0-9]" | head -n 1); read -p "Press Enter to continue..." ;;
        3) anonsurf status; read -p "Press Enter to continue..." ;;
        4) return ;;
    esac
}

security_menu() {
    clear
    echo "=== Security Options ==="
    echo "1. Toggle Lockdown Mode"
    echo "2. Firewall Status"
    echo "3. Show Active Services"
    echo "4. Back"
    
    read -p "Select option: " opt
    case $opt in
        1) lockdown status; read -p "Press Enter to continue..." ;;
        2) ufw status; read -p "Press Enter to continue..." ;;
        3) systemctl list-units --type=service --state=running; read -p "Press Enter to continue..." ;;
        4) return ;;
    esac
}

system_info() {
    clear
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "CPU: $(grep "model name" /proc/cpuinfo | head -n 1 | cut -d: -f2)"
    echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
    echo "Disk Space: $(df -h / | tail -n 1 | awk '{print $4}') free"
    echo
    read -p "Press Enter to continue..."
}

while true; do
    show_menu
    read -r opt

    case $opt in
        1) theme_menu ;;
        2) network_menu ;;
        3) security_menu ;;
        4) system_info ;;
        5) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
done
EOF

chmod +x /opt/cobra/scripts/cobra-config

# Create welcome message
echo -e "${CYAN}[*] Creating welcome message...${NC}"
cat > /etc/update-motd.d/10-cobra << 'EOF'
#!/bin/bash
echo "
   ______      __                ____  _____ 
  / ____/___  / /_  _________ _/ __ \/ ___/ 
 / /   / __ \/ __ \/ ___/ __ '/ / / /\__ \ 
/ /___/ /_/ / /_/ / /  / /_/ / /_/ /___/ / 
\____/\____/_.___/_/   \__,_/\____//____/  
                                           
Minimal Debian-based pentesting environment
----------------------------------------
Type 'cobra' to launch the system monitor
Type 'tools-menu' to access pentesting tools
Type 'cobra-config' to configure system settings
"
EOF

chmod +x /etc/update-motd.d/10-cobra

# Set default theme
echo -e "${CYAN}[*] Setting default theme...${NC}"
/opt/cobra/scripts/theme set hacker-green

# Create aliases
echo -e "${CYAN}[*] Creating useful aliases...${NC}"
cat > /etc/profile.d/cobra-aliases.sh << 'EOF'
# Cobra aliases
alias c='clear'
alias l='ls -la'
alias ports='netstat -tuln'
alias myip='curl ifconfig.me'
alias scan='nmap -sC -sV'
alias updates='apt update && apt list --upgradable'
alias tools='tools-menu'
alias config='cobra-config'
EOF

# Set system preferences
echo -e "${CYAN}[*] Setting system preferences...${NC}"
# Set vim as default editor
update-alternatives --set editor /usr/bin/vim.basic

# Configure shell history
cat >> /etc/profile.d/cobra-history.sh << 'EOF'
# Enhanced shell history
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTTIMEFORMAT="%F %T "
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend
EOF

echo -e "${GREEN}[*] Configuration complete!${NC}"
