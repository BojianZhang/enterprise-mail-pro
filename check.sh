#!/bin/bash

# 项目完整性检查脚本

set -e

echo "======================================"
echo "企业邮件系统 - 项目完整性检查"
echo "======================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# 检查函数
check_file() {
    local file=$1
    local description=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗${NC} $description (缺失: $file)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

check_directory() {
    local dir=$1
    local description=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗${NC} $description (缺失: $dir)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

echo "1. 检查项目结构"
echo "--------------------------------------"
check_directory "backend" "后端项目目录"
check_directory "frontend" "前端项目目录"
check_directory "backend/src/main/java" "Java源代码目录"
check_directory "frontend/src" "前端源代码目录"
echo ""

echo "2. 检查配置文件"
echo "--------------------------------------"
check_file "docker-compose.yml" "Docker Compose配置"
check_file "backend/pom.xml" "Maven配置文件"
check_file "frontend/package.json" "前端依赖配置"
check_file "backend/src/main/resources/application.yml" "Spring Boot配置"
check_file "frontend/vite.config.ts" "Vite配置文件"
echo ""

echo "3. 检查Docker文件"
echo "--------------------------------------"
check_file "backend/Dockerfile" "后端Dockerfile"
check_file "frontend/Dockerfile" "前端Dockerfile"
check_file "frontend/nginx.conf" "Nginx配置"
echo ""

echo "4. 检查部署脚本"
echo "--------------------------------------"
check_file "deploy.sh" "Linux部署脚本"
check_file "deploy.bat" "Windows部署脚本"
check_file "test.sh" "Linux测试脚本"
check_file "test.bat" "Windows测试脚本"
echo ""

echo "5. 检查核心源文件"
echo "--------------------------------------"
check_file "backend/src/main/java/com/enterprise/mail/EnterpriseMailApplication.java" "Spring Boot主类"
check_file "backend/src/main/java/com/enterprise/mail/entity/User.java" "用户实体"
check_file "backend/src/main/java/com/enterprise/mail/entity/Email.java" "邮件实体"
check_file "backend/src/main/java/com/enterprise/mail/controller/AuthController.java" "认证控制器"
check_file "backend/src/main/java/com/enterprise/mail/service/EmailService.java" "邮件服务"
check_file "frontend/src/main.ts" "前端入口文件"
check_file "frontend/src/App.vue" "Vue根组件"
check_file "frontend/src/router/index.ts" "路由配置"
echo ""

echo "6. 检查文档"
echo "--------------------------------------"
check_file "README.md" "项目说明文档"
check_file "DEPLOYMENT_GUIDE.md" "部署指南"
check_file "QUICK_START.md" "快速启动指南"
check_file "PROJECT_SUMMARY.md" "项目总结"
echo ""

echo "7. 检查数据库脚本"
echo "--------------------------------------"
check_file "backend/src/main/resources/init.sql" "数据库初始化脚本"
echo ""

echo "======================================"
echo "检查结果汇总"
echo "======================================"
echo -e "总检查项: $TOTAL_CHECKS"
echo -e "${GREEN}通过: $PASSED_CHECKS${NC}"
echo -e "${RED}失败: $FAILED_CHECKS${NC}"
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✓ 项目完整性检查通过！${NC}"
    echo "您可以运行 deploy.sh 来部署项目"
    exit 0
else
    echo -e "${RED}✗ 项目完整性检查失败！${NC}"
    echo "请检查缺失的文件或目录"
    exit 1
fi