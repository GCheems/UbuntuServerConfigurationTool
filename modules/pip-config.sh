#!/bin/bash

# Python pip 配置模块

MODULE_NAME="pip"

configure_pip() {
    step "开始配置 Python pip..."
    
    # 检查 Python 是否安装
    local python_cmd=""
    if command_exists python3; then
        python_cmd="python3"
    elif command_exists python; then
        python_cmd="python"
    else
        warn "Python 未安装"
        
        if confirm "是否现在安装 Python?" "y"; then
            install_python
            python_cmd="python3"
        else
            info "跳过 pip 配置"
            return 0
        fi
    fi
    
    info "检测到 Python 已安装"
    $python_cmd --version
    
    # 检查 pip 是否安装
    if ! command_exists pip3 && ! command_exists pip; then
        warn "pip 未安装"
        
        if confirm "是否现在安装 pip?" "y"; then
            install_pip
        else
            info "跳过 pip 配置"
            return 0
        fi
    fi
    
    # 显示可用镜像
    separator
    echo -e "${GREEN}可用的 pip 镜像源:${NC}"
    separator
    
    local index=1
    for mirror in "${PIP_MIRRORS[@]}"; do
        IFS='|' read -r name url desc <<< "$mirror"
        echo "  [$index] $desc"
        echo "      $url"
        ((index++))
    done
    echo ""
    
    # 选择镜像
    local selected_index
    read -p "请选择镜像源 [1-${#PIP_MIRRORS[@]}，默认1]: " selected_index
    selected_index=${selected_index:-1}
    
    if [ "$selected_index" -lt 1 ] || [ "$selected_index" -gt "${#PIP_MIRRORS[@]}" ]; then
        error "无效的选择"
        return 1
    fi
    
    local selected_mirror="${PIP_MIRRORS[$((selected_index-1))]}"
    IFS='|' read -r mirror_name mirror_url mirror_desc <<< "$selected_mirror"
    
    info "已选择: $mirror_desc"
    
    # 配置 pip 镜像
    configure_pip_mirror "$mirror_url"
}

# 安装 Python
install_python() {
    step "安装 Python..."
    
    apt-get update
    apt-get install -y python3 python3-pip python3-venv
    
    if command_exists python3; then
        success "Python 安装成功"
        python3 --version
    else
        error "Python 安装失败"
        return 1
    fi
}

# 安装 pip
install_pip() {
    step "安装 pip..."
    
    apt-get update
    apt-get install -y python3-pip
    
    if command_exists pip3; then
        success "pip 安装成功"
        pip3 --version
    else
        error "pip 安装失败"
        return 1
    fi
}

# 配置 pip 镜像
configure_pip_mirror() {
    local mirror_url="$1"
    
    step "配置 pip 镜像源..."
    
    # 确定配置目录
    local pip_config_dir="$HOME/.pip"
    local pip_config_file="$pip_config_dir/pip.conf"
    
    # 创建配置目录
    ensure_dir "$pip_config_dir"
    
    # 备份现有配置
    if [ -f "$pip_config_file" ]; then
        backup_config "$pip_config_file" "$MODULE_NAME"
    fi
    
    # 提取镜像主机名（用于 trusted-host）
    local mirror_host=$(echo "$mirror_url" | sed -E 's|https?://([^/]+).*|\1|')
    
    # 生成配置文件
    local template_file="$SCRIPT_DIR/templates/pip.conf.template"
    
    if [ -f "$template_file" ]; then
        sed -e "s|{{MIRROR_URL}}|$mirror_url|g" \
            -e "s|{{MIRROR_HOST}}|$mirror_host|g" \
            "$template_file" > "$pip_config_file"
    else
        # 直接生成配置
        cat > "$pip_config_file" << EOF
[global]
index-url = $mirror_url
trusted-host = $mirror_host

[install]
trusted-host = $mirror_host
EOF
    fi
    
    success "pip 镜像源配置完成"
    
    info "配置文件: $pip_config_file"
    info "镜像地址: $mirror_url"
    
    # 也配置全局 pip
    if confirm "是否同时配置系统级 pip 镜像?（需要 root 权限）" "y"; then
        configure_global_pip_mirror "$mirror_url" "$mirror_host"
    fi
}

