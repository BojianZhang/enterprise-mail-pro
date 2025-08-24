#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================"
echo "企业邮件系统 - 本地运行脚本"
echo "========================================"
echo ""
echo "此脚本用于在无法访问 Docker Hub 时本地运行项目"
echo ""

# 检查 Java
check_java() {
    echo "检查 Java..."
    if command -v java >/dev/null 2>&1; then
        JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo -e "${GREEN}✓ Java 已安装: $JAVA_VERSION${NC}"
        
        # 检查 Java 版本是否为 17 或更高
        if [[ "$JAVA_VERSION" =~ ^17\. ]] || [[ "$JAVA_VERSION" =~ ^1[89]\. ]] || [[ "$JAVA_VERSION" =~ ^2[0-9]\. ]]; then
            return 0
        else
            echo -e "${YELLOW}警告: 需要 Java 17 或更高版本${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Java 未安装${NC}"
        echo "请安装 Java 17 或更高版本"
        return 1
    fi
}

# 检查 Maven
check_maven() {
    echo "检查 Maven..."
    if command -v mvn >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Maven 已安装: $(mvn -version | head -n 1)${NC}"
        return 0
    else
        echo -e "${RED}✗ Maven 未安装${NC}"
        echo "请安装 Maven 3.6 或更高版本"
        return 1
    fi
}

# 检查 Node.js
check_node() {
    echo "检查 Node.js..."
    if command -v node >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Node.js 已安装: $(node -version)${NC}"
        return 0
    else
        echo -e "${RED}✗ Node.js 未安装${NC}"
        echo "请安装 Node.js 16 或更高版本"
        return 1
    fi
}

# 检查 MySQL
check_mysql() {
    echo "检查 MySQL..."
    if command -v mysql >/dev/null 2>&1; then
        echo -e "${GREEN}✓ MySQL 客户端已安装${NC}"
        
        # 尝试连接 MySQL
        if mysql -h localhost -u root -e "SELECT 1" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ MySQL 服务正在运行${NC}"
            return 0
        else
            echo -e "${YELLOW}MySQL 服务未运行或需要密码${NC}"
            echo "请确保 MySQL 正在运行并且可以访问"
            return 1
        fi
    else
        echo -e "${YELLOW}MySQL 客户端未安装${NC}"
        echo "请安装并启动 MySQL 8.0"
        return 1
    fi
}

# 设置数据库
setup_database() {
    echo ""
    echo "设置数据库..."
    
    read -p "请输入 MySQL root 密码: " -s MYSQL_ROOT_PWD
    echo ""
    
    # 创建数据库和用户
    mysql -h localhost -u root -p"$MYSQL_ROOT_PWD" <<EOF
CREATE DATABASE IF NOT EXISTS mail_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'mailuser'@'localhost' IDENTIFIED BY 'mail123456';
GRANT ALL PRIVILEGES ON mail_system.* TO 'mailuser'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 数据库设置完成${NC}"
    else
        echo -e "${RED}✗ 数据库设置失败${NC}"
        return 1
    fi
}

# 构建后端
build_backend() {
    echo ""
    echo "构建后端..."
    cd backend
    
    # 使用国内镜像源
    if [ -f ~/.m2/settings.xml ]; then
        echo "使用已有的 Maven 配置"
    else
        echo "配置 Maven 国内镜像源..."
        mkdir -p ~/.m2
        cat > ~/.m2/settings.xml <<EOF
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
    fi
    
    mvn clean package -DskipTests
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 后端构建成功${NC}"
    else
        echo -e "${RED}✗ 后端构建失败${NC}"
        return 1
    fi
    
    cd ..
}

# 构建前端
build_frontend() {
    echo ""
    echo "构建前端..."
    cd frontend
    
    # 使用国内镜像源
    npm config set registry https://registry.npmmirror.com
    
    # 安装依赖
    echo "安装前端依赖..."
    npm install
    
    # 构建
    echo "构建前端..."
    npm run build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 前端构建成功${NC}"
    else
        echo -e "${RED}✗ 前端构建失败${NC}"
        return 1
    fi
    
    cd ..
}

# 启动后端
start_backend() {
    echo ""
    echo "启动后端服务..."
    
    # 创建日志目录
    mkdir -p logs
    
    # 设置环境变量
    export SPRING_DATASOURCE_URL="jdbc:mysql://localhost:3306/mail_system?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true"
    export SPRING_DATASOURCE_USERNAME="mailuser"
    export SPRING_DATASOURCE_PASSWORD="mail123456"
    export JWT_SECRET="ThisIsAVerySecureSecretKeyForJWTTokenGenerationPleaseChangeInProduction2024"
    
    # 启动后端
    nohup java -jar backend/target/*.jar > logs/backend.log 2>&1 &
    BACKEND_PID=$!
    echo "后端 PID: $BACKEND_PID"
    
    # 保存 PID
    echo $BACKEND_PID > backend.pid
    
    # 等待后端启动
    echo -n "等待后端启动..."
    for i in {1..30}; do
        if curl -f http://localhost:8080/api/actuator/health >/dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC}"
            echo -e "${GREEN}后端启动成功${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
    done
    
    echo -e " ${RED}✗${NC}"
    echo -e "${RED}后端启动失败，请查看 logs/backend.log${NC}"
    return 1
}

# 启动前端
start_frontend() {
    echo ""
    echo "启动前端服务..."
    
    # 检查是否有 nginx
    if command -v nginx >/dev/null 2>&1; then
        echo "使用 Nginx 服务前端文件..."
        
        # 创建 nginx 配置
        sudo tee /etc/nginx/sites-available/mail-frontend <<EOF
server {
    listen 80;
    server_name localhost;
    root $(pwd)/frontend/dist;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
        
        sudo ln -sf /etc/nginx/sites-available/mail-frontend /etc/nginx/sites-enabled/
        sudo nginx -s reload
        
        echo -e "${GREEN}✓ 前端已通过 Nginx 部署${NC}"
    else
        echo "使用 Node.js 开发服务器..."
        cd frontend
        npm run dev > ../logs/frontend.log 2>&1 &
        FRONTEND_PID=$!
        echo "前端 PID: $FRONTEND_PID"
        echo $FRONTEND_PID > ../frontend.pid
        cd ..
        
        echo -e "${GREEN}✓ 前端开发服务器已启动${NC}"
    fi
}

# 显示访问信息
show_info() {
    echo ""
    echo "========================================"
    echo -e "${GREEN}本地运行成功！${NC}"
    echo "========================================"
    echo ""
    echo "访问地址："
    echo -e "  前端界面: ${BLUE}http://localhost${NC}"
    echo -e "  后端 API: ${BLUE}http://localhost:8080${NC}"
    echo -e "  API 文档: ${BLUE}http://localhost:8080/swagger-ui.html${NC}"
    echo ""
    echo "查看日志："
    echo "  后端: tail -f logs/backend.log"
    echo "  前端: tail -f logs/frontend.log"
    echo ""
    echo "停止服务："
    echo "  ./stop-local.sh"
}

# 主函数
main() {
    # 检查依赖
    echo "检查系统依赖..."
    
    if ! check_java; then
        exit 1
    fi
    
    if ! check_maven; then
        exit 1
    fi
    
    if ! check_node; then
        exit 1
    fi
    
    if ! check_mysql; then
        read -p "是否继续？MySQL 需要单独配置 (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # 设置数据库
    read -p "是否需要设置数据库？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_database
    fi
    
    # 构建项目
    build_backend
    build_frontend
    
    # 启动服务
    start_backend
    start_frontend
    
    # 显示信息
    show_info
}

# 运行主函数
main