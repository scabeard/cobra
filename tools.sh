#!/bin/bash

# Cobra Tools Installation
# Handles installation of pentesting tools and frameworks

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

# Function to verify tool installation
verify_tool() {
    if ! command -v "$1" &> /dev/null; then
        handle_error "Tool '$1' was not installed correctly"
    fi
}

# Function to verify Python package installation
verify_pip_package() {
    if ! pip3 list | grep -q "^$1[[:space:]]"; then
        handle_error "Failed to install Python package: $1"
    fi
}

# Function to verify directory creation
verify_dir() {
    if [ ! -d "$1" ]; then
        handle_error "Failed to create directory: $1"
    fi
}

echo -e "${GREEN}[*] Installing pentesting tools...${NC}"

# Verify system requirements
if ! command -v apt &> /dev/null; then
    handle_error "This script requires apt package manager"
fi

if ! command -v git &> /dev/null; then
    handle_error "Git is required but not installed"
fi

# Install basic pentesting tools with error handling
echo -e "${CYAN}[*] Installing basic tools...${NC}"
apt install -y --no-install-recommends \
    nmap \
    nikto \
    hydra \
    sqlmap \
    dirb \
    gobuster \
    wfuzz \
    john \
    hashcat \
    wireshark \
    tcpdump \
    netcat-traditional \
    masscan \
    whatweb \
    exploitdb \
    wordlists \
    smbclient \
    enum4linux \
    nbtscan \
    ftp \
    telnet \
    whois \
    dnsutils \
    net-tools

# Install Metasploit Framework with error handling
echo -e "${CYAN}[*] Installing Metasploit Framework...${NC}"
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall || handle_error "Failed to download Metasploit installer"
chmod +x msfinstall || handle_error "Failed to make Metasploit installer executable"
./msfinstall || handle_error "Metasploit installation failed"
rm msfinstall

# Verify Metasploit installation
verify_tool "msfconsole"

# Initialize Metasploit database with error handling
echo -e "${CYAN}[*] Initializing Metasploit database...${NC}"
systemctl start postgresql || handle_error "Failed to start PostgreSQL"
systemctl enable postgresql || handle_error "Failed to enable PostgreSQL"
msfdb init || handle_warning "Metasploit database initialization encountered issues"

# Install additional Python-based tools with error handling
echo -e "${CYAN}[*] Installing Python-based tools...${NC}"
pip3 install --upgrade pip || handle_error "Failed to upgrade pip"

echo -e "${CYAN}[*] Installing Python packages...${NC}"
pip3 install \
    requests \
    beautifulsoup4 \
    scapy \
    impacket \
    pwntools \
    pyftpdlib \
    python-nmap \
    paramiko

# Create tools directory structure with error handling
echo -e "${CYAN}[*] Creating tools directory structure...${NC}"
for dir in recon exploit post web wireless reverse; do
    mkdir -p "/opt/cobra/tools/$dir" || handle_error "Failed to create $dir directory"
    verify_dir "/opt/cobra/tools/$dir"
done

# Install additional GitHub tools with error handling
echo -e "${CYAN}[*] Installing additional tools from GitHub...${NC}"

# Recon tools
cd /opt/cobra/tools/recon || handle_error "Failed to change to recon directory"
git clone https://github.com/21y4d/nmapAutomator.git || handle_warning "Failed to clone nmapAutomator"
git clone https://github.com/RustScan/RustScan.git || handle_warning "Failed to clone RustScan"
chmod +x nmapAutomator/nmapAutomator.sh || handle_warning "Failed to make nmapAutomator executable"

# Web tools with error handling
cd /opt/cobra/tools/web || handle_error "Failed to change to web directory"
git clone https://github.com/maurosoria/dirsearch.git || handle_warning "Failed to clone dirsearch"
git clone https://github.com/OJ/gobuster.git || handle_warning "Failed to clone gobuster"
[ -f dirsearch/dirsearch.py ] && chmod +x dirsearch/dirsearch.py || handle_warning "Failed to make dirsearch executable"

# Exploit tools with error handling
cd /opt/cobra/tools/exploit || handle_error "Failed to change to exploit directory"
git clone https://github.com/offensive-security/exploitdb.git || handle_warning "Failed to clone exploitdb"
git clone https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite.git || handle_warning "Failed to clone PEAS"

# Post-exploitation tools with error handling
cd /opt/cobra/tools/post || handle_error "Failed to change to post directory"
git clone https://github.com/DominicBreuker/pspy.git || handle_warning "Failed to clone pspy"
git clone https://github.com/rebootuser/LinEnum.git || handle_warning "Failed to clone LinEnum"

