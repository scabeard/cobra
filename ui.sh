#!/bin/bash

# Cobra UI Setup
# Handles terminal UI, monitoring tools, and theme configuration

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

# Function to verify Python package installation
verify_pip_package() {
    if ! pip3 list | grep -q "^$1[[:space:]]"; then
        handle_error "Failed to install Python package: $1"
    fi
}

# Function to verify file creation
verify_file() {
    if [ ! -f "$1" ]; then
        handle_error "Failed to create file: $1"
    fi
}

echo -e "${GREEN}[*] Setting up UI components...${NC}"

# Verify Python installation
if ! command -v python3 &> /dev/null; then
    handle_error "Python 3 is required but not installed"
fi

if ! command -v pip3 &> /dev/null; then
    handle_error "pip3 is required but not installed"
fi

# Install UI dependencies with error handling
echo -e "${CYAN}[*] Installing UI dependencies...${NC}"
apt install -y --no-install-recommends \
    python3-urwid \
    python3-psutil \
    python3-netifaces \
    python3-blessed \
    ranger \
    ncdu \
    btop \
    neofetch

# Install VSCodium with error handling
echo -e "${CYAN}[*] Installing VSCodium...${NC}"
VSCODIUM_KEY="/usr/share/keyrings/vscodium-archive-keyring.gpg"
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor \
    | dd of="$VSCODIUM_KEY" || handle_error "Failed to download and import VSCodium key"

verify_file "$VSCODIUM_KEY"

VSCODIUM_LIST="/etc/apt/sources.list.d/vscodium.list"
echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
    | tee "$VSCODIUM_LIST" || handle_error "Failed to add VSCodium repository"

verify_file "$VSCODIUM_LIST"

apt update || handle_error "Failed to update package lists"
apt install -y codium || handle_error "Failed to install VSCodium"

# Create the terminal UI framework with error handling
echo -e "${CYAN}[*] Creating terminal UI framework...${NC}"
mkdir -p /opt/cobra/ui || handle_error "Failed to create UI directory"

# Verify Python package installations
for package in urwid psutil netifaces blessed; do
    verify_pip_package "$package"
done

# Create the main UI script with error handling
UI_SCRIPT="/opt/cobra/ui/cobra_ui.py"
cat > "$UI_SCRIPT" << 'EOF' || handle_error "Failed to create UI script"
#!/usr/bin/env python3
import urwid
import psutil
import netifaces
import socket
import time
from datetime import datetime

class SystemStats:
    @staticmethod
    def get_cpu_usage():
        return psutil.cpu_percent(interval=1)

    @staticmethod
    def get_memory_usage():
        mem = psutil.virtual_memory()
        return f"{mem.percent}% ({mem.used >> 20}MB/{mem.total >> 20}MB)"

    @staticmethod
    def get_network_info():
        interfaces = netifaces.interfaces()
        info = []
        for iface in interfaces:
            if iface != 'lo':
                try:
                    addrs = netifaces.ifaddresses(iface)
                    if netifaces.AF_INET in addrs:
                        ip = addrs[netifaces.AF_INET][0]['addr']
                        info.append(f"{iface}: {ip}")
                except:
                    continue
        return '\n'.join(info)

class DashboardWidget(urwid.WidgetWrap):
    def __init__(self):
        self.update_text()
        self._w = urwid.AttrMap(self.text_widget, 'body')
        self.update()

    def update_text(self):
        stats = SystemStats()
        text = [
            ('header', f"╔══ COBRA SYSTEM DASHBOARD ══╗\n"),
            ('normal', f"║ CPU Usage: {stats.get_cpu_usage()}%\n"),
            ('normal', f"║ Memory: {stats.get_memory_usage()}\n"),
            ('normal', f"║ Network:\n"),
        ]
        for line in stats.get_network_info().split('\n'):
            text.append(('normal', f"║   {line}\n"))
        text.append(('header', f"╚{'═' * 28}╝\n"))
        self.text_widget = urwid.Text(text)

    def update(self):
        self.update_text()
        self._w = urwid.AttrMap(self.text_widget, 'body')

class CobraUI:
    palette = [
        ('header', 'light green', 'black'),
        ('normal', 'light gray', 'black'),
        ('body', 'white', 'black'),
    ]

    def __init__(self):
        try:
            self.dashboard = DashboardWidget()
            self.main_widget = urwid.Padding(
                urwid.Filler(self.dashboard),
                align='center',
                width=('relative', 80)
            )
            self.loop = urwid.MainLoop(
                self.main_widget,
                self.palette,
                unhandled_input=self.handle_input,
                handle_mouse=False
            )
        except Exception as e:
            print(f"Failed to initialize UI: {str(e)}")
            sys.exit(1)

    def handle_input(self, key):
        if key in ('q', 'Q'):
            raise urwid.ExitMainLoop()
        elif key in ('r', 'R'):
            self.dashboard.update()

    def run(self):
        self.loop.set_alarm_in(1, self.update)
        self.loop.run()

    def update(self, loop, user_data):
        self.dashboard.update()
        loop.set_alarm_in(1, self.update)

if __name__ == '__main__':
    import sys
    try:
        ui = CobraUI()
        ui.run()
    except KeyboardInterrupt:
        sys.exit(0)
    except Exception as e:
        print(f"Error running UI: {str(e)}")
        sys.exit(1)
