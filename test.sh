#!/bin/bash

# Cobra Installation Test Script
# Verifies system requirements and dependencies

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to check requirements
check_requirement() {
    echo -ne "${CYAN}[*] Checking for $1...${NC}"
    if eval $2 &>/dev/null; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        echo -e "${YELLOW}[!] $3${NC}"
        return 1
    }
}

# Function to check package manager
check_package_manager() {
    echo -ne "${CYAN}[*] Checking package manager...${NC}"
    if command -v apt &>/dev/null; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        echo -e "${YELLOW}[!] This script requires a Debian-based Linux distribution${NC}"
        return 1
    }
}

# Function to check disk space
check_disk_space() {
    local required_space=10 # GB
    local available_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    
    echo -ne "${CYAN}[*] Checking available disk space...${NC}"
    if [ "$available_space" -ge "$required_space" ]; then
        echo -e "${GREEN}OK${NC}"
        echo -e "${CYAN}    Available: ${available_space}GB, Required: ${required_space}GB${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        echo -e "${YELLOW}[!] Not enough disk space. Available: ${available_space}GB, Required: ${required_space}GB${NC}"
        return 1
    }
}

# Function to check memory
check_memory() {
    local required_mem=2 # GB
    local available_mem=$(free -g | awk '/^Mem:/{print $2}')
    
    echo -ne "${CYAN}[*] Checking available memory...${NC}"
    if [ "$available_mem" -ge "$required_mem" ]; then
        echo -e "${GREEN}OK${NC}"
        echo -e "${CYAN}    Available: ${available_mem}GB, Required: ${required_mem}GB${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        echo -e "${YELLOW}[!] Not enough memory. Available: ${available_mem}GB, Required: ${required_mem}GB${NC}"
        return 1
    }
}

# Function to check internet connectivity
check_internet() {
    echo -ne "${CYAN}[*] Checking internet connectivity...${NC}"
    if ping -c 1 google.com &>/dev/null; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        echo -e "${YELLOW}[!] No internet connection available${NC}"
        return 1
    }
}

# Main test sequence
echo -e "${GREEN}[*] Starting Cobra installation test...${NC}\n"

# System checks
echo -e "${CYAN}=== System Requirements ===${NC}"
check_requirement "Root privileges" "[ \$(id -u) -eq 0 ]" "This script must be run as root"
check_package_manager
check_disk_space
check_memory
check_internet

echo -e "\n${CYAN}=== Required Commands ===${NC}"
check_requirement "git" "command -v git" "git is required but not installed"
check_requirement "curl" "command -v curl" "curl is required but not installed"
check_requirement "wget" "command -v wget" "wget is required but not installed"
check_requirement "python3" "command -v python3" "python3 is required but not installed"
check_requirement "pip3" "command -v pip3" "pip3 is required but not installed"

echo -e "\n${CYAN}=== Directory Access ===${NC}"
check_requirement "Write access to /opt" "touch /opt/test_write && rm /opt/test_write" "No write access to /opt directory"
check_requirement "Write access to /etc/profile.d" "touch /etc/profile.d/test_write && rm /etc/profile.d/test_write" "No write access to /etc/profile.d directory"

echo -e "\n${CYAN}=== Service Requirements ===${NC}"
check_requirement "systemd" "command -v systemctl" "systemd is required but not installed"
check_requirement "PostgreSQL" "command -v psql" "PostgreSQL is required for Metasploit but not installed"

# Summary
echo -e "\n${CYAN}=== Test Summary ===${NC}"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✓] All requirements met! You can proceed with the installation.${NC}"
    echo -e "${CYAN}[*] Run './main.sh' to start the installation process.${NC}"
else
    echo -e "${RED}[✗] Some requirements are not met. Please address the issues above before proceeding.${NC}"
    exit 1
fi
