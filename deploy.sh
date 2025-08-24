#!/bin/bash

# 企业邮件系统部署脚本

set -e

echo "======================================"
echo "企业邮件系统 - 部署脚本"
echo "======================================"

# 检查 Docker 和 Docker Compose
check_requirements() {
    echo "检查系统要求..."
    
    if ! command -v docker &> /dev/null; then
        echo "错误: Docker 未安装"
        echo "请访问 https://docs.docker.com/get-docker/ 安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "错误: Docker Compose 未安装"
        echo "请访问 https://docs.docker.com/compose/install/ 安装 Docker Compose"
        exit 1
    fi
    
    echo "✓ Docker 已安装"
    echo "✓ Docker Compose 已安装"
}

# 创建必要的目录
create_directories() {
    echo "创建必要的目录..."
    mkdir -p logs
    mkdir -p nginx/ssl
    mkdir -p data/mysql
    mkdir -p data/redis
    mkdir -p data/mail
    echo "✓ 目录创建完成"
}

# 生成环境配置文件
generate_env() {
    echo "生成环境配置文件..."
    
    if [ ! -f .env ]; then
        cat > .env << EOF
# MySQL Configuration
MYSQL_ROOT_PASSWORD=root123456
MYSQL_DATABASE=mail_system
MYSQL_USER=mailuser
MYSQL_PASSWORD=mail123456

# Redis Configuration
REDIS_PASSWORD=

# JWT Configuration
JWT_SECRET=ThisIsAVerySecureSecretKeyForJWTTokenGenerationPleaseChangeInProduction2024

# Mail Server Configuration
MAIL_DOMAIN=enterprise.mail
MAIL_ADMIN_USER=admin
MAIL_ADMIN_PASSWORD=admin123456

# Application Ports
BACKEND_PORT=8080
FRONTEND_PORT=80
SMTP_PORT=25
IMAP_PORT=143
POP3_PORT=110
EOF
        echo "✓ .env 文件已生成"
    else
        echo "✓ .env 文件已存在"
    fi
}

# 构建和启动服务
build_and_start() {
    echo "构建 Docker 镜像..."
    docker-compose build
    
    echo "启动服务..."
    docker-compose up -d
    
    echo "等待服务启动..."
    sleep 10
}

# 检查服务状态
check_services() {
    echo "检查服务状态..."
    docker-compose ps
    
    # 检查后端健康状态
    echo "检查后端服务..."
    if curl -f http://localhost:8080/api/actuator/health &> /dev/null; then
        echo "✓ 后端服务正常"
    else
        echo "✗ 后端服务异常"
    fi
    
    # 检查前端
    echo "检查前端服务..."
    if curl -f http://localhost &> /dev/null; then
        echo "✓ 前端服务正常"
    else
        echo "✗ 前端服务异常"
    fi
}

# 显示访问信息
show_info() {
    echo ""
    echo "======================================"
    echo "部署完成！"
    echo "======================================"
    echo "访问地址:"
    echo "  Web界面: http://localhost"
    echo "  API文档: http://localhost:8080/api/swagger-ui.html"
    echo ""
    echo "默认管理员账号:"
    echo "  用户名: admin"
    echo "  密码: admin123456"
    echo ""
    echo "邮件服务端口:"
    echo "  SMTP: 25, 465(SSL)"
    echo "  IMAP: 143, 993(SSL)"
    echo "  POP3: 110, 995(SSL)"
    echo ""
    echo "查看日志:"
    echo "  docker-compose logs -f"
    echo ""
    echo "停止服务:"
    echo "  docker-compose down"
    echo "======================================"
}

# 主函数
main() {
    check_requirements
    create_directories
    generate_env
    build_and_start
    check_services
    show_info
}

# 执行主函数
main