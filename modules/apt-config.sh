#!/bin/bash

# APT 软件源配置模块

MODULE_NAME="apt"

configure_apt() {
    step "开始配置 APT 软件源..."
    
    # 检测系统版本
    if [ -z "$CODENAME" ]; then
        detect_ubuntu_version
    fi
    
    # 显示可用镜像
    separator
    echo -e "${GREEN}可用的 APT 镜像源:${NC}"
    separator
    
    local index=1
    for mirror in "${APT_MIRRORS[@]}"; do
        IFS='|' read -r name url desc <<< "$mirror"
        echo "  [$index] $desc ($name)"
        ((index++))
    done
    echo ""
    
    # 选择镜像
    local selected_index
    read -p "请选择镜像源 [1-${#APT_MIRRORS[@]}，默认1]: " selected_index
    selected_index=${selected_index:-1}
    
    if [ "$selected_index" -lt 1 ] || [ "$selected_index" -gt "${#APT_MIRRORS[@]}" ]; then
        error "无效的选择"
        return 1
    fi
    
    local selected_mirror="${APT_MIRRORS[$((selected_index-1))]}"
    IFS='|' read -r mirror_name mirror_url mirror_desc <<< "$selected_mirror"
    
    info "已选择: $mirror_desc"
    
    # 备份原有配置
    backup_config "/etc/apt/sources.list" "$MODULE_NAME"
    
    # 生成新的 sources.list
    local sources_template="$SCRIPT_DIR/templates/sources.list.template"
    local sources_file="/etc/apt/sources.list"
    
    if [ ! -f "$sources_template" ]; then
        error "模板文件不存在: $sources_template"
        return 1
    fi
    
    # 替换模板变量
    sed -e "s|{{MIRROR_URL}}|$mirror_url|g" \
        -e "s|{{VERSION}}|$VER|g" \
        -e "s|{{CODENAME}}|$CODENAME|g" \
        "$sources_template" > "$sources_file"
    
    success "APT 源配置已更新"
    
    # 更新软件包列表
    step "更新软件包列表..."
    if apt-get update; then
        success "软件包列表更新成功"
    else
        error "软件包列表更新失败"
        warn "建议检查网络连接或尝试其他镜像源"
        return 1
    fi
    
    separator
    success "APT 软件源配置完成！"
    separator
    
    # 显示配置信息
    info "当前使用镜像: $mirror_desc"
    info "配置文件: /etc/apt/sources.list"
    info "备份位置: /opt/server-config-tool/backups/"
}

# 测试 APT 源
test_apt_source() {
    step "测试 APT 源连接..."
    
    if apt-get update -qq 2>&1 | grep -q "Failed"; then
        error "APT 源测试失败"
        return 1
    else
        success "APT 源连接正常"
        return 0
    fi
}

# 恢复默认 APT 源
restore_apt_default() {
    warn "将恢复到 Ubuntu 官方源"
    
    if ! confirm "确认恢复?" "n"; then
        return 1
    fi
    
    backup_config "/etc/apt/sources.list" "apt_restore"
    
    cat > /etc/apt/sources.list << EOF
# Ubuntu 官方源
deb http://archive.ubuntu.com/ubuntu/ $CODENAME main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $CODENAME-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $CODENAME-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ $CODENAME-security main restricted universe multiverse
EOF
    
    success "已恢复 Ubuntu 官方源"
    
    apt-get update
}

# 显示当前 APT 配置
show_apt_config() {
    separator
    echo -e "${GREEN}当前 APT 源配置:${NC}"
    separator
    
    if [ -f /etc/apt/sources.list ]; then
        grep -v '^#' /etc/apt/sources.list | grep -v '^$' | head -n 5
    else
        error "配置文件不存在"
    fi
    
    separator
}
