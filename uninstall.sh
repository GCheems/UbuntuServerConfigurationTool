#!/bin/bash

#########################################################
# Ubuntu 服务器配置工具 - 卸载脚本
# 
# 用途: 恢复所有配置到默认状态
# 
# 使用方法: sudo bash uninstall.sh
#########################################################

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载库文件
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/backup.sh"

# 显示卸载横幅
show_uninstall_banner() {
    clear
    echo -e "${RED}"
    cat << "EOF"
 _   _       _           _        _ _ 
| | | |_ __ (_)_ __  ___| |_ __ _| | |
| | | | '_ \| | '_ \/ __| __/ _` | | |
| |_| | | | | | | | \__ \ || (_| | | |
 \___/|_| |_|_|_| |_|___/\__\__,_|_|_|
 
   服务器配置工具 - 卸载程序
EOF
    echo -e "${NC}"
    separator
}

# 卸载主函数
uninstall() {
    show_uninstall_banner
    
    warn "警告: 此操作将:"
    echo "  • 移除所有配置的镜像源"
    echo "  • 恢复到默认配置"
    echo "  • 可选保留或删除备份文件"
    echo ""
    
    if ! confirm "确认继续卸载?" "n"; then
        info "已取消卸载"
        exit 0
    fi
    
    separator
    step "开始卸载..."
    separator
    
    # 1. 恢复 APT 源
    if [ -f /etc/apt/sources.list ]; then
        step "恢复 APT 源..."
        restore_module_latest "apt" 2>/dev/null || warn "未找到 APT 备份，跳过"
    fi
    
    # 2. 移除 Docker 配置
    if [ -f /etc/docker/daemon.json ]; then
        step "恢复 Docker 配置..."
        restore_module_latest "docker" 2>/dev/null || warn "未找到 Docker 备份，跳过"
        
        if systemctl is-active --quiet docker; then
            systemctl restart docker
        fi
    fi
    
    # 3. 移除 Git 配置
    if command_exists git; then
        step "移除 Git 配置..."
        git config --global --unset-all url."https://mirror.ghproxy.com/https://github.com/".insteadOf 2>/dev/null || true
        git config --global --unset http.proxy 2>/dev/null || true
        git config --global --unset https.proxy 2>/dev/null || true
        
        # 移除 gitclone 脚本
        if [ -f /usr/local/bin/gitclone ]; then
            rm -f /usr/local/bin/gitclone
        fi
    fi
    
    # 4. 移除 NPM 配置
    if command_exists npm; then
        step "恢复 NPM 配置..."
        npm config delete registry 2>/dev/null || true
        npm config delete disturl 2>/dev/null || true
        npm config delete electron_mirror 2>/dev/null || true
        npm config delete sass_binary_site 2>/dev/null || true
    fi
    
    if command_exists yarn; then
        yarn config delete registry 2>/dev/null || true
    fi
    
    # 5. 移除 pip 配置
    if [ -f "$HOME/.pip/pip.conf" ]; then
        step "移除 pip 配置..."
        rm -f "$HOME/.pip/pip.conf"
    fi
    
    if [ -f /etc/pip/pip.conf ]; then
        rm -f /etc/pip/pip.conf
    fi
    
    # 6. 恢复 DNS 配置
    step "恢复 DNS 配置..."
    
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        restore_module_latest "dns" 2>/dev/null || warn "未找到 DNS 备份，跳过"
        systemctl restart systemd-resolved 2>/dev/null || true
    else
        # 解锁 resolv.conf
        chattr -i /etc/resolv.conf 2>/dev/null || true
        restore_module_latest "dns" 2>/dev/null || warn "未找到 DNS 备份，跳过"
    fi
    
    separator
    success "配置已恢复！"
    separator
    
    # 询问是否删除备份
    if confirm "是否删除所有备份文件?" "n"; then
        remove_all_backups
    else
        info "备份文件保留在: /opt/server-config-tool/backups/"
    fi
    
    # 询问是否删除日志
    if confirm "是否删除日志文件?" "n"; then
        rm -rf /opt/server-config-tool/logs/
        success "日志文件已删除"
    else
        info "日志文件保留在: /opt/server-config-tool/logs/"
    fi
    
    separator
    success "卸载完成！"
    separator
    
    info "提示:"
    echo "  • 所有配置已恢复到修改前的状态"
    echo "  • 部分配置可能需要重启系统才能完全生效"
    echo "  • 如需完全删除，可以手动删除 /opt/server-config-tool/ 目录"
}

# 主函数
main() {
    # 初始化环境
    init_environment
    
    # 检查 root 权限
    check_root
    
    # 运行卸载
    uninstall
}

# 运行主函数
main "$@"
