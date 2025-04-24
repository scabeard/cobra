#!/bin/bash

# Cobra Installation Script
# A minimal Debian-based pentesting environment with terminal UI

# Exit on any error
set -e

# Color definitions
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}[*] Starting Cobra Installation...${NC}"

# Check if running on Debian/Ubuntu
if [ ! -f /etc/debian_version ]; then
    echo -e "${RED}[!] Error: This script requires a Debian-based Linux distribution${NC}"
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}[!] Error: Please run as root${NC}"
    exit 1
fi

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create necessary directories
INSTALL_DIR="/opt/cobra"
mkdir -p "$INSTALL_DIR"

# Component scripts
echo -e "${PURPLE}[*] Running base system installation...${NC}"
bash "$SCRIPT_DIR/base.sh"

# Check for required commands (after base installation)
for cmd in apt wget curl git python3 pip3; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}[!] Error: Required command '$cmd' not found${NC}"
        exit 1
    fi
done

echo -e "${PURPLE}[*] Configuring security features...${NC}"
bash "$SCRIPT_DIR/security.sh"

echo -e "${PURPLE}[*] Setting up UI components...${NC}"
bash "$SCRIPT_DIR/ui.sh"

echo -e "${PURPLE}[*] Installing pentesting tools...${NC}"
bash "$SCRIPT_DIR/tools.sh"

echo -e "${PURPLE}[*] Applying configurations...${NC}"
bash "$SCRIPT_DIR/config.sh"

# Copy scripts to installation directory
cp "$SCRIPT_DIR"/*.sh "$INSTALL_DIR/"

echo -e "${GREEN}[*] Installation complete!${NC}"
echo -e "${GREEN}[*] Please reboot your system to apply all changes.${NC}"
