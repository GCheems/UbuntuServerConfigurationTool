# Ubuntu Server Configuration Tool

<div align="center">

**One-Click Solution for China Mainland Server Network Issues**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Ubuntu-orange.svg)](https://ubuntu.com/)
[![Shell](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)

Enable your China-based servers to access GitHub, Docker Hub, and other services seamlessly

[中文文档](README.md)

</div>

---

## 📖 Introduction

A one-click configuration tool designed for Ubuntu servers in mainland China. It solves network access issues by configuring domestic mirror sources and network optimizations:

- ✅ **Slow APT Updates** - Configure Aliyun/Tsinghua mirrors
- ✅ **Docker Pull Timeouts** - Configure multiple Docker registry mirrors
- ✅ **GitHub Access Issues** - Configure GitHub proxy mirrors
- ✅ **Slow NPM Installs** - Configure Taobao NPM mirror
- ✅ **pip Install Failures** - Configure Tsinghua/Aliyun Python mirrors
- ✅ **Slow DNS Resolution** - Configure domestic DNS servers

## 🚀 Quick Start

### Download

```bash
# Clone repository
git clone https://github.com/yourusername/server-config-tool.git
cd server-config-tool

# Or download directly
wget https://github.com/yourusername/server-config-tool/archive/main.zip
unzip main.zip
cd server-config-tool-main
```

### One-Click Configuration

```bash
# Grant execute permission
chmod +x install.sh

# Run configuration (requires root)
sudo ./install.sh
```

That's it! The tool displays an interactive menu where you can choose:
- **Option 1**: Configure all services at once (recommended)
- **Options 2-7**: Configure individual services

## ✨ Features

### 🔧 Core Functions

| Service | Function | Description |
|---------|----------|-------------|
| **APT** | Package Source Acceleration | Support for Aliyun, Tsinghua, USTC mirrors |
| **Docker** | Registry Mirror Acceleration | Configure multiple domestic mirrors, auto-install Docker |
| **Git/GitHub** | Access Acceleration | Support mirror proxy, HTTP proxy, SSH proxy |
| **NPM/Yarn** | Package Manager Acceleration | Configure Taobao mirror, optional cnpm |
| **Python pip** | Package Installation Acceleration | Configure domestic pip mirrors, user & system level |
| **DNS** | Domain Resolution Optimization | Configure Aliyun/Tencent DNS, custom support |

### 🛡️ Security Features

- ✅ **Auto Backup** - Automatically backup all config files before modification
- ✅ **One-Click Restore** - Restore to any historical configuration
- ✅ **Logging** - Detailed logs for all operations
- ✅ **Permission Check** - Ensure running with root privileges
- ✅ **Version Detection** - Auto-adapt to different Ubuntu versions

### 💡 User-Friendly Design

- 🎨 Colorful output for clear operation status
- 📋 Interactive menu, easy to use
- 🔍 Configuration viewer to check current status
- 🧪 Network testing to verify configuration
- 📊 Backup statistics for managing history

## 📚 Usage Guide

### Main Menu

After running `sudo ./install.sh`:

```
Main Menu:

  Configuration Options:
    [1] Configure All Services
    [2] Configure APT Sources
    [3] Configure Docker Mirrors
    [4] Configure Git/GitHub Acceleration
    [5] Configure NPM/Yarn Mirrors
    [6] Configure Python pip Mirrors
    [7] Configure DNS Servers

  Management Options:
    [8] View Current Configuration
    [9] Backup Management
    [10] Test Network Connection

  Other:
    [0] Exit
```

### Common Scenarios

#### Scenario 1: New Server Initialization

```bash
sudo ./install.sh
# Select option 1 - Configure all services
# Follow prompts to select mirrors (default is usually fine)
# Wait for completion
```

#### Scenario 2: Configure Docker Only

```bash
sudo ./install.sh
# Select option 3 - Configure Docker mirrors
# Tool will auto-install Docker if not present
# Auto-test after configuration
```

#### Scenario 3: Restore Original Configuration

```bash
sudo ./install.sh
# Select option 9 - Backup Management
# Select option 2 - Restore Backup
# Input backup file path to restore
```

### Uninstall

To restore all configurations to original state:

```bash
sudo ./uninstall.sh
```

The uninstall script will:
1. Restore all configuration files
2. Ask whether to delete backup files
3. Ask whether to delete log files

## 📂 Directory Structure

```
server-config-tool/
├── install.sh              # Main installation script
├── uninstall.sh           # Uninstall script
├── lib/                   # Utility libraries
│   ├── common.sh          # Common functions
│   └── backup.sh          # Backup management
├── modules/               # Configuration modules
│   ├── apt-config.sh
│   ├── docker-config.sh
│   ├── git-config.sh
│   ├── npm-config.sh
│   ├── pip-config.sh
│   └── dns-config.sh
├── config/                # Configuration files
│   └── mirrors.conf
├── templates/             # Configuration templates
│   ├── sources.list.template
│   ├── daemon.json.template
│   └── pip.conf.template
├── README.md              # Chinese documentation
└── README_EN.md           # This file
```

## 💻 System Requirements

- **OS:** Ubuntu 18.04 / 20.04 / 22.04 / 24.04
- **Permissions:** root or sudo access
- **Network:** Access to domestic mirror sources required

## ❓ FAQ

### Q: Still slow after configuration?

A: Try:
1. Switch to another mirror source
2. Check network connection (option 10)
3. Review logs (`/opt/server-config-tool/logs/`)

### Q: How to recover from wrong configuration?

A: Two ways:
1. Use backup restore (main menu option 9)
2. Run uninstall script `sudo ./uninstall.sh`

### Q: Support for other Linux distributions?

A: Currently Ubuntu only. Other Debian-based distros may partially work but are untested.

### Q: Will it affect existing configurations?

A: Tool automatically backs up all config files before modification. You can restore anytime.

## 🤝 Contributing

Issues and Pull Requests are welcome!

## 📄 License

MIT License - See [LICENSE](LICENSE) file

## 🙏 Acknowledgments

Thanks to mirror source providers:
- [Aliyun Mirror](https://developer.aliyun.com/mirror/)
- [Tsinghua University Mirror](https://mirrors.tuna.tsinghua.edu.cn/)
- [USTC Mirror](https://mirrors.ustc.edu.cn/)
- [Taobao NPM Mirror](https://npmmirror.com/)
- And all other mirror providers

---

<div align="center">

**If this tool helps you, please give it a ⭐ Star!**

Made with ❤️ for Chinese Developers

</div>