# Create tool launcher scripts with error handling
echo -e "${CYAN}[*] Creating tool launcher scripts...${NC}"

# Create dirsearch launcher
DIRSEARCH_LAUNCHER="/opt/cobra/scripts/dirsearch"
cat > "$DIRSEARCH_LAUNCHER" << 'EOF' || handle_error "Failed to create dirsearch launcher"
#!/bin/bash
python3 /opt/cobra/tools/web/dirsearch/dirsearch.py "$@"
EOF
chmod +x "$DIRSEARCH_LAUNCHER" || handle_error "Failed to make dirsearch launcher executable"
verify_file "$DIRSEARCH_LAUNCHER"

# Create nmapAutomator launcher with error handling
NMAP_AUTO_LAUNCHER="/opt/cobra/scripts/nmapAuto"
cat > "$NMAP_AUTO_LAUNCHER" << 'EOF' || handle_error "Failed to create nmapAutomator launcher"
#!/bin/bash
/opt/cobra/tools/recon/nmapAutomator/nmapAutomator.sh "$@"
EOF
chmod +x "$NMAP_AUTO_LAUNCHER" || handle_error "Failed to make nmapAutomator launcher executable"
verify_file "$NMAP_AUTO_LAUNCHER"

# Create LinEnum launcher with error handling
LINENUM_LAUNCHER="/opt/cobra/scripts/linenum"
cat > "$LINENUM_LAUNCHER" << 'EOF' || handle_error "Failed to create LinEnum launcher"
#!/bin/bash
bash /opt/cobra/tools/post/LinEnum/LinEnum.sh "$@"
EOF
chmod +x "$LINENUM_LAUNCHER" || handle_error "Failed to make LinEnum launcher executable"
verify_file "$LINENUM_LAUNCHER"

# Create tools menu script with error handling
TOOLS_MENU="/opt/cobra/scripts/tools-menu"
cat > "$TOOLS_MENU" << 'EOF' || handle_error "Failed to create tools menu"
#!/bin/bash

show_menu() {
    clear
    echo "╔══ COBRA TOOLS MENU ══╗"
    echo "║                      ║"
    echo "║ 1. Reconnaissance    ║"
    echo "║ 2. Web Testing      ║"
    echo "║ 3. Exploitation     ║"
    echo "║ 4. Post Exploit     ║"
    echo "║ 5. Metasploit       ║"
    echo "║ 6. Exit             ║"
    echo "║                      ║"
    echo "╚══════════════════════╝"
    echo
    echo "Select an option:"
}

recon_menu() {
    clear
    echo "=== Reconnaissance Tools ==="
    echo "1. Nmap"
    echo "2. NmapAutomator"
    echo "3. RustScan"
    echo "4. Back"
}

web_menu() {
    clear
    echo "=== Web Testing Tools ==="
    echo "1. Dirsearch"
    echo "2. Gobuster"
    echo "3. Nikto"
    echo "4. SQLMap"
    echo "5. Back"
}

exploit_menu() {
    clear
    echo "=== Exploitation Tools ==="
    echo "1. SearchSploit"
    echo "2. Hydra"
    echo "3. John the Ripper"
    echo "4. Back"
}

post_menu() {
    clear
    echo "=== Post Exploitation Tools ==="
    echo "1. LinEnum"
    echo "2. PSPY"
    echo "3. Back"
}

while true; do
    show_menu
    read -r opt

    case $opt in
        1) recon_menu ;;
        2) web_menu ;;
        3) exploit_menu ;;
        4) post_menu ;;
        5) msfconsole ;;
        6) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
done
EOF
chmod +x "$TOOLS_MENU" || handle_error "Failed to make tools menu executable"
verify_file "$TOOLS_MENU"

# Verify critical tool installations
for tool in nmap nikto hydra sqlmap dirb gobuster wfuzz john hashcat wireshark tcpdump netcat; do
    verify_tool "$tool" || handle_warning "Tool '$tool' may not have installed correctly"
done

# Verify Python package installations
for package in requests beautifulsoup4 scapy impacket pwntools pyftpdlib python-nmap paramiko; do
    verify_pip_package "$package" || handle_warning "Python package '$package' may not have installed correctly"
done

# Add tools directory to PATH
echo -e "${CYAN}[*] Updating PATH...${NC}"
echo 'export PATH=$PATH:/opt/cobra/scripts' >> /etc/profile.d/cobra.sh

echo -e "${GREEN}[*] Tools installation complete!${NC}"
