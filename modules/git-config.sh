#!/bin/bash

# Git/GitHub 配置模块

MODULE_NAME="git"

configure_git() {
    step "开始配置 Git/GitHub 加速..."
    
    # 检查 Git 是否安装
    if ! command_exists git; then
        warn "Git 未安装"
        
        if confirm "是否现在安装 Git?" "y"; then
            apt-get update
            apt-get install -y git
            success "Git 安装成功"
        else
            info "跳过 Git 配置"
            return 0
        fi
    else
        info "检测到 Git 已安装"
        git --version
    fi
    
    separator
    echo -e "${GREEN}GitHub 加速方式:${NC}"
    echo "  [1] 配置 GitHub 镜像代理（推荐）"
    echo "  [2] 配置 Git 代理"
    echo "  [3] 仅加速 Git Clone"
    echo "  [4] 跳过配置"
    echo ""
    
    local choice
    read -p "请选择 [1-4]: " choice
    
    case $choice in
        1)
            configure_github_mirror
            ;;
        2)
            configure_git_proxy
            ;;
        3)
            configure_git_clone_acceleration
            ;;
        4)
            info "跳过 Git 配置"
            return 0
            ;;
        *)
            error "无效的选择"
            return 1
            ;;
    esac
}

# 配置 GitHub 镜像代理
configure_github_mirror() {
    step "配置 GitHub 镜像代理..."
    
    # 创建或备份 git config
    local git_config="$HOME/.gitconfig"
    if [ -f "$git_config" ]; then
        backup_config "$git_config" "$MODULE_NAME"
    fi
    
    # 显示可用镜像
    separator
    echo -e "${GREEN}可用的 GitHub 镜像:${NC}"
    separator
    
    local index=1
    for mirror in "${GITHUB_MIRRORS[@]}"; do
        IFS='|' read -r url desc <<< "$mirror"
        echo "  [$index] $desc"
        echo "      $url"
        ((index++))
    done
    echo ""
    
    local selected_index
    read -p "请选择镜像 [1-${#GITHUB_MIRRORS[@]}，默认1]: " selected_index
    selected_index=${selected_index:-1}
    
    local selected_mirror="${GITHUB_MIRRORS[$((selected_index-1))]}"
    IFS='|' read -r mirror_url mirror_desc <<< "$selected_mirror"
    
    info "已选择: $mirror_desc"
    
    # 配置 GitHub URL 替换
    git config --global url."${mirror_url}https://github.com/".insteadOf "https://github.com/"
    
    success "GitHub 镜像代理配置完成"
    
    separator
    info "使用方式: 正常使用 git clone https://github.com/xxx/xxx"
    info "实际会从: ${mirror_url}https://github.com/xxx/xxx 克隆"
    separator
}

# 配置 Git 代理
configure_git_proxy() {
    step "配置 Git 代理..."
    
    warn "此功能需要您有可用的代理服务器"
    
    echo "请输入代理地址（例如: http://127.0.0.1:7890 或 socks5://127.0.0.1:1080）"
    read -p "代理地址: " proxy_url
    
    if [ -z "$proxy_url" ]; then
        error "代理地址不能为空"
        return 1
    fi
    
    # 备份配置
    local git_config="$HOME/.gitconfig"
    if [ -f "$git_config" ]; then
        backup_config "$git_config" "$MODULE_NAME"
    fi
    
    # 配置 HTTP/HTTPS 代理
    git config --global http.proxy "$proxy_url"
    git config --global https.proxy "$proxy_url"
    
    success "Git 代理配置完成"
    
    # 询问是否配置 SSH 代理
    if confirm "是否配置 Git SSH 代理?" "n"; then
        configure_git_ssh_proxy "$proxy_url"
    fi
    
    show_git_config
}

