#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "Docker 和 Docker Compose 安装脚本"
echo "========================================"
echo ""

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            echo "debian"
        elif [ -f /etc/redhat-release ]; then
            echo "redhat"
        else
            echo "unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

# 安装 Docker
install_docker() {
    echo -e "${YELLOW}正在安装 Docker...${NC}"
    
    if [ "$OS" == "debian" ]; then
        # Ubuntu/Debian
        sudo apt-get update
        sudo apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        
        # 添加 Docker 官方 GPG 密钥
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        # 设置存储库
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # 安装 Docker Engine
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
    elif [ "$OS" == "redhat" ]; then
        # CentOS/RHEL
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
    elif [ "$OS" == "macos" ]; then
        echo -e "${YELLOW}请从 Docker 官网下载 Docker Desktop for Mac:${NC}"
        echo "https://www.docker.com/products/docker-desktop"
        exit 1
        
    elif [ "$OS" == "windows" ]; then
        echo -e "${YELLOW}请从 Docker 官网下载 Docker Desktop for Windows:${NC}"
        echo "https://www.docker.com/products/docker-desktop"
        exit 1
        
    else
        echo -e "${RED}不支持的操作系统${NC}"
        exit 1
    fi
    
    # 启动 Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 将当前用户添加到 docker 组
    sudo usermod -aG docker $USER
    
    echo -e "${GREEN}Docker 安装完成！${NC}"
}

# 安装 Docker Compose
install_docker_compose() {
    echo -e "${YELLOW}正在安装 Docker Compose...${NC}"
    
    if [ "$OS" == "debian" ] || [ "$OS" == "redhat" ]; then
        # Docker Compose v2 已经作为插件包含在 docker-ce 中
        echo -e "${GREEN}Docker Compose 已作为 Docker 插件安装${NC}"
        
        # 创建 docker-compose 别名以便向后兼容
        echo 'alias docker-compose="docker compose"' >> ~/.bashrc
        source ~/.bashrc
        
    elif [ "$OS" == "macos" ] || [ "$OS" == "windows" ]; then
        echo -e "${YELLOW}Docker Desktop 已包含 Docker Compose${NC}"
    fi
}

# 检查 Docker 是否已安装
check_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}Docker 已安装，版本: $(docker --version)${NC}"
        return 0
    else
        return 1
    fi
}

# 检查 Docker Compose 是否已安装
check_docker_compose() {
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        echo -e "${GREEN}Docker Compose 已安装，版本: $(docker compose version)${NC}"
        return 0
    else
        return 1
    fi
}

# 主程序
main() {
    # 检查 Docker
    if ! check_docker; then
        read -p "Docker 未安装，是否安装？(y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_docker
        else
            echo -e "${RED}需要 Docker 才能继续${NC}"
            exit 1
        fi
    fi
    
    # 检查 Docker Compose
    if ! check_docker_compose; then
        read -p "Docker Compose 未安装，是否安装？(y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_docker_compose
        else
            echo -e "${RED}需要 Docker Compose 才能继续${NC}"
            exit 1
        fi
    fi
    
    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}所有依赖已安装完成！${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo "您现在可以运行部署脚本："
    echo "  ./deploy.sh"
    echo ""
    echo -e "${YELLOW}注意：如果刚添加到 docker 组，需要重新登录或运行:${NC}"
    echo "  newgrp docker"
}

main