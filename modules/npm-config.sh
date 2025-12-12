#!/bin/bash

# NPM/Yarn 配置模块

MODULE_NAME="npm"

configure_npm() {
    step "开始配置 NPM/Yarn..."
    
    # 检查 Node.js 和 NPM 是否安装
    if ! command_exists node && ! command_exists npm; then
        warn "Node.js/NPM 未安装"
        
        if confirm "是否现在安装 Node.js?" "y"; then
            install_nodejs
        else
            info "跳过 NPM 配置"
            return 0
        fi
    else
        info "检测到 Node.js 已安装"
        node --version
        npm --version
    fi
    
    # 配置 NPM 镜像
    configure_npm_mirror
    
    # 询问是否配置 Yarn
    if command_exists yarn || confirm "是否配置 Yarn?（需安装）" "n"; then
        configure_yarn_mirror
    fi
    
    # 询问是否安装 cnpm
    if confirm "是否安装 cnpm?（淘宝 NPM 客户端）" "n"; then
        install_cnpm
    fi
}

# 安装 Node.js
install_nodejs() {
    step "安装 Node.js..."
    
    # 使用 NodeSource 发行版（使用清华镜像）
    info "添加 NodeSource 仓库..."
    
    curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/nodesource/deb/setup_lts.x | bash -
    
    apt-get install -y nodejs
    
    if command_exists node; then
        success "Node.js 安装成功"
        node --version
        npm --version
    else
        error "Node.js 安装失败"
        return 1
    fi
}

# 配置 NPM 镜像
configure_npm_mirror() {
    step "配置 NPM 镜像源..."
    
    # 备份 NPM 配置
    local npm_config="$HOME/.npmrc"
    if [ -f "$npm_config" ]; then
        backup_config "$npm_config" "$MODULE_NAME"
    fi
    
    # 设置镜像源
    npm config set registry "$NPM_REGISTRY"
    
    # 设置其他镜像
    npm config set disturl "https://npmmirror.com/dist"
    npm config set electron_mirror "https://npmmirror.com/mirrors/electron/"
    npm config set sass_binary_site "https://npmmirror.com/mirrors/node-sass/"
    npm config set phantomjs_cdnurl "https://npmmirror.com/mirrors/phantomjs/"
    npm config set chromedriver_cdnurl "https://npmmirror.com/mirrors/chromedriver/"
    
    success "NPM 镜像源配置完成"
    
    info "当前 NPM 镜像: $NPM_REGISTRY_NAME"
    info "镜像地址: $NPM_REGISTRY"
}

# 配置 Yarn 镜像
configure_yarn_mirror() {
    # 检查 Yarn 是否安装
    if ! command_exists yarn; then
        step "安装 Yarn..."
        npm install -g yarn
        
        if ! command_exists yarn; then
            error "Yarn 安装失败"
            return 1
        fi
    fi
    
    step "配置 Yarn 镜像源..."
    
    # 设置 Yarn 镜像
    yarn config set registry "$YARN_REGISTRY"
    
    success "Yarn 镜像源配置完成"
    
    info "当前 Yarn 镜像: $YARN_REGISTRY_NAME"
    info "镜像地址: $YARN_REGISTRY"
}

# 安装 cnpm
install_cnpm() {
    step "安装 cnpm..."
    
    npm install -g cnpm --registry="$NPM_REGISTRY"
    
    if command_exists cnpm; then
        success "cnpm 安装成功"
        cnpm --version
        
        separator
        info "使用方式:"
        echo "  使用 'cnpm install' 代替 'npm install'"
        echo "  cnpm 会自动使用淘宝镜像"
        separator
    else
        error "cnpm 安装失败"
        return 1
    fi
}

# 重置 NPM 配置
reset_npm_config() {
    step "重置 NPM 配置..."
    
    npm config delete registry
    npm config delete disturl
    npm config delete electron_mirror
    npm config delete sass_binary_site
    npm config delete phantomjs_cdnurl
    npm config delete chromedriver_cdnurl
    
    success "NPM 配置已重置为默认值"
}

# 显示 NPM 配置
show_npm_config() {
    separator
    echo -e "${GREEN}NPM 配置信息:${NC}"
    separator
    
    if command_exists npm; then
        echo -e "${BLUE}NPM 版本:${NC}"
        npm --version
        
        echo ""
        echo -e "${BLUE}当前镜像源:${NC}"
        npm config get registry
        
        echo ""
        echo -e "${BLUE}其他配置:${NC}"
        npm config list | grep -E "(disturl|electron_mirror|sass_binary_site)" || echo "  无额外配置"
    else
        warn "NPM 未安装"
    fi
    
    echo ""
    
    if command_exists yarn; then
        echo -e "${BLUE}Yarn 版本:${NC}"
        yarn --version
        
        echo ""
        echo -e "${BLUE}Yarn 镜像源:${NC}"
        yarn config get registry
    fi
    
    separator
}

# 测试 NPM 镜像
test_npm() {
    step "测试 NPM 镜像..."
    
    info "测试安装一个小包: lodash"
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # 初始化项目
    npm init -y >/dev/null 2>&1
    
    # 测试安装
    if npm install lodash --save >/dev/null 2>&1; then
        success "NPM 镜像测试成功"
        cd - >/dev/null
        rm -rf "$temp_dir"
        return 0
    else
        error "NPM 镜像测试失败"
        cd - >/dev/null
        rm -rf "$temp_dir"
        return 1
    fi
}

# 清理 NPM 缓存
clean_npm_cache() {
    step "清理 NPM 缓存..."
    
    if command_exists npm; then
        npm cache clean --force
        success "NPM 缓存已清理"
    fi
    
    if command_exists yarn; then
        yarn cache clean
        success "Yarn 缓存已清理"
    fi
}