# 配置全局 pip 镜像
configure_global_pip_mirror() {
    local mirror_url="$1"
    local mirror_host="$2"
    
    step "配置系统级 pip 镜像..."
    
    local global_pip_dir="/etc/pip"
    local global_pip_conf="$global_pip_dir/pip.conf"
    
    # 创建目录
    ensure_dir "$global_pip_dir"
    
    # 备份
    if [ -f "$global_pip_conf" ]; then
        backup_config "$global_pip_conf" "pip_global"
    fi
    
    # 写入配置
    cat > "$global_pip_conf" << EOF
[global]
index-url = $mirror_url
trusted-host = $mirror_host

[install]
trusted-host = $mirror_host
EOF
    
    success "系统级 pip 镜像配置完成"
}

# 重置 pip 配置
reset_pip_config() {
    step "重置 pip 配置..."
    
    local pip_config_file="$HOME/.pip/pip.conf"
    
    if [ -f "$pip_config_file" ]; then
        rm -f "$pip_config_file"
        success "用户级 pip 配置已删除"
    fi
    
    local global_pip_conf="/etc/pip/pip.conf"
    
    if [ -f "$global_pip_conf" ]; then
        if confirm "是否删除系统级 pip 配置?" "n"; then
            rm -f "$global_pip_conf"
            success "系统级 pip 配置已删除"
        fi
    fi
}

# 显示 pip 配置
show_pip_config() {
    separator
    echo -e "${GREEN}pip 配置信息:${NC}"
    separator
    
    if command_exists pip3; then
        echo -e "${BLUE}pip 版本:${NC}"
        pip3 --version
        
        echo ""
        echo -e "${BLUE}用户级配置 (~/.pip/pip.conf):${NC}"
        if [ -f "$HOME/.pip/pip.conf" ]; then
            cat "$HOME/.pip/pip.conf"
        else
            echo "  未配置"
        fi
        
        echo ""
        echo -e "${BLUE}系统级配置 (/etc/pip/pip.conf):${NC}"
        if [ -f "/etc/pip/pip.conf" ]; then
            cat "/etc/pip/pip.conf"
        else
            echo "  未配置"
        fi
    elif command_exists pip; then
        echo -e "${BLUE}pip 版本:${NC}"
        pip --version
    else
        warn "pip 未安装"
    fi
    
    separator
}

# 测试 pip 镜像
test_pip() {
    step "测试 pip 镜像..."
    
    local pip_cmd="pip3"
    if ! command_exists pip3; then
        pip_cmd="pip"
    fi
    
    info "测试安装一个小包: requests"
    
    # 创建虚拟环境进行测试
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    python3 -m venv test_env
    source test_env/bin/activate
    
    if pip install requests >/dev/null 2>&1; then
        success "pip 镜像测试成功"
        deactivate
        cd - >/dev/null
        rm -rf "$temp_dir"
        return 0
    else
        error "pip 镜像测试失败"
        deactivate
        cd - >/dev/null
        rm -rf "$temp_dir"
        return 1
    fi
}

# 升级 pip
upgrade_pip() {
    step "升级 pip..."
    
    local pip_cmd="pip3"
    if ! command_exists pip3; then
        pip_cmd="pip"
    fi
    
    $pip_cmd install --upgrade pip
    
    success "pip 已升级到最新版本"
    $pip_cmd --version
}

# 清理 pip 缓存
clean_pip_cache() {
    step "清理 pip 缓存..."
    
    local pip_cmd="pip3"
    if ! command_exists pip3; then
        pip_cmd="pip"
    fi
    
    $pip_cmd cache purge
    
    success "pip 缓存已清理"
}