EOF

chmod +x "$UI_SCRIPT" || handle_error "Failed to make UI script executable"
verify_file "$UI_SCRIPT"

# Create launcher script with error handling
LAUNCHER_SCRIPT="/opt/cobra/scripts/cobra"
cat > "$LAUNCHER_SCRIPT" << 'EOF' || handle_error "Failed to create launcher script"
#!/bin/bash
cd /opt/cobra/ui
./cobra_ui.py
EOF

chmod +x "$LAUNCHER_SCRIPT" || handle_error "Failed to make launcher script executable"
verify_file "$LAUNCHER_SCRIPT"

# Set up theme configuration with error handling
echo -e "${CYAN}[*] Creating theme configuration...${NC}"
mkdir -p /opt/cobra/config/themes || handle_error "Failed to create themes directory"

# Create default theme with error handling
THEME_CONFIG="/opt/cobra/config/themes/config.json"
cat > "$THEME_CONFIG" << 'EOF' || handle_error "Failed to create theme configuration"
{
    "current_theme": "hacker-green",
    "themes": {
        "hacker-green": {
            "primary": "#00ff00",
            "secondary": "#008000",
            "background": "#000000",
            "text": "#00ff00"
        },
        "cyber-purple": {
            "primary": "#800080",
            "secondary": "#ff00ff",
            "background": "#000000",
            "text": "#ff00ff"
        },
        "neon-pink": {
            "primary": "#ff1493",
            "secondary": "#ff69b4",
            "background": "#000000",
            "text": "#ff1493"
        }
    }
}
EOF

# Configure i3 window manager with error handling
echo -e "${CYAN}[*] Configuring i3 window manager...${NC}"
I3_CONFIG_DIR="/etc/skel/.config/i3"
I3_CONFIG="$I3_CONFIG_DIR/config"
mkdir -p "$I3_CONFIG_DIR" || handle_error "Failed to create i3 config directory"
cat > "$I3_CONFIG" << 'EOF' || handle_error "Failed to create i3 configuration"
# i3 config file
set $mod Mod4

# Font
font pango:monospace 8

# Start terminal
bindsym $mod+Return exec urxvt

# Kill focused window
bindsym $mod+Shift+q kill

# Start dmenu
bindsym $mod+d exec dmenu_run

# Change focus
bindsym $mod+j focus left
bindsym $mod+k focus down
bindsym $mod+l focus up
bindsym $mod+semicolon focus right

# Move focused window
bindsym $mod+Shift+j move left
bindsym $mod+Shift+k move down
bindsym $mod+Shift+l move up
bindsym $mod+Shift+semicolon move right

# Split in horizontal orientation
bindsym $mod+h split h

# Split in vertical orientation
bindsym $mod+v split v

# Enter fullscreen mode
bindsym $mod+f fullscreen toggle

# Change container layout
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Toggle tiling / floating
bindsym $mod+Shift+space floating toggle

# Change focus between tiling / floating windows
bindsym $mod+space focus mode_toggle

# Focus the parent container
bindsym $mod+a focus parent

# Define names for workspaces
set $ws1 "1:Terminal"
set $ws2 "2:Browser"
set $ws3 "3:Code"
set $ws4 "4:Tools"

# Switch to workspace
bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4

# Move focused container to workspace
bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4

# Reload the configuration file
bindsym $mod+Shift+c reload

# Restart i3 inplace
bindsym $mod+Shift+r restart

# Exit i3
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Exit i3?' -B 'Yes' 'i3-msg exit'"

# Start i3bar
bar {
    status_command i3status
    colors {
        background #000000
        statusline #00ff00
        separator #666666

        focused_workspace  #00ff00 #000000 #00ff00
        active_workspace   #333333 #5f676a #ffffff
        inactive_workspace #000000 #000000 #888888
        urgent_workspace   #2f343a #900000 #ffffff
    }
}

# Auto-start applications
exec --no-startup-id nitrogen --restore
exec --no-startup-id compton
exec --no-startup-id /opt/cobra/scripts/cobra
EOF

# Configure URxvt with error handling
echo -e "${CYAN}[*] Configuring terminal...${NC}"
XRESOURCES="/etc/skel/.Xresources"
cat > "$XRESOURCES" << 'EOF' || handle_error "Failed to create Xresources configuration"
URxvt*background: Black
URxvt*foreground: Green
URxvt*color0: Black
URxvt*color1: Red3
URxvt*color2: Green3
URxvt*color3: Yellow3
URxvt*color4: Blue3
URxvt*color5: Magenta3
URxvt*color6: Cyan3
URxvt*color7: AntiqueWhite
URxvt*color8: Grey25
URxvt*color9: Red
URxvt*color10: Green
URxvt*color11: Yellow
URxvt*color12: Blue
URxvt*color13: Magenta
URxvt*color14: Cyan
URxvt*color15: White
URxvt*scrollBar: false
URxvt*font: xft:Monospace:size=10
URxvt*boldFont: xft:Monospace:bold:size=10
URxvt*letterSpace: -1
URxvt*borderLess: true
URxvt*depth: 32
EOF

echo -e "${GREEN}[*] UI setup complete!${NC}"
