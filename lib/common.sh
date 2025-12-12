#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志目录
LOG_DIR="/opt/server-config-tool/logs"
LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"

# 确保日志目录存在
ensure_log_dir() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi
}

# 日志记录函数
log() {
    local level="$1"
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# 信息输出
info() {
    echo -e "${GREEN}[INFO]${NC} $@"
    log "INFO" "$@"
}

# 警告输出
warn() {
    echo -e "${YELLOW}[WARN]${NC} $@"
    log "WARN" "$@"
}

# 错误输出
error() {
    echo -e "${RED}[ERROR]${NC} $@"
    log "ERROR" "$@"
}

# 成功输出
success() {
    echo -e "${GREEN}[✓]${NC} $@"
    log "SUCCESS" "$@"
}

# 步骤输出
step() {
    echo -e "${BLUE}[→]${NC} $@"
    log "STEP" "$@"
}

# 检查是否为 root 或有 sudo 权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "此脚本需要 root 权限，请使用 sudo 运行"
        exit 1
    fi
}

# 检测 Ubuntu 版本
detect_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        CODENAME=$VERSION_CODENAME
        
        if [[ "$OS" != *"Ubuntu"* ]]; then
            error "此脚本仅支持 Ubuntu 系统，当前系统: $OS"
            exit 1
        fi
        
        info "检测到系统: $OS $VER ($CODENAME)"
        log "INFO" "Detected OS: $OS $VER ($CODENAME)"
    else
        error "无法检测系统版本"
        exit 1
    fi
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 测试网络连接
test_connection() {
    local host="$1"
    local timeout="${2:-5}"
    
    if ping -c 1 -W "$timeout" "$host" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 测试 HTTP 连接
test_http() {
    local url="$1"
    local timeout="${2:-10}"
    
    if command_exists curl; then
        if curl -f -s -m "$timeout" "$url" >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    elif command_exists wget; then
        if wget -q -T "$timeout" -O /dev/null "$url" 2>&1; then
            return 0
        else
            return 1
        fi
    else
        warn "curl 和 wget 都不可用，无法测试 HTTP 连接"
        return 1
    fi
}

# 询问用户确认
confirm() {
    local message="$1"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        local prompt="[Y/n]"
    else
        local prompt="[y/N]"
    fi
    
    read -p "$message $prompt " response
    response=${response:-$default}
    
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# 显示分隔线
separator() {
    echo -e "${BLUE}=================================================${NC}"
}

# 显示横幅
show_banner() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
 ____                             ____             __ _       
/ ___|  ___ _ ____   _____ _ __  / ___|___  _ __  / _(_) __ _ 
\___ \ / _ \ '__\ \ / / _ \ '__|| |   / _ \| '_ \| |_| |/ _` |
 ___) |  __/ |   \ V /  __/ |   | |__| (_) | | | |  _| | (_| |
|____/ \___|_|    \_/ \___|_|    \____\___/|_| |_|_| |_|\__, |
                                                         |___/ 
        Ubuntu 服务器配置工具 v1.0
        解决国内服务器网络访问问题
EOF
    echo -e "${NC}"
    separator
}

# 创建目录（如果不存在）
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log "INFO" "Created directory: $dir"
    fi
}

# 安全备份文件
safe_backup() {
    local file="$1"
    local backup_dir="${2:-/opt/server-config-tool/backups}"
    
    ensure_dir "$backup_dir"
    
    if [ -f "$file" ]; then
        local filename=$(basename "$file")
        local backup_path="$backup_dir/${filename}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_path"
        success "已备份 $file -> $backup_path"
        echo "$backup_path"
        return 0
    else
        warn "文件不存在，跳过备份: $file"
        return 1
    fi
}

# 检查并安装必要工具
install_if_missing() {
    local package="$1"
    
    if ! command_exists "$package"; then
        step "安装 $package..."
        apt-get update -qq
        apt-get install -y "$package" >/dev/null 2>&1
        if command_exists "$package"; then
            success "$package 安装成功"
        else
            error "$package 安装失败"
            return 1
        fi
    else
        info "$package 已安装"
    fi
    return 0
}

# 显示进度条
show_progress() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${BLUE}["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "]${NC} %d%%" "$percentage"
    
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# 初始化环境
init_environment() {
    ensure_log_dir
    log "INFO" "=== Server Config Tool Started ==="
    log "INFO" "Script executed by: $USER (UID: $EUID)"
    log "INFO" "Working directory: $(pwd)"
}
