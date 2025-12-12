#!/bin/bash

# Docker 配置模块

MODULE_NAME="docker"

configure_docker() {
    step "开始配置 Docker..."
    
    # 检查 Docker 是否安装
    if ! command_exists docker; then
        warn "Docker 未安装"
        
        if confirm "是否现在安装 Docker?" "y"; then
            install_docker
        else
            info "跳过 Docker 配置"
            return 0
        fi
    else
        info "检测到 Docker 已安装"
        docker --version
    fi
    
    # 配置镜像加速器
    configure_docker_mirrors
}

# 安装 Docker
install_docker() {
    step "安装 Docker..."
    
    # 安装依赖
    apt-get update
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # 添加 Docker 官方 GPG 密钥（使用阿里云镜像）
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # 设置 Docker 仓库（使用阿里云镜像）
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装 Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 启动 Docker
    systemctl start docker
    systemctl enable docker
    
    # 验证安装
    if docker --version; then
        success "Docker 安装成功"
        docker --version
    else
        error "Docker 安装失败"
        return 1
    fi
}

# 配置 Docker 镜像加速器
configure_docker_mirrors() {
    step "配置 Docker 镜像加速器..."
    
    local daemon_json="/etc/docker/daemon.json"
    local template_file="$SCRIPT_DIR/templates/daemon.json.template"
    
    # 备份现有配置
    if [ -f "$daemon_json" ]; then
        backup_config "$daemon_json" "$MODULE_NAME"
    fi
    
    separator
    info "可用的 Docker 镜像加速器:"
    separator
    
    # 构建镜像 URL 列表
    local mirror_urls=""
    local has_aliyun=false
    
    for mirror in "${DOCKER_MIRRORS[@]}"; do
        IFS='|' read -r name url desc <<< "$mirror"
        if [ -z "$mirror_urls" ]; then
            mirror_urls="\"$url\""
        else
            mirror_urls="$mirror_urls,\n    \"$url\""
        fi
        info "  • $desc"
        echo "    $url"
        
        # 检查是否包含阿里云
        if [[ "$name" == "aliyun" ]]; then
            has_aliyun=true
        fi
    done
    
    separator
    
    # 阿里云镜像特殊提示
    if [ "$has_aliyun" = true ]; then
        warn "注意: 阿里云镜像加速器需要注册账号后获取专属地址"
        info "获取地址: https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors"
        echo ""
    fi
    
    # 生成配置文件
    if [ -f "$template_file" ]; then
        sed "s|{{MIRROR_URLS}}|$mirror_urls|g" "$template_file" > "$daemon_json"
    else
        # 如果模板不存在，直接生成
        cat > "$daemon_json" <<EOF
{
  "registry-mirrors": [
$(echo -e "$mirror_urls")
  ],
  "max-concurrent-downloads": 10,
  "log-driver": "json-file",
  "log-level": "warn",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    fi
    
    success "Docker 配置已更新"
    
    # 重启 Docker 服务
    step "重启 Docker 服务..."
    if systemctl restart docker; then
        success "Docker 服务重启成功"
    else
        error "Docker 服务重启失败"
        return 1
    fi
    
    # 验证配置
    separator
    success "Docker 镜像加速器配置完成！"
    separator
    
    show_docker_config
}

# 测试 Docker 镜像加速
test_docker() {
    step "测试 Docker 镜像拉取..."
    
    info "拉取测试镜像: hello-world"
    
    if docker pull hello-world; then
        success "Docker 镜像拉取成功"
        docker run --rm hello-world
        
        # 清理测试镜像
        docker rmi hello-world >/dev/null 2>&1
        return 0
    else
        error "Docker 镜像拉取失败"
        return 1
    fi
}

# 显示 Docker 配置
show_docker_config() {
    echo -e "${GREEN}Docker 配置信息:${NC}"
    
    if [ -f /etc/docker/daemon.json ]; then
        cat /etc/docker/daemon.json
    else
        warn "配置文件不存在"
    fi
    
    echo ""
    echo -e "${GREEN}Docker 信息:${NC}"
    docker info 2>/dev/null | grep -A 10 "Registry Mirrors" || echo "无镜像加速器配置"
}

# 移除 Docker
remove_docker() {
    warn "这将完全卸载 Docker！"
    
    if ! confirm "确认卸载?" "n"; then
        return 1
    fi
    
    step "卸载 Docker..."
    
    # 停止所有容器
    docker stop $(docker ps -aq) 2>/dev/null
    
    # 卸载 Docker
    apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 删除数据
    if confirm "是否删除 Docker 数据（镜像、容器、卷等）?" "n"; then
        rm -rf /var/lib/docker
        rm -rf /var/lib/containerd
    fi
    
    success "Docker 已卸载"
}