# 配置 Git SSH 代理
configure_git_ssh_proxy() {
    local proxy_url="$1"
    
    step "配置 Git SSH 代理..."
    
    local ssh_config="$HOME/.ssh/config"
    
    # 确保 .ssh 目录存在
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # 备份 SSH 配置
    if [ -f "$ssh_config" ]; then
        backup_config "$ssh_config" "git_ssh"
    fi
    
    # 解析代理地址
    local proxy_host=$(echo "$proxy_url" | sed -E 's|^.*://([^:]+):.*$|\1|')
    local proxy_port=$(echo "$proxy_url" | sed -E 's|^.*:([0-9]+)$|\1|')
    
    # 添加 SSH 配置
    cat >> "$ssh_config" << EOF

# GitHub SSH Proxy - Added by Server Config Tool
Host github.com
    HostName github.com
    User git
    ProxyCommand nc -X connect -x $proxy_host:$proxy_port %h %p
EOF
    
    chmod 600 "$ssh_config"
    
    success "Git SSH 代理配置完成"
}

# 配置 Git Clone 加速
configure_git_clone_acceleration() {
    step "配置 Git Clone 加速..."
    
    info "创建 git clone 加速脚本..."
    
    # 创建加速脚本
    local script_path="/usr/local/bin/gitclone"
    
    cat > "$script_path" << 'EOF'
#!/bin/bash
# Git Clone 加速脚本

if [ $# -eq 0 ]; then
    echo "用法: gitclone <github_url> [destination]"
    exit 1
fi

GITHUB_URL="$1"
DEST="$2"

# 检查是否为 GitHub URL
if [[ "$GITHUB_URL" != *"github.com"* ]]; then
    echo "错误: 仅支持 GitHub URL"
    exit 1
fi

# 使用镜像
MIRROR_URL="https://mirror.ghproxy.com/"
ACCELERATED_URL="${MIRROR_URL}${GITHUB_URL}"

echo "使用加速镜像克隆..."
echo "原始: $GITHUB_URL"
echo "镜像: $ACCELERATED_URL"

if [ -z "$DEST" ]; then
    git clone "$ACCELERATED_URL"
else
    git clone "$ACCELERATED_URL" "$DEST"
fi
EOF
    
    chmod +x "$script_path"
    
    success "加速脚本已创建: $script_path"
    
    separator
    info "使用方式:"
    echo "  gitclone https://github.com/user/repo.git"
    echo "  gitclone https://github.com/user/repo.git mydir"
    separator
}

# 移除 Git 配置
remove_git_config() {
    step "移除 Git 配置..."
    
    # 移除 URL 替换配置
    git config --global --unset-all url."https://mirror.ghproxy.com/https://github.com/".insteadOf 2>/dev/null
    
    # 移除代理配置
    git config --global --unset http.proxy 2>/dev/null
    git config --global --unset https.proxy 2>/dev/null
    
    success "Git 配置已移除"
}

# 显示 Git 配置
show_git_config() {
    separator
    echo -e "${GREEN}当前 Git 配置:${NC}"
    separator
    
    echo -e "${BLUE}代理设置:${NC}"
    git config --global --get http.proxy && echo "  HTTP: $(git config --global --get http.proxy)" || echo "  HTTP: 未配置"
    git config --global --get https.proxy && echo "  HTTPS: $(git config --global --get https.proxy)" || echo "  HTTPS: 未配置"
    
    echo ""
    echo -e "${BLUE}URL 替换:${NC}"
    git config --global --get-regexp "^url\." || echo "  未配置"
    
    separator
}

# 测试 GitHub 连接
test_github() {
    step "测试 GitHub 连接..."
    
    info "测试 HTTPS 连接..."
    if test_http "https://github.com" 10; then
        success "GitHub HTTPS 连接正常"
    else
        warn "GitHub HTTPS 连接失败"
    fi
    
    info "测试 SSH 连接..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        success "GitHub SSH 连接正常"
    else
        warn "GitHub SSH 连接失败（这是正常的如果未配置 SSH 密钥）"
    fi
}
