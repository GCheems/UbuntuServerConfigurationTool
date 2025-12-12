# Ubuntu 服务器配置工具

<div align="center">

**一键解决中国大陆服务器网络访问问题**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Ubuntu-orange.svg)](https://ubuntu.com/)
[![Shell](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)

让你的国内服务器像在海外一样自由访问 GitHub、Docker Hub 等服务

</div>

---

## 📖 简介

这是一个专为中国大陆 Ubuntu 服务器设计的一键配置工具，通过配置国内镜像源和网络优化，解决以下问题：

- ✅ **APT 更新慢** - 配置阿里云/清华等国内镜像源
- ✅ **Docker 拉取超时** - 配置多个 Docker 镜像加速器
- ✅ **GitHub 无法访问** - 配置 GitHub 镜像代理
- ✅ **NPM 安装缓慢** - 配置淘宝 NPM 镜像
- ✅ **pip 安装失败** - 配置清华/阿里云 Python 镜像
- ✅ **DNS 解析慢** - 配置国内 DNS 服务器

## 🚀 快速开始

### 下载工具

```bash
# 克隆仓库
git clone https://github.com/yourusername/server-config-tool.git
cd server-config-tool

# 或直接下载
wget https://github.com/yourusername/server-config-tool/archive/main.zip
unzip main.zip
cd server-config-tool-main
```

### 一键配置

```bash
# 赋予执行权限
chmod +x install.sh

# 运行配置（需要 root 权限）
sudo ./install.sh
```

就这么简单！工具会显示交互式菜单，你可以选择：
- **选项 1**: 一键配置所有服务（推荐）
- **选项 2-7**: 单独配置某个服务

## ✨ 功能特性

### 🔧 核心功能

| 服务 | 功能 | 说明 |
|------|------|------|
| **APT** | 软件源加速 | 支持阿里云、清华、中科大等多个镜像源 |
| **Docker** | 镜像拉取加速 | 配置多个国内镜像加速器，自动安装 Docker |
| **Git/GitHub** | 访问加速 | 支持镜像代理、HTTP 代理、SSH 代理多种方式 |
| **NPM/Yarn** | 包管理加速 | 配置淘宝镜像，可选安装 cnpm |
| **Python pip** | 包安装加速 | 配置国内 pip 镜像，支持用户级和系统级 |
| **DNS** | 域名解析优化 | 配置阿里/腾讯等国内 DNS，支持自定义 |

### 🛡️ 安全特性

- ✅ **自动备份** - 修改前自动备份所有配置文件
- ✅ **一键恢复** - 支持恢复到任意历史配置
- ✅ **日志记录** - 所有操作都有详细日志
- ✅ **权限检查** - 确保在 root 权限下运行
- ✅ **版本检测** - 自动适配不同 Ubuntu 版本

### 💡 人性化设计

- 🎨 彩色输出，操作状态一目了然
- 📋 交互式菜单，简单易用
- 🔍 配置查看，随时了解当前状态
- 🧪 网络测试，验证配置是否生效
- 📊 备份统计，管理历史配置

## 📚 使用指南

### 主菜单说明

运行 `sudo ./install.sh` 后会看到主菜单：

```
主菜单:

  配置选项:
    [1] 一键配置所有服务
    [2] 配置 APT 软件源
    [3] 配置 Docker 镜像加速
    [4] 配置 Git/GitHub 加速
    [5] 配置 NPM/Yarn 镜像
    [6] 配置 Python pip 镜像
    [7] 配置 DNS 服务器

  管理选项:
    [8] 查看当前配置
    [9] 备份管理
    [10] 测试网络连接

  其他:
    [0] 退出
```

### 常见使用场景

#### 场景 1: 新服务器初始化

```bash
# 运行工具
sudo ./install.sh

# 选择选项 1 - 一键配置所有服务
# 按提示选择镜像源（通常选择默认即可）
# 等待配置完成
```

#### 场景 2: 只需要配置 Docker

```bash
sudo ./install.sh

# 选择选项 3 - 配置 Docker 镜像加速
# 如果未安装，工具会自动安装 Docker
# 配置完成后会自动测试拉取镜像
```

#### 场景 3: 恢复原始配置

```bash
sudo ./install.sh

# 选择选项 9 - 备份管理
# 选择选项 2 - 恢复备份
# 输入备份文件路径进行恢复
```

### 备份管理

所有备份文件存储在 `/opt/server-config-tool/backups/`

```bash
# 查看备份列表
sudo ./install.sh
# 选择 9 -> 1

# 恢复备份
sudo ./install.sh
# 选择 9 -> 2

# 清理旧备份
sudo ./install.sh
# 选择 9 -> 3
```

### 卸载工具

如需恢复所有配置到原始状态：

```bash
sudo ./uninstall.sh
```

卸载脚本会：
1. 恢复所有配置文件到修改前的状态
2. 询问是否删除备份文件
3. 询问是否删除日志文件

## 🔍 配置详情

### APT 软件源

**可选镜像:**
- 阿里云镜像（推荐）
- 清华大学镜像
- 中国科学技术大学镜像
- 网易镜像
- 华为云镜像

**配置文件:** `/etc/apt/sources.list`

**验证:**
```bash
sudo apt update
```

### Docker 镜像加速

**配置的镜像:**
- 阿里云 Docker 镜像
- 网易云 Docker 镜像
- 中科大 Docker 镜像
- 腾讯云 Docker 镜像

**配置文件:** `/etc/docker/daemon.json`

**验证:**
```bash
docker pull hello-world
```

### Git/GitHub 加速

**支持的方式:**
1. **GitHub 镜像代理**（推荐）- 自动替换 GitHub URL
2. **HTTP/HTTPS 代理** - 需要自备代理服务器
3. **Git Clone 加速脚本** - 提供 `gitclone` 命令

**配置文件:** `~/.gitconfig`

**使用示例:**
```bash
# 方式 1: 正常使用 git clone（会自动使用镜像）
git clone https://github.com/user/repo.git

# 方式 3: 使用 gitclone 命令
gitclone https://github.com/user/repo.git
```

### NPM/Yarn 镜像

**配置的镜像:**
- 淘宝 NPM 镜像（npmmirror.com）
- Electron、Sass、ChromeDriver 等二进制镜像

**配置文件:** `~/.npmrc`

**验证:**
```bash
npm config get registry
# 应显示: https://registry.npmmirror.com
```

### Python pip 镜像

**可选镜像:**
- 清华大学镜像（推荐）
- 阿里云镜像
- 中科大镜像
- 豆瓣镜像

**配置文件:** 
- 用户级: `~/.pip/pip.conf`
- 系统级: `/etc/pip/pip.conf`

**验证:**
```bash
pip config list
```

### DNS 服务器

**可选 DNS:**
- 阿里云 DNS (223.5.5.5)
- 腾讯 DNS (119.29.29.29)
- 百度 DNS (180.76.76.76)
- 114 DNS (114.114.114.114)
- 自定义 DNS

**配置方式:**
- systemd-resolved: `/etc/systemd/resolved.conf`
- 传统方式: `/etc/resolv.conf`

## 🧪 测试功能

工具提供网络测试功能（主菜单选项 10）：

```bash
测试网络连接...
=================================================
[→] 测试 百度 (baidu.com)...
[✓] 百度 连接正常
[→] 测试 GitHub (github.com)...
[✓] GitHub 连接正常
[→] 测试 NPM Registry (registry.npmjs.org)...
[✓] NPM Registry 连接正常
...
```

## 📂 目录结构

```
服务器配置工具/
├── install.sh              # 主安装脚本
├── uninstall.sh           # 卸载脚本
├── lib/                   # 工具函数库
│   ├── common.sh          # 通用函数
│   └── backup.sh          # 备份管理
├── modules/               # 配置模块
│   ├── apt-config.sh      # APT 配置
│   ├── docker-config.sh   # Docker 配置
│   ├── git-config.sh      # Git 配置
│   ├── npm-config.sh      # NPM 配置
│   ├── pip-config.sh      # pip 配置
│   └── dns-config.sh      # DNS 配置
├── config/                # 配置文件
│   └── mirrors.conf       # 镜像源配置
├── templates/             # 配置模板
│   ├── sources.list.template
│   ├── daemon.json.template
│   └── pip.conf.template
└── README.md              # 本文档
```

## 💻 系统要求

- **操作系统:** Ubuntu 18.04 / 20.04 / 22.04 / 24.04
- **权限:** root 或 sudo 权限
- **网络:** 需要能够访问国内镜像源

## ❓ 常见问题

### Q: 配置后还是很慢怎么办？

A: 可以尝试：
1. 切换到其他镜像源（主菜单重新配置）
2. 检查网络连接（选项 10）
3. 查看日志排查问题 (`/opt/server-config-tool/logs/`)

### Q: 配置错了怎么恢复？

A: 两种方式：
1. 使用备份恢复功能（主菜单选项 9）
2. 运行卸载脚本 `sudo ./uninstall.sh`

### Q: 支持其他 Linux 发行版吗？

A: 目前只支持 Ubuntu。其他 Debian 系发行版可能部分兼容，但未经测试。

### Q: 会不会影响现有配置？

A: 工具会在修改前自动备份所有配置文件，可以随时恢复。

### Q: 如何添加自定义镜像源？

A: 编辑 `config/mirrors.conf` 文件，按照现有格式添加新的镜像源。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

感谢以下镜像源提供商：
- [阿里云开源镜像站](https://developer.aliyun.com/mirror/)
- [清华大学开源镜像站](https://mirrors.tuna.tsinghua.edu.cn/)
- [中国科学技术大学镜像站](https://mirrors.ustc.edu.cn/)
- [淘宝 NPM 镜像](https://npmmirror.com/)
- 以及其他所有镜像源提供商

---

<div align="center">

**如果这个工具帮助到了你，请给个 ⭐ Star！**

Made with ❤️ for Chinese Developers

</div>
