#!/bin/bash

# 企业邮件系统 - 优化的部署脚本
# 修复了所有依赖问题，使用稳定的包版本

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 打印步骤
print_step() {
    echo ""
    print_message "$BLUE" "===> $1"
}

# 打印成功
print_success() {
    print_message "$GREEN" "✓ $1"
}

# 打印警告
print_warning() {
    print_message "$YELLOW" "⚠ $1"
}

# 打印错误
print_error() {
    print_message "$RED" "✗ $1"
}

# 头部信息
print_header() {
    echo ""
    echo "========================================"
    echo "   企业邮件系统 - 智能部署脚本 v3.0"
    echo "========================================"
    echo ""
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查 Java
check_java() {
    print_step "检查 Java 环境"
    
    if command_exists java; then
        JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
        if [[ "$JAVA_VERSION" -ge 17 ]]; then
            print_success "Java 已安装 (版本 >= 17)"
            return 0
        else
            print_warning "Java 版本过低，需要 17 或更高版本"
            return 1
        fi
    else
        print_error "Java 未安装"
        return 1
    fi
}

# 检查 Maven
check_maven() {
    print_step "检查 Maven"
    
    if command_exists mvn; then
        print_success "Maven 已安装: $(mvn -version | head -n 1)"
        return 0
    else
        print_error "Maven 未安装"
        return 1
    fi
}

# 检查 Node.js
check_node() {
    print_step "检查 Node.js"
    
    if command_exists node; then
        NODE_VERSION=$(node -version | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ "$NODE_VERSION" -ge 16 ]]; then
            print_success "Node.js 已安装 (版本 >= 16)"
            return 0
        else
            print_warning "Node.js 版本过低，需要 16 或更高版本"
            return 1
        fi
    else
        print_error "Node.js 未安装"
        return 1
    fi
}

# 检查 Docker
check_docker() {
    print_step "检查 Docker"
    
    if command_exists docker; then
        if docker info >/dev/null 2>&1; then
            print_success "Docker 已安装并运行"
            return 0
        else
            print_warning "Docker 已安装但未运行"
            
            # 尝试启动 Docker
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                print_message "$YELLOW" "尝试启动 Docker 服务..."
                sudo systemctl start docker 2>/dev/null || true
                sleep 2
                if docker info >/dev/null 2>&1; then
                    print_success "Docker 服务已启动"
                    return 0
                fi
            fi
            return 1
        fi
    else
        print_error "Docker 未安装"
        return 1
    fi
}

# 检查端口
check_ports() {
    print_step "检查端口占用"
    
    local ports=(80 443 3306 6379 8080 25 143 110)
    local has_conflict=false
    
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            print_warning "端口 $port 已被占用"
            has_conflict=true
        fi
    done
    
    if [ "$has_conflict" = false ]; then
        print_success "所有端口都可用"
    fi
}

# 配置 Maven 镜像
setup_maven_mirror() {
    print_step "配置 Maven 国内镜像"
    
    mkdir -p ~/.m2
    if [ ! -f ~/.m2/settings.xml ]; then
        cat > ~/.m2/settings.xml <<'EOF'
<settings>
  <mirrors>
    <mirror>
      <id>aliyun</id>
      <mirrorOf>central</mirrorOf>
      <name>Aliyun Maven Mirror</name>
      <url>https://maven.aliyun.com/repository/public</url>
    </mirror>
  </mirrors>
</settings>
EOF
        print_success "Maven 镜像配置完成"
    else
        print_message "$YELLOW" "Maven 配置已存在"
    fi
}

# 配置 NPM 镜像
setup_npm_mirror() {
    print_step "配置 NPM 国内镜像"
    
    npm config set registry https://registry.npmmirror.com
    print_success "NPM 镜像配置完成"
}

# 创建目录结构
create_directories() {
    print_step "创建必要的目录"
    
    mkdir -p data/{mysql,redis,mail}
    mkdir -p logs
    mkdir -p nginx/ssl
    
    print_success "目录创建完成"
}

# 生成环境变量
generate_env() {
    print_step "生成环境变量文件"
    
    if [ ! -f .env ]; then
        cat > .env <<'EOF'
# 数据库配置
MYSQL_ROOT_PASSWORD=root123456
MYSQL_DATABASE=mail_system
MYSQL_USER=mailuser
MYSQL_PASSWORD=mail123456

# Redis配置
REDIS_PASSWORD=

# JWT配置
JWT_SECRET=ThisIsAVerySecureSecretKeyForJWTTokenGenerationPleaseChangeInProduction2024

# 邮件服务器配置
MAIL_DOMAIN=enterprise.mail
SMTP_PORT=25
IMAP_PORT=143
POP3_PORT=110

# 应用配置
APP_ENV=production
APP_DEBUG=false
EOF
        print_success "环境变量文件已生成"
    else
        print_message "$YELLOW" "环境变量文件已存在"
    fi
}

