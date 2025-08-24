#!/bin/bash

# 企业邮件系统 - Docker构建和部署脚本
# 解决构建问题的快速部署方案

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   企业邮件系统 - Docker 部署${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 检查Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker未安装${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}错误: Docker Compose未安装${NC}"
    exit 1
fi

# 2. 创建必要的目录
echo -e "${YELLOW}创建必要目录...${NC}"
mkdir -p logs
mkdir -p data/mysql
mkdir -p data/redis
mkdir -p data/mail

# 3. 生成.env文件（如果不存在）
if [ ! -f .env ]; then
    echo -e "${YELLOW}生成环境配置文件...${NC}"
    cat > .env << 'EOF'
# 数据库配置
MYSQL_ROOT_PASSWORD=Mail@System2024
MYSQL_DATABASE=mail_system
MYSQL_USER=mailuser
MYSQL_PASSWORD=Mail@User2024

# Redis配置
REDIS_PASSWORD=Redis@2024

# JWT配置
JWT_SECRET=ThisIsAVeryLongSecretKeyForJWTAuthenticationInProductionPleaseChangeThis2024

# 邮件配置
MAIL_HOST=localhost
MAIL_PORT=25
MAIL_USERNAME=admin@enterprise.mail
MAIL_PASSWORD=Admin@2024

# 环境
SPRING_PROFILES_ACTIVE=docker
EOF
    echo -e "${GREEN}✓ 环境配置文件已生成${NC}"
else
    echo -e "${GREEN}✓ 使用现有环境配置${NC}"
fi

# 4. 修复前端nginx配置
echo -e "${YELLOW}准备nginx配置...${NC}"
if [ ! -f frontend/nginx.conf ]; then
    cp frontend/nginx.default.conf frontend/nginx.conf
    echo -e "${GREEN}✓ nginx配置已准备${NC}"
fi

# 5. 选择构建方式
echo ""
echo -e "${BLUE}请选择部署方式:${NC}"
echo "  1) 完整构建并部署（较慢，约5-10分钟）"
echo "  2) 仅部署数据库和Redis（快速）"
echo "  3) 清理并重新构建"
echo -n "选择 [1-3]: "
read choice

case $choice in
    1)
        echo -e "${YELLOW}开始构建镜像...${NC}"
        
        # 使用生产配置构建
        if docker compose version &> /dev/null; then
            docker compose -f docker-compose.prod.yml build --no-cache
            echo -e "${GREEN}✓ 镜像构建完成${NC}"
            
            echo -e "${YELLOW}启动所有服务...${NC}"
            docker compose -f docker-compose.prod.yml up -d
        else
            docker-compose -f docker-compose.prod.yml build --no-cache
            echo -e "${GREEN}✓ 镜像构建完成${NC}"
            
            echo -e "${YELLOW}启动所有服务...${NC}"
            docker-compose -f docker-compose.prod.yml up -d
        fi
        
        echo -e "${GREEN}✓ 服务启动完成${NC}"
        ;;
        
    2)
        echo -e "${YELLOW}仅启动数据库和Redis...${NC}"
        
        if docker compose version &> /dev/null; then
            docker compose -f docker-compose.prod.yml up -d mysql redis
        else
            docker-compose -f docker-compose.prod.yml up -d mysql redis
        fi
        
        echo -e "${GREEN}✓ 数据库服务已启动${NC}"
        echo ""
        echo "现在你可以本地运行应用:"
        echo "  后端: cd backend && ./mvnw spring-boot:run"
        echo "  前端: cd frontend && npm install && npm run dev"
        ;;
        
    3)
        echo -e "${YELLOW}清理旧容器和镜像...${NC}"
        
        if docker compose version &> /dev/null; then
            docker compose -f docker-compose.prod.yml down -v
            docker compose -f docker-compose.prod.yml rm -f
        else
            docker-compose -f docker-compose.prod.yml down -v
            docker-compose -f docker-compose.prod.yml rm -f
        fi
        
        echo -e "${GREEN}✓ 清理完成${NC}"
        echo "请重新运行脚本选择选项1进行构建"
        ;;
        
    *)
        echo -e "${RED}无效选择${NC}"
        exit 1
        ;;
esac

# 6. 等待服务就绪
if [ "$choice" = "1" ]; then
    echo ""
    echo -e "${YELLOW}等待服务就绪...${NC}"
    sleep 10
    
    # 检查服务状态
    echo -e "${YELLOW}检查服务状态...${NC}"
    
    # 检查MySQL
    if docker exec mail-mysql mysqladmin ping -h localhost &> /dev/null; then
        echo -e "${GREEN}✓ MySQL 正常${NC}"
    else
        echo -e "${RED}✗ MySQL 未就绪${NC}"
    fi
    
    # 检查Redis
    if docker exec mail-redis redis-cli -a ${REDIS_PASSWORD:-Redis@2024} ping &> /dev/null; then
        echo -e "${GREEN}✓ Redis 正常${NC}"
    else
        echo -e "${RED}✗ Redis 未就绪${NC}"
    fi
    
    # 检查后端
    if curl -s http://localhost:8080/api/actuator/health &> /dev/null; then
        echo -e "${GREEN}✓ 后端服务正常${NC}"
    else
        echo -e "${YELLOW}⚠ 后端服务启动中...${NC}"
    fi
    
    # 检查前端
    if curl -s http://localhost &> /dev/null; then
        echo -e "${GREEN}✓ 前端服务正常${NC}"
    else
        echo -e "${YELLOW}⚠ 前端服务启动中...${NC}"
    fi
fi

# 7. 显示访问信息
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "访问地址:"
echo -e "  前端: ${BLUE}http://localhost${NC}"
echo -e "  后端API: ${BLUE}http://localhost:8080/api${NC}"
echo ""
echo "默认账号:"
echo "  邮箱: admin@enterprise.mail"
echo "  密码: Admin@123"
echo ""
echo "查看日志:"
if docker compose version &> /dev/null; then
    echo "  docker compose -f docker-compose.prod.yml logs -f"
else
    echo "  docker-compose -f docker-compose.prod.yml logs -f"
fi
echo ""
echo "停止服务:"
if docker compose version &> /dev/null; then
    echo "  docker compose -f docker-compose.prod.yml down"
else
    echo "  docker-compose -f docker-compose.prod.yml down"
fi
echo ""
echo -e "${GREEN}========================================${NC}"