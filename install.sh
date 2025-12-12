#!/bin/bash

#########################################################
# Ubuntu 服务器配置工具
# 
# 用途: 一键配置国内服务器网络环境
# 支持: APT, Docker, Git/GitHub, NPM, pip, DNS
# 
# 使用方法: sudo bash install.sh
#########################################################

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载库文件
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/backup.sh"

# 加载配置文件
if [ -f "$SCRIPT_DIR/config/mirrors.conf" ]; then
    source "$SCRIPT_DIR/config/mirrors.conf"
else
    error "配置文件不存在: $SCRIPT_DIR/config/mirrors.conf"
    exit 1
fi

# 加载模块
for module in "$SCRIPT_DIR"/modules/*.sh; do
    if [ -f "$module" ]; then
        source "$module"
    fi
done

# 显示主菜单
show_main_menu() {
    while true; do
        show_banner
        
        echo -e "${GREEN}主菜单:${NC}"
        echo ""
        echo "  ${BLUE}配置选项:${NC}"
        echo "    [1] 一键配置所有服务"
        echo "    [2] 配置 APT 软件源"
        echo "    [3] 配置 Docker 镜像加速"
        echo "    [4] 配置 Git/GitHub 加速"
        echo "    [5] 配置 NPM/Yarn 镜像"
        echo "    [6] 配置 Python pip 镜像"
        echo "    [7] 配置 DNS 服务器"
        echo ""
        echo "  ${BLUE}管理选项:${NC}"
        echo "    [8] 查看当前配置"
        echo "    [9] 备份管理"
        echo "    [10] 测试网络连接"
        echo ""
        echo "  ${BLUE}其他:${NC}"
        echo "    [0] 退出"
        echo ""
        
        read -p "请选择 [0-10]: " choice
        
        case $choice in
            1)
                configure_all
                ;;
            2)
                configure_apt
                pause
                ;;
            3)
                configure_docker
                pause
                ;;
            4)
                configure_git
                pause
                ;;
            5)
                configure_npm
                pause
                ;;
            6)
                configure_pip
                pause
                ;;
            7)
                configure_dns
                pause
                ;;
            8)
                show_all_configs
                pause
                ;;
            9)
                backup_menu
                ;;
            10)
                test_network
                pause
                ;;
            0)
                info "感谢使用！"
                exit 0
                ;;
            *)
                error "无效的选择"
                pause
                ;;
        esac
    done
}

# 一键配置所有服务
configure_all() {
    separator
    echo -e "${GREEN}开始一键配置所有服务...${NC}"
    separator
    
    info "此操作将依次配置:"
    echo "  • APT 软件源"
    echo "  • Docker 镜像加速"
    echo "  • Git/GitHub 加速"
    echo "  • NPM/Yarn 镜像"
    echo "  • Python pip 镜像"
    echo "  • DNS 服务器"
    echo ""
    
    if ! confirm "确认继续?" "y"; then
        info "已取消操作"
        return 0
    fi
    
    local start_time=$(date +%s)
    
    # APT
    separator
    info "步骤 1/6: 配置 APT 软件源"
    separator
    configure_apt || warn "APT 配置失败，继续下一步..."
    
    # Docker
    separator
    info "步骤 2/6: 配置 Docker"
    separator
    configure_docker || warn "Docker 配置失败，继续下一步..."
    
    # Git
    separator
    info "步骤 3/6: 配置 Git/GitHub"
    separator
    configure_git || warn "Git 配置失败，继续下一步..."
    
    # NPM
    separator
    info "步骤 4/6: 配置 NPM/Yarn"
    separator
    configure_npm || warn "NPM 配置失败，继续下一步..."
    
    # pip
    separator
    info "步骤 5/6: 配置 Python pip"
    separator
    configure_pip || warn "pip 配置失败，继续下一步..."
    
    # DNS
    separator
    info "步骤 6/6: 配置 DNS"
    separator
    configure_dns || warn "DNS 配置失败"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    separator
    success "所有配置完成！"
    info "总耗时: ${duration} 秒"
    separator
    
    pause
}

# 显示所有配置
show_all_configs() {
    clear
    show_banner
    
    echo -e "${GREEN}=== 当前配置概览 ===${NC}"
    echo ""
    
    # APT
    echo -e "${BLUE}1. APT 软件源:${NC}"
    if [ -f /etc/apt/sources.list ]; then
        local apt_mirror=$(grep -m 1 "^deb" /etc/apt/sources.list | awk '{print $2}')
        echo "   镜像: $apt_mirror"
    else
        echo "   未配置"
    fi
    echo ""
    
    # Docker
    echo -e "${BLUE}2. Docker 镜像:${NC}"
    if command_exists docker && [ -f /etc/docker/daemon.json ]; then
        echo "   已配置"
        local mirror_count=$(grep -c "registry-mirrors" /etc/docker/daemon.json 2>/dev/null || echo 0)
        echo "   镜像数量: $mirror_count"
    else
        echo "   未配置"
    fi
    echo ""
    
    # Git
    echo -e "${BLUE}3. Git 配置:${NC}"
    if command_exists git; then
        local git_proxy=$(git config --global --get http.proxy 2>/dev/null || echo "未配置")
        echo "   HTTP 代理: $git_proxy"
    else
        echo "   Git 未安装"
    fi
    echo ""
    
    # NPM
    echo -e "${BLUE}4. NPM 镜像:${NC}"
    if command_exists npm; then
        local npm_registry=$(npm config get registry 2>/dev/null || echo "默认")
        echo "   镜像源: $npm_registry"
    else
        echo "   NPM 未安装"
    fi
    echo ""
    
    # pip
    echo -e "${BLUE}5. pip 镜像:${NC}"
    if [ -f "$HOME/.pip/pip.conf" ]; then
        local pip_mirror=$(grep "index-url" "$HOME/.pip/pip.conf" | awk '{print $3}')
        echo "   镜像源: $pip_mirror"
    else
        echo "   未配置"
    fi
    echo ""
    
    # DNS
    echo -e "${BLUE}6. DNS 服务器:${NC}"
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        echo "   使用 systemd-resolved"
    elif [ -f /etc/resolv.conf ]; then
        local dns_servers=$(grep "^nameserver" /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')
        echo "   DNS: $dns_servers"
    else
        echo "   未配置"
    fi
    
    separator
}

# 备份管理菜单
backup_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${GREEN}备份管理:${NC}"
        echo ""
        echo "  [1] 查看所有备份"
        echo "  [2] 恢复备份"
        echo "  [3] 清理旧备份"
        echo "  [4] 备份统计"
        echo "  [0] 返回主菜单"
        echo ""
        
        read -p "请选择 [0-4]: " choice
        
        case $choice in
            1)
                list_backups
                pause
                ;;
            2)
                restore_backup_interactive
                pause
                ;;
            3)
                cleanup_old_backups
                pause
                ;;
            4)
                show_backup_stats
                pause
                ;;
            0)
                return 0
                ;;
            *)
                error "无效的选择"
                pause
                ;;
        esac
    done
}

# 交互式恢复备份
restore_backup_interactive() {
    list_backups
    
    echo ""
    read -p "请输入要恢复的备份文件路径: " backup_file
    
    if [ -n "$backup_file" ] && [ -f "$backup_file" ]; then
        restore_backup "$backup_file"
    else
        error "无效的备份文件"
    fi
}

# 测试网络连接
test_network() {
    separator
    echo -e "${GREEN}测试网络连接...${NC}"
    separator
    
    local test_urls=(
        "baidu.com|百度"
        "github.com|GitHub"
        "registry.npmjs.org|NPM Registry"
        "pypi.org|Python PyPI"
        "hub.docker.com|Docker Hub"
    )
    
    for url_info in "${test_urls[@]}"; do
        IFS='|' read -r url name <<< "$url_info"
        
        step "测试 $name ($url)..."
        
        if test_connection "$url" 3; then
            success "$name 连接正常"
        else
            error "$name 连接失败"
        fi
    done
    
    separator
    
    # DNS 解析测试
    if command_exists nslookup; then
        step "测试 DNS 解析..."
        test_dns
    fi
}

# 暂停等待用户
pause() {
    echo ""
    read -p "按回车键继续..." dummy
}

# 主函数
main() {
    # 初始化环境
    init_environment
    
    # 检查 root 权限
    check_root
    
    # 检测系统版本
    detect_ubuntu_version
    
    # 显示主菜单
    show_main_menu
}

# 运行主函数
main "$@"
