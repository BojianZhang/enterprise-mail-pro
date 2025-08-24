#!/bin/bash

# 企业邮件系统 - 快速启动脚本
# 一键启动所有服务

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   企业邮件系统 - 快速启动${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查必要的软件
check_requirements() {
    echo -e "${YELLOW}检查系统要求...${NC}"
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: Docker 未安装${NC}"
        echo "请先安装 Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # 检查 Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}错误: Docker Compose 未安装${NC}"
        echo "请先安装 Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # 检查 Node.js (用于前端开发)
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}警告: Node.js 未安装（仅开发模式需要）${NC}"
    fi
    
    echo -e "${GREEN}✓ 系统要求检查通过${NC}"
}

# 创建必要的目录
create_directories() {
    echo -e "${YELLOW}创建必要目录...${NC}"
    mkdir -p data/mysql
    mkdir -p data/redis
    mkdir -p data/attachments
    mkdir -p logs
    echo -e "${GREEN}✓ 目录创建完成${NC}"
}

# 生成环境配置文件
generate_env() {
    if [ ! -f .env ]; then
        echo -e "${YELLOW}生成环境配置文件...${NC}"
        cat > .env << 'EOF'
# 数据库配置
DB_HOST=mysql
DB_PORT=3306
DB_NAME=mail_system
DB_USERNAME=root
DB_PASSWORD=Mail@Sys2024!

# Redis配置
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=Redis@2024!

# JWT配置
JWT_SECRET=ThisIsAVeryLongSecretKeyForJWTAuthenticationInProductionPleaseChangeThis2024!

# 邮件服务器配置
MAIL_HOST=localhost
MAIL_PORT=25
MAIL_USERNAME=admin@enterprise.mail
MAIL_PASSWORD=Admin@2024!

# 服务端口
SERVER_PORT=8080
FRONTEND_PORT=3000

# 环境
SPRING_PROFILES_ACTIVE=prod
NODE_ENV=production
EOF
        echo -e "${GREEN}✓ 环境配置文件已生成${NC}"
        echo -e "${YELLOW}  请编辑 .env 文件以配置生产环境参数${NC}"
    else
        echo -e "${GREEN}✓ 使用现有环境配置文件${NC}"
    fi
}

# 启动模式选择
select_mode() {
    echo ""
    echo -e "${BLUE}请选择启动模式:${NC}"
    echo "  1) 生产模式 (Docker)"
    echo "  2) 开发模式 (本地)"
    echo "  3) 混合模式 (数据库用Docker，应用本地)"
    echo -n "选择 [1-3]: "
    read mode
    
    case $mode in
        1)
            start_production
            ;;
        2)
            start_development
            ;;
        3)
            start_hybrid
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            exit 1
            ;;
    esac
}

# 生产模式启动
start_production() {
    echo ""
    echo -e "${BLUE}启动生产模式...${NC}"
    
    # 构建镜像
    echo -e "${YELLOW}构建 Docker 镜像...${NC}"
    docker-compose build
    
    # 启动服务
    echo -e "${YELLOW}启动所有服务...${NC}"
    docker-compose up -d
    
    # 等待服务就绪
    echo -e "${YELLOW}等待服务就绪...${NC}"
    sleep 10
    
    # 检查服务状态
    check_services
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ 系统启动成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "访问地址:"
    echo -e "  前端: ${BLUE}http://localhost:3000${NC}"
    echo -e "  后端API: ${BLUE}http://localhost:8080/api${NC}"
    echo ""
    echo "默认账号:"
    echo "  用户名: admin@enterprise.mail"
    echo "  密码: Admin@123"
}

# 开发模式启动
start_development() {
    echo ""
    echo -e "${BLUE}启动开发模式...${NC}"
    
    # 启动 MySQL 和 Redis
    echo -e "${YELLOW}启动数据库服务...${NC}"
    docker-compose up -d mysql redis
    
    # 等待数据库就绪
    sleep 5
    
    # 启动后端
    echo -e "${YELLOW}启动后端服务...${NC}"
    cd backend
    ./mvnw spring-boot:run &
    cd ..
    
    # 启动前端
    echo -e "${YELLOW}启动前端服务...${NC}"
    cd frontend
    npm install
    npm run dev &
    cd ..
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ 开发环境启动成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "访问地址:"
    echo -e "  前端: ${BLUE}http://localhost:5173${NC}"
    echo -e "  后端API: ${BLUE}http://localhost:8080/api${NC}"
}

# 混合模式启动
start_hybrid() {
    echo ""
    echo -e "${BLUE}启动混合模式...${NC}"
    
    # 启动数据库服务
    echo -e "${YELLOW}启动 Docker 数据库服务...${NC}"
    docker-compose up -d mysql redis
    
    # 等待服务就绪
    sleep 5
    
    echo -e "${GREEN}数据库服务已启动${NC}"
    echo "请手动启动应用:"
    echo "  后端: cd backend && ./mvnw spring-boot:run"
    echo "  前端: cd frontend && npm run dev"
}

# 检查服务状态
check_services() {
    echo ""
    echo -e "${YELLOW}检查服务状态...${NC}"
    
    # 检查后端
    if curl -s http://localhost:8080/api/actuator/health > /dev/null; then
        echo -e "${GREEN}✓ 后端服务正常${NC}"
    else
        echo -e "${RED}✗ 后端服务未响应${NC}"
    fi
    
    # 检查前端
    if curl -s http://localhost:3000 > /dev/null; then
        echo -e "${GREEN}✓ 前端服务正常${NC}"
    else
        echo -e "${YELLOW}⚠ 前端服务启动中...${NC}"
    fi
    
    # 检查数据库
    if docker-compose ps | grep mysql | grep Up > /dev/null; then
        echo -e "${GREEN}✓ MySQL 数据库正常${NC}"
    else
        echo -e "${RED}✗ MySQL 数据库异常${NC}"
    fi
    
    # 检查 Redis
    if docker-compose ps | grep redis | grep Up > /dev/null; then
        echo -e "${GREEN}✓ Redis 缓存正常${NC}"
    else
        echo -e "${RED}✗ Redis 缓存异常${NC}"
    fi
}

# 停止服务
stop_services() {
    echo -e "${YELLOW}停止所有服务...${NC}"
    docker-compose down
    echo -e "${GREEN}✓ 服务已停止${NC}"
}

# 清理数据
clean_data() {
    echo -e "${RED}警告: 这将删除所有数据！${NC}"
    echo -n "确认删除? [y/N]: "
    read confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        docker-compose down -v
        rm -rf data/
        echo -e "${GREEN}✓ 数据已清理${NC}"
    else
        echo "取消操作"
    fi
}

# 显示帮助
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  start    - 启动服务"
    echo "  stop     - 停止服务"
    echo "  restart  - 重启服务"
    echo "  status   - 查看服务状态"
    echo "  logs     - 查看日志"
    echo "  clean    - 清理数据"
    echo "  help     - 显示帮助"
}

# 主程序
main() {
    case ${1:-start} in
        start)
            check_requirements
            create_directories
            generate_env
            select_mode
            ;;
        stop)
            stop_services
            ;;
        restart)
            stop_services
            sleep 2
            start_production
            ;;
        status)
            check_services
            ;;
        logs)
            docker-compose logs -f
            ;;
        clean)
            clean_data
            ;;
        help)
            show_help
            ;;
        *)
            echo -e "${RED}未知命令: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 运行主程序
main $@