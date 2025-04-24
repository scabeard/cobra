#!/bin/bash

# Cobra Base System Installation
# Handles core system setup and essential packages

# Exit on any error
set -e

# Color definitions
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Function to check if a package is installed
check_package() {
    dpkg -l "$1" &> /dev/null
}

# Function to handle errors
handle_error() {
    echo -e "${RED}[!] Error: $1${NC}"
    exit 1
}

echo -e "${GREEN}[*] Starting base system setup...${NC}"

# Check internet connectivity
echo -e "${CYAN}[*] Checking internet connection...${NC}"
if ! ping -c 1 google.com &> /dev/null; then
    handle_error "No internet connection available"
fi

# Check if apt is locked
if fuser /var/lib/dpkg/lock &> /dev/null; then
    handle_error "Package manager is locked. Please wait for other installations to complete"
fi

# Update package lists with error handling
echo -e "${CYAN}[*] Updating package lists...${NC}"
apt update || handle_error "Failed to update package lists"
apt upgrade -y || handle_error "Failed to upgrade packages"

# Install essential system utilities with error handling
echo -e "${CYAN}[*] Installing essential utilities...${NC}"
apt install -y --no-install-recommends \
    build-essential \
    curl \
    wget \
    git \
    tmux \
    htop \
    neofetch \
    net-tools \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install X Window System (minimal)
echo -e "${CYAN}[*] Installing minimal X Window System...${NC}"
apt install -y \
    xorg \
    i3 \
    rxvt-unicode \
    firefox-esr

# Install Python development environment
echo -e "${CYAN}[*] Setting up Python environment...${NC}"
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev

# Install basic development tools
echo -e "${CYAN}[*] Installing development tools...${NC}"
apt install -y \
    gcc \
    g++ \
    make \
    cmake \
    gdb \
    vim \
    nano

# Create necessary directories
echo -e "${CYAN}[*] Creating system directories...${NC}"
mkdir -p /opt/cobra/tools
mkdir -p /opt/cobra/config
mkdir -p /opt/cobra/scripts

# Set up system environment
echo -e "${CYAN}[*] Configuring system environment...${NC}"
cat > /etc/profile.d/cobra.sh << 'EOF'
# Cobra Environment Settings
export COBRA_HOME=/opt/cobra
export PATH=$PATH:$COBRA_HOME/scripts
export TERM=xterm-256color
EOF

# Clean up
echo -e "${CYAN}[*] Cleaning up...${NC}"
apt autoremove -y
apt clean

echo -e "${GREEN}[*] Base system setup complete!${NC}"
