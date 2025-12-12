#!/bin/bash

# Docker 配置诊断和修复脚本

echo "========================================"
echo "Docker 镜像加速配置诊断工具"
echo "========================================"
echo ""

# 1. 检查 Docker 是否安装
echo "[1/6] 检查 Docker 安装..."
if command -v docker &> /dev/null; then
    docker_version=$(docker --version)
    echo "✅ Docker 已安装: $docker_version"
else
    echo "❌ Docker 未安装"
    exit 1
fi
echo ""

# 2. 检查 Docker 服务状态
echo "[2/6] 检查 Docker 服务状态..."
if systemctl is-active --quiet docker; then
    echo "✅ Docker 服务正在运行"
else
    echo "❌ Docker 服务未运行"
    echo "尝试启动 Docker 服务..."
    sudo systemctl start docker
fi
echo ""

# 3. 检查配置文件
echo "[3/6] 检查配置文件..."
if [ -f /etc/docker/daemon.json ]; then
    echo "✅ 配置文件存在: /etc/docker/daemon.json"
    echo ""
    echo "当前配置内容:"
    echo "----------------------------------------"
    cat /etc/docker/daemon.json
    echo "----------------------------------------"
else
    echo "❌ 配置文件不存在: /etc/docker/daemon.json"
fi
echo ""

# 4. 检查配置是否生效
echo "[4/6] 检查 Docker 配置是否加载..."
registry_mirrors=$(docker info 2>/dev/null | grep -A 10 "Registry Mirrors" || echo "未找到")

if [[ "$registry_mirrors" == *"docker.xuanyuan.me"* ]] || [[ "$registry_mirrors" == *"dockerproxy.com"* ]]; then
    echo "✅ 镜像源配置已加载"
    echo "$registry_mirrors"
else
    echo "❌ 镜像源配置未加载或未生效"
    echo "Docker Info 输出:"
    echo "$registry_mirrors"
fi
echo ""

# 5. 检查 DNS 配置
echo "[5/6] 检查 DNS 配置..."
dns_config=$(docker info 2>/dev/null | grep "DNS" || echo "未配置")
echo "$dns_config"
echo ""

# 6. 诊断结果和建议
echo "[6/6] 诊断结果和修复建议"
echo "========================================"

if [[ "$registry_mirrors" != *"docker.xuanyuan.me"* ]]; then
    echo ""
    echo "⚠️  问题诊断: 镜像源配置未生效"
    echo ""
    echo "可能的原因："
    echo "  1. Docker 服务未重启"
    echo "  2. daemon.json 配置格式错误"
    echo "  3. 配置文件权限问题"
    echo ""
    echo "修复步骤："
    echo "  1. 检查配置文件格式是否正确"
    echo "  2. 运行: sudo systemctl daemon-reload"
    echo "  3. 运行: sudo systemctl restart docker"
    echo "  4. 验证: docker info | grep 'Registry Mirrors' -A 5"
    echo ""
    
    read -p "是否现在自动修复？[y/N]: " auto_fix
    
    if [[ "$auto_fix" =~ ^[Yy]$ ]]; then
        echo ""
        echo "开始自动修复..."
        
        # 重新加载守护进程
        echo "→ 重新加载 systemd 守护进程..."
        sudo systemctl daemon-reload
        
        # 重启 Docker 服务
        echo "→ 重启 Docker 服务..."
        sudo systemctl restart docker
        
        # 等待服务启动
        sleep 3
        
        # 验证
        echo "→ 验证配置..."
        if docker info 2>/dev/null | grep -q "Registry Mirrors"; then
            echo "✅ 修复成功！镜像源配置已生效"
            echo ""
            docker info | grep "Registry Mirrors" -A 10
        else
            echo "❌ 自动修复失败，请手动检查配置"
        fi
    fi
else
    echo "✅ 配置正常，镜像源已生效"
fi
echo ""

echo "========================================"
echo "诊断完成！"
echo "========================================"
