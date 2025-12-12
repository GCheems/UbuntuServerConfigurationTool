#!/bin/bash

# DNS 配置模块

MODULE_NAME="dns"

configure_dns() {
    step "开始配置 DNS..."
    
    # 显示可用 DNS
    separator
    echo -e "${GREEN}可用的 DNS 服务器:${NC}"
    separator
    
    local index=1
    for dns in "${DNS_SERVERS[@]}"; do
        IFS='|' read -r name primary secondary desc <<< "$dns"
        echo "  [$index] $desc"
        echo "      主: $primary"
        [ -n "$secondary" ] && echo "      备: $secondary"
        ((index++))
    done
    echo "  [$index] 自定义 DNS"
    echo ""
    
    # 选择 DNS
    local selected_index
    read -p "请选择DNS服务器 [1-$index，默认1]: " selected_index
    selected_index=${selected_index:-1}
    
    if [ "$selected_index" -eq "$index" ]; then
        configure_custom_dns
    elif [ "$selected_index" -ge 1 ] && [ "$selected_index" -lt "$index" ]; then
        local selected_dns="${DNS_SERVERS[$((selected_index-1))]}"
        IFS='|' read -r dns_name primary secondary desc <<< "$selected_dns"
        
        info "已选择: $desc"
        configure_dns_servers "$primary" "$secondary"
    else
        error "无效的选择"
        return 1
    fi
}

# 配置 DNS 服务器
configure_dns_servers() {
    local primary="$1"
    local secondary="$2"
    
    step "配置 DNS 服务器..."
    
    # 检测系统使用的 DNS 管理方式
    if systemctl is-active --quiet systemd-resolved; then
        configure_systemd_resolved_dns "$primary" "$secondary"
    else
        configure_resolv_conf_dns "$primary" "$secondary"
    fi
    
    success "DNS 配置完成"
    
    # 测试 DNS
    if confirm "是否测试 DNS 解析?" "y"; then
        test_dns
    fi
}

# 配置 systemd-resolved 的 DNS
configure_systemd_resolved_dns() {
    local primary="$1"
    local secondary="$2"
    
    info "检测到 systemd-resolved，使用 systemd-resolved 配置"
    
    # 备份配置
    local resolved_conf="/etc/systemd/resolved.conf"
    backup_config "$resolved_conf" "$MODULE_NAME"
    
    # 配置 DNS
    cat > "$resolved_conf" << EOF
# DNS Configuration - Modified by Server Config Tool
[Resolve]
DNS=$primary${secondary:+ $secondary}
FallbackDNS=8.8.8.8 8.8.4.4
#Domains=
#LLMNR=yes
#MulticastDNS=yes
#DNSSEC=allow-downgrade
#DNSOverTLS=no
#Cache=yes
#DNSStubListener=yes
EOF
    
    # 重启服务
    systemctl restart systemd-resolved
    
    success "systemd-resolved DNS 配置完成"
    info "主 DNS: $primary"
    [ -n "$secondary" ] && info "备 DNS: $secondary"
}

# 配置 resolv.conf 的 DNS
configure_resolv_conf_dns() {
    local primary="$1"
    local secondary="$2"
    
    local resolv_conf="/etc/resolv.conf"
    
    # 备份配置
    backup_config "$resolv_conf" "$MODULE_NAME"
    
    # 检查是否为符号链接（systemd-resolved）
    if [ -L "$resolv_conf" ]; then
        warn "/etc/resolv.conf 是一个符号链接"
        
        if confirm "是否删除链接并创建静态配置?" "y"; then
            rm -f "$resolv_conf"
        else
            info "保持现有配置"
            return 1
        fi
    fi
    
    # 写入 DNS 配置
    cat > "$resolv_conf" << EOF
# DNS Configuration - Modified by Server Config Tool
nameserver $primary
EOF
    
    if [ -n "$secondary" ]; then
        echo "nameserver $secondary" >> "$resolv_conf"
    fi
    
    # 添加备用 DNS
    cat >> "$resolv_conf" << EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
    
    # 防止被覆盖
    chattr +i "$resolv_conf" 2>/dev/null || warn "无法锁定 resolv.conf（可能会被 DHCP 覆盖）"
    
    success "DNS 配置完成"
    info "主 DNS: $primary"
    [ -n "$secondary" ] && info "备 DNS: $secondary"
    
    if [ $? -ne 0 ]; then
        warn "提示: 如果使用 DHCP，此配置可能会被覆盖"
        info "可以考虑在网络配置中设置静态 DNS"
    fi
}

# 配置自定义 DNS
configure_custom_dns() {
    echo ""
    read -p "请输入主 DNS 服务器: " primary_dns
    read -p "请输入备用 DNS 服务器（可选，直接回车跳过）: " secondary_dns
    
    if [ -z "$primary_dns" ]; then
        error "主 DNS 服务器不能为空"
        return 1
    fi
    
    configure_dns_servers "$primary_dns" "$secondary_dns"
}

# 测试 DNS 解析
test_dns() {
    separator
    step "测试 DNS 解析..."
    separator
    
    local test_domains=("baidu.com" "github.com" "google.com")
    
    for domain in "${test_domains[@]}"; do
        info "解析 $domain..."
        
        if nslookup "$domain" >/dev/null 2>&1; then
            local ip=$(nslookup "$domain" 2>/dev/null | grep -A 1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)
            success "$domain -> $ip"
        else
            error "$domain 解析失败"
        fi
    done
    
    separator
}

# 显示当前 DNS 配置
show_dns_config() {
    separator
    echo -e "${GREEN}当前 DNS 配置:${NC}"
    separator
    
    if systemctl is-active --quiet systemd-resolved; then
        echo -e "${BLUE}systemd-resolved 状态:${NC}"
        systemctl status systemd-resolved --no-pager | head -n 3
        
        echo ""
        echo -e "${BLUE}DNS 服务器:${NC}"
        resolvectl status | grep "DNS Servers" || echo "  无配置"
    else
        echo -e "${BLUE}/etc/resolv.conf:${NC}"
        if [ -f /etc/resolv.conf ]; then
            grep "^nameserver" /etc/resolv.conf
        else
            error "配置文件不存在"
        fi
    fi
    
    separator
}

# 重置 DNS 配置
reset_dns_config() {
    step "重置 DNS 配置..."
    
    if systemctl is-active --quiet systemd-resolved; then
        # 恢复 systemd-resolved 默认配置
        local resolved_conf="/etc/systemd/resolved.conf"
        
        if [ -f "$resolved_conf" ]; then
            cat > "$resolved_conf" << 'EOF'
[Resolve]
#DNS=
#FallbackDNS=
#Domains=
#LLMNR=yes
#MulticastDNS=yes
#DNSSEC=allow-downgrade
#DNSOverTLS=no
#Cache=yes
#DNSStubListener=yes
EOF
            systemctl restart systemd-resolved
            success "systemd-resolved 配置已重置"
        fi
    else
        # 解锁 resolv.conf
        chattr -i /etc/resolv.conf 2>/dev/null
        
        # 恢复默认配置
        cat > /etc/resolv.conf << 'EOF'
# Default DNS Configuration
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
        
        success "resolv.conf 已重置为默认配置"
    fi
}

# 解锁 resolv.conf
unlock_resolv_conf() {
    step "解锁 /etc/resolv.conf..."
    
    chattr -i /etc/resolv.conf 2>/dev/null
    
    if [ $? -eq 0 ]; then
        success "/etc/resolv.conf 已解锁"
    else
        warn "无法解锁（可能未锁定或权限不足）"
    fi
}