# 构建后端
build_backend() {
    print_step "构建后端应用"
    
    cd backend
    
    # 清理和构建
    print_message "$YELLOW" "正在构建，这可能需要几分钟..."
    mvn clean package -DskipTests -q
    
    if [ -f target/*.jar ]; then
        print_success "后端构建成功"
    else
        print_error "后端构建失败"
        exit 1
    fi
    
    cd ..
}

# 构建前端
build_frontend() {
    print_step "构建前端应用"
    
    cd frontend
    
    # 安装依赖
    print_message "$YELLOW" "安装前端依赖..."
    npm install --silent
    
    # 构建
    print_message "$YELLOW" "构建前端应用..."
    npm run build
    
    if [ -d dist ]; then
        print_success "前端构建成功"
    else
        print_error "前端构建失败"
        exit 1
    fi
    
    cd ..
}

# Docker 部署
deploy_with_docker() {
    print_step "使用 Docker 部署"
    
    # 检查 docker-compose 命令
    if docker compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE="docker compose"
    elif command_exists docker-compose; then
        DOCKER_COMPOSE="docker-compose"
    else
        print_error "Docker Compose 未安装"
        return 1
    fi
    
    # 停止旧容器
    print_message "$YELLOW" "停止旧容器..."
    $DOCKER_COMPOSE down 2>/dev/null || true
    
    # 构建镜像
    print_message "$YELLOW" "构建 Docker 镜像..."
    $DOCKER_COMPOSE build
    
    # 启动服务
    print_message "$YELLOW" "启动服务..."
    $DOCKER_COMPOSE up -d
    
    # 等待服务就绪
    print_message "$YELLOW" "等待服务就绪..."
    sleep 10
    
    # 检查服务状态
    if curl -f http://localhost:8080/api/actuator/health >/dev/null 2>&1; then
        print_success "后端服务已启动"
    else
        print_warning "后端服务可能还在启动中"
    fi
    
    if curl -f http://localhost >/dev/null 2>&1; then
        print_success "前端服务已启动"
    else
        print_warning "前端服务可能还在启动中"
    fi
    
    print_success "Docker 部署完成"
}

# 本地部署
deploy_locally() {
    print_step "本地部署（不使用 Docker）"
    
    # 启动 MySQL（如果已安装）
    if command_exists mysql; then
        print_message "$YELLOW" "确保 MySQL 正在运行..."
    fi
    
    # 启动 Redis（如果已安装）
    if command_exists redis-server; then
        print_message "$YELLOW" "启动 Redis..."
        redis-server --daemonize yes
    fi
    
    # 启动后端
    print_message "$YELLOW" "启动后端服务..."
    nohup java -jar backend/target/*.jar > logs/backend.log 2>&1 &
    echo $! > backend.pid
    
    # 启动前端开发服务器
    print_message "$YELLOW" "启动前端服务..."
    cd frontend
    nohup npm run dev > ../logs/frontend.log 2>&1 &
    echo $! > ../frontend.pid
    cd ..
    
    print_success "本地部署完成"
}

# 显示访问信息
show_access_info() {
    echo ""
    echo "========================================"
    print_message "$GREEN" "部署成功完成！"
    echo "========================================"
    echo ""
    echo "访问地址："
    echo "  前端界面: http://localhost"
    echo "  后端 API: http://localhost:8080/api"
    echo "  API 文档: http://localhost:8080/api/swagger-ui.html"
    echo ""
    echo "默认账号："
    echo "  用户名: admin"
    echo "  密码: admin123"
    echo ""
    echo "邮件服务端口："
    echo "  SMTP: 25 (465 SSL)"
    echo "  IMAP: 143 (993 SSL)"
    echo "  POP3: 110 (995 SSL)"
    echo ""
    echo "管理命令："
    if [ "$DEPLOY_MODE" = "docker" ]; then
        echo "  查看日志: docker compose logs -f [service]"
        echo "  停止服务: docker compose down"
        echo "  重启服务: docker compose restart"
    else
        echo "  查看后端日志: tail -f logs/backend.log"
        echo "  查看前端日志: tail -f logs/frontend.log"
        echo "  停止服务: ./stop-local.sh"
    fi
    echo ""
}

# 主函数
main() {
    print_header
    
    # 检查基础环境
    local has_docker=true
    local has_local_env=true
    
    # 检查 Docker 环境
    if ! check_docker; then
        has_docker=false
    fi
    
    # 检查本地环境
    if ! check_java || ! check_maven || ! check_node; then
        has_local_env=false
    fi
    
    # 选择部署模式
    DEPLOY_MODE=""
    if [ "$has_docker" = true ] && [ "$has_local_env" = true ]; then
        echo ""
        echo "检测到 Docker 和本地环境都可用"
        echo "请选择部署方式："
        echo "  1) Docker 部署（推荐）"
        echo "  2) 本地部署"
        read -p "请输入选择 (1/2): " choice
        case $choice in
            1) DEPLOY_MODE="docker" ;;
            2) DEPLOY_MODE="local" ;;
            *) DEPLOY_MODE="docker" ;;
        esac
    elif [ "$has_docker" = true ]; then
        DEPLOY_MODE="docker"
    elif [ "$has_local_env" = true ]; then
        DEPLOY_MODE="local"
    else
        print_error "没有可用的部署环境"
        echo "请安装 Docker 或者 Java 17 + Maven + Node.js"
        exit 1
    fi
    
    # 通用准备工作
    check_ports
    create_directories
    generate_env
    
    # 根据模式部署
    if [ "$DEPLOY_MODE" = "docker" ]; then
        print_message "$BLUE" "使用 Docker 模式部署"
        deploy_with_docker
    else
        print_message "$BLUE" "使用本地模式部署"
        setup_maven_mirror
        setup_npm_mirror
        build_backend
        build_frontend
        deploy_locally
    fi
    
    # 显示访问信息
    show_access_info
}

# 运行主函数
main "$@"