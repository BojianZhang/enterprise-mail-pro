#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
PROJECT_NAME="enterprise-mail-pro"
BACKEND_PORT=8080
FRONTEND_PORT=80
SMTP_PORT=25
MYSQL_PORT=3306

echo "========================================"
echo "企业邮件系统 - 部署脚本 v2.0"
echo "========================================"

# 函数：检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 函数：检查 Docker
check_docker() {
    echo "检查 Docker..."
    if command_exists docker; then
        echo -e "${GREEN}✓ Docker 已安装: $(docker --version)${NC}"
        
        # 检查 Docker 服务是否运行
        if ! docker info >/dev/null 2>&1; then
            echo -e "${YELLOW}Docker 服务未运行，尝试启动...${NC}"
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                sudo systemctl start docker
            fi
        fi
        return 0
    else
        echo -e "${RED}✗ Docker 未安装${NC}"
        echo "请先运行 ./install-docker.sh 安装 Docker"
        return 1
    fi
}

# 函数：检查 Docker Compose
check_docker_compose() {
    echo "检查 Docker Compose..."
    
    # 尝试新版本的 docker compose 命令
    if docker compose version >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Docker Compose (插件) 已安装${NC}"
        DOCKER_COMPOSE="docker compose"
        return 0
    # 尝试旧版本的 docker-compose 命令
    elif command_exists docker-compose; then
        echo -e "${GREEN}✓ Docker Compose (独立) 已安装: $(docker-compose --version)${NC}"
        DOCKER_COMPOSE="docker-compose"
        return 0
    else
        echo -e "${RED}✗ Docker Compose 未安装${NC}"
        echo "请先运行 ./install-docker.sh 安装 Docker Compose"
        return 1
    fi
}

# 函数：检查端口占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${YELLOW}警告: 端口 $port 已被占用${NC}"
        return 1
    fi
    return 0
}

# 函数：创建必要的目录
create_directories() {
    echo "创建必要的目录..."
    mkdir -p data/mysql
    mkdir -p data/redis
    mkdir -p data/mail
    mkdir -p logs
    mkdir -p nginx/ssl
    echo -e "${GREEN}✓ 目录创建完成${NC}"
}

# 函数：生成环境变量文件
generate_env() {
    if [ ! -f .env ]; then
        echo "生成环境变量文件..."
        cp .env.example .env
        
        # 生成随机的 JWT 密钥
        JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')
        sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env 2>/dev/null || \
        sed -i '' "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env 2>/dev/null
        
        echo -e "${GREEN}✓ 环境变量文件已生成${NC}"
    else
        echo -e "${YELLOW}环境变量文件已存在，跳过生成${NC}"
    fi
}

# 函数：构建 Docker 镜像
build_images() {
    echo ""
    echo "构建 Docker 镜像..."
    echo "这可能需要几分钟时间，请耐心等待..."
    
    # 使用 buildx 构建（如果可用）
    if docker buildx version >/dev/null 2>&1; then
        echo "使用 Docker Buildx 构建..."
        docker buildx bake -f docker-compose.yml
    else
        echo "使用 Docker Compose 构建..."
        $DOCKER_COMPOSE build --no-cache
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Docker 镜像构建成功${NC}"
    else
        echo -e "${RED}✗ Docker 镜像构建失败${NC}"
        echo "请检查 Dockerfile 配置"
        exit 1
    fi
}

# 函数：启动服务
start_services() {
    echo ""
    echo "启动服务..."
    
    $DOCKER_COMPOSE up -d
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 服务启动成功${NC}"
    else
        echo -e "${RED}✗ 服务启动失败${NC}"
        exit 1
    fi
}

# 函数：等待服务就绪
wait_for_services() {
    echo ""
    echo "等待服务就绪..."
    
    # 等待 MySQL
    echo -n "等待 MySQL..."
    for i in {1..30}; do
        if docker exec mail-mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
            echo -e " ${GREEN}✓${NC}"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    # 等待后端
    echo -n "等待后端服务..."
    for i in {1..30}; do
        if curl -f http://localhost:$BACKEND_PORT/api/actuator/health >/dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC}"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    # 等待前端
    echo -n "等待前端服务..."
    for i in {1..30}; do
        if curl -f http://localhost:$FRONTEND_PORT >/dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC}"
            break
        fi
        echo -n "."
        sleep 2
    done
}

# 函数：显示服务状态
show_status() {
    echo ""
    echo "========================================"
    echo "服务状态："
    echo "========================================"
    $DOCKER_COMPOSE ps
}

# 函数：显示访问信息
show_access_info() {
    echo ""
    echo "========================================"
    echo -e "${GREEN}部署成功！${NC}"
    echo "========================================"
    echo ""
    echo "访问地址："
    echo -e "  前端界面: ${BLUE}http://localhost${NC}"
    echo -e "  后端 API: ${BLUE}http://localhost:8080${NC}"
    echo -e "  API 文档: ${BLUE}http://localhost:8080/swagger-ui.html${NC}"
    echo ""
    echo "邮件服务端口："
    echo "  SMTP: 25, 465 (SSL)"
    echo "  IMAP: 143, 993 (SSL)"
    echo "  POP3: 110, 995 (SSL)"
    echo ""
    echo "数据库连接："
    echo "  Host: localhost"
    echo "  Port: 3306"
    echo "  Database: mail_system"
    echo "  Username: mailuser"
    echo "  Password: mail123456"
    echo ""
    echo "查看日志："
    echo "  $DOCKER_COMPOSE logs -f [service_name]"
    echo ""
    echo "停止服务："
    echo "  $DOCKER_COMPOSE down"
    echo ""
    echo "重启服务："
    echo "  $DOCKER_COMPOSE restart"
}

# 主函数
main() {
    # 检查必要的工具
    echo "检查系统要求..."
    
    if ! check_docker; then
        exit 1
    fi
    
    if ! check_docker_compose; then
        exit 1
    fi
    
    # 检查端口
    echo ""
    echo "检查端口占用..."
    check_port $BACKEND_PORT
    check_port $FRONTEND_PORT
    check_port $SMTP_PORT
    check_port $MYSQL_PORT
    
    # 准备环境
    create_directories
    generate_env
    
    # 构建和启动
    build_images
    start_services
    wait_for_services
    
    # 显示结果
    show_status
    show_access_info
}

# 运行主函数
main