# Cobra - Minimal Debian-based Pentesting Environment

Cobra is a lightweight, terminal-focused pentesting environment that provides essential security tools and a clean, efficient interface. It's designed to be installed on a Debian-based Linux distribution.

## Features

- **Terminal UI Dashboard**
  - System resource monitoring
  - Network interface tracking
  - Clean, minimalist design

- **Security Tools**
  - Network reconnaissance
  - Web application testing
  - Exploitation frameworks
  - Post-exploitation tools
  - Anonymity features

- **System Hardening**
  - MAC address randomization
  - Firewall configuration
  - Fail2ban integration
  - System auditing

- **Development Environment**
  - VSCodium editor
  - Python development tools
  - Version control integration
  - Package management

## Requirements

- Debian-based Linux distribution (Debian, Ubuntu, Kali)
- Root privileges
- 2GB RAM minimum
- 10GB free disk space
- Internet connection
- Required packages:
  - git
  - curl
  - wget
  - python3
  - pip3
  - systemd
  - PostgreSQL

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/cobra.git
   cd cobra
   ```

2. Run the test script to verify system requirements:
   ```bash
   chmod +x test.sh
   sudo ./test.sh
   ```

3. If all requirements are met, run the installation:
   ```bash
   sudo ./main.sh
   ```

4. After installation completes, reboot your system:
   ```bash
   sudo reboot
   ```

## Usage

### Terminal UI

Launch the Cobra dashboard:
```bash
cobra
```

### Tools Menu

Access the pentesting tools menu:
```bash
tools-menu
```

### Security Features

Enable lockdown mode (MAC spoofing, Tor routing):
```bash
lockdown on
```

Disable lockdown mode:
```bash
lockdown off
```

### Theme Configuration

List available themes:
```bash
theme list
```

Set a theme:
```bash
theme set <theme-name>
```

## Directory Structure

```
/opt/cobra/
├── tools/
│   ├── recon/
│   ├── exploit/
│   ├── post/
│   ├── web/
│   ├── wireless/
│   └── reverse/
├── ui/
│   └── cobra_ui.py
├── config/
│   └── themes/
└── scripts/
```

## Available Tools

### Reconnaissance
- Nmap
- NmapAutomator
- RustScan
- Whatweb
- Enum4linux

### Web Testing
- Dirsearch
- Gobuster
- Nikto
- SQLMap
- Wfuzz

### Exploitation
- Metasploit Framework
- SearchSploit
- Hydra
- John the Ripper
- Hashcat

### Post Exploitation
- LinEnum
- PSPY
- Privilege Escalation Scripts

### Anonymity
- Anonsurf
- MAC Changer
- Tor
- ProxyChains

## Configuration

### Firewall

The UFW firewall is configured with:
- Default deny incoming
- Default allow outgoing
- SSH allowed

### Fail2ban

Default configuration:
- Ban time: 1 hour
- Find time: 10 minutes
- Max retries: 3

### Network

MAC address randomization is enabled for all interfaces by default.

## Troubleshooting

1. If installation fails, check:
   - System requirements using `test.sh`
   - Internet connectivity
   - Available disk space
   - Package manager status

2. If UI doesn't launch:
   - Verify Python dependencies
   - Check system resources
   - Review error logs

3. If tools don't work:
   - Verify tool installation in `/opt/cobra/tools`
   - Check PATH configuration
   - Review permissions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Security Notice

This toolkit is intended for legal security testing and educational purposes only. Users are responsible for complying with applicable laws and regulations. The authors are not responsible for any misuse or damage caused by this tool.
