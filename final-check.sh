#!/bin/bash

# 企业邮件系统 - 最终验证报告
# 验证所有修复是否成功完成

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   企业邮件系统 - 最终验证报告${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# 统计变量
total_checks=0
passed_checks=0
failed_checks=0
warnings=0

# 检查函数
check_file() {
    local file=$1
    local description=$2
    total_checks=$((total_checks + 1))
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        passed_checks=$((passed_checks + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        failed_checks=$((failed_checks + 1))
        return 1
    fi
}

check_dir() {
    local dir=$1
    local description=$2
    total_checks=$((total_checks + 1))
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $description"
        passed_checks=$((passed_checks + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        failed_checks=$((failed_checks + 1))
        return 1
    fi
}

check_content() {
    local file=$1
    local pattern=$2
    local description=$3
    total_checks=$((total_checks + 1))
    
    if [ -f "$file" ] && grep -q "$pattern" "$file" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $description"
        passed_checks=$((passed_checks + 1))
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $description"
        warnings=$((warnings + 1))
        return 1
    fi
}

# 1. 核心文件检查
echo -e "${BLUE}1. 核心文件检查${NC}"
echo "-------------------"
check_file "backend/pom.xml" "Maven配置文件存在"
check_file "frontend/package.json" "前端依赖配置存在"
check_file "docker-compose.yml" "Docker编排文件存在"
check_file ".env" "环境配置文件存在"
check_file ".gitignore" "Git忽略配置存在"
echo ""

# 2. Docker相关文件
echo -e "${BLUE}2. Docker配置检查${NC}"
echo "-------------------"
check_file "backend/Dockerfile" "后端Dockerfile存在"
check_file "frontend/Dockerfile" "前端Dockerfile存在"
check_file "frontend/nginx.conf" "Nginx配置文件存在"
check_file "docker-compose.prod.yml" "生产环境Docker配置存在"
echo ""

# 3. 后端配置文件
echo -e "${BLUE}3. 后端配置文件${NC}"
echo "-------------------"
check_file "backend/src/main/resources/application.yml" "主配置文件存在"
check_file "backend/src/main/resources/application-dev.yml" "开发环境配置存在"
check_file "backend/src/main/resources/application-test.yml" "测试环境配置存在"
check_file "backend/src/main/resources/application-prod.yml" "生产环境配置存在"
check_file "backend/src/main/resources/application-docker.yml" "Docker环境配置存在"
echo ""

# 4. 前端API文件
echo -e "${BLUE}4. 前端API实现${NC}"
echo "-------------------"
check_file "frontend/src/api/auth.ts" "认证API存在"
check_file "frontend/src/api/email.ts" "邮件API存在"
check_file "frontend/src/api/user.ts" "用户API存在"
check_file "frontend/src/api/attachment.ts" "附件API存在"
check_file "frontend/src/api/folder.ts" "文件夹API存在"
check_file "frontend/src/api/alias.ts" "别名API存在"
echo ""

# 5. 类型定义文件
echo -e "${BLUE}5. TypeScript类型定义${NC}"
echo "-------------------"
check_file "frontend/src/types/user.ts" "用户类型定义存在"
check_file "frontend/src/types/email.ts" "邮件类型定义存在"
check_file "frontend/src/types/folder.ts" "文件夹类型定义存在"
check_file "frontend/src/types/alias.ts" "别名类型定义存在"
echo ""

# 6. 安全配置检查
echo -e "${BLUE}6. 安全配置检查${NC}"
echo "-------------------"
check_file "backend/src/main/java/com/enterprise/mail/config/EnhancedSecurityConfig.java" "增强安全配置存在"
check_file "backend/src/main/java/com/enterprise/mail/security/JwtAuthenticationFilter.java" "JWT过滤器存在"
check_file "backend/src/main/java/com/enterprise/mail/security/JwtTokenUtil.java" "JWT工具类存在"
check_file ".env.production.template" "生产环境配置模板存在"
echo ""

# 7. 数据库文件
echo -e "${BLUE}7. 数据库初始化${NC}"
echo "-------------------"
check_file "backend/src/main/resources/schema.sql" "数据库结构文件存在"
check_file "backend/src/main/resources/data.sql" "初始数据文件存在"
check_file "backend/src/main/resources/init.sql" "Docker初始化脚本存在"
echo ""

# 8. 核心服务检查
echo -e "${BLUE}8. 核心服务实现${NC}"
echo "-------------------"
check_file "backend/src/main/java/com/enterprise/mail/service/EmailService.java" "邮件服务存在"
check_file "backend/src/main/java/com/enterprise/mail/service/UserService.java" "用户服务存在"
check_file "backend/src/main/java/com/enterprise/mail/service/AuthService.java" "认证服务存在"
check_file "backend/src/main/java/com/enterprise/mail/service/SmtpServerService.java" "SMTP服务存在"
echo ""

# 9. 密码安全检查
echo -e "${BLUE}9. 密码安全检查${NC}"
echo "-------------------"
if [ -f ".env" ]; then
    if grep -q "root123456\|admin123456\|mail123456\|changeme" ".env" 2>/dev/null; then
        echo -e "${RED}✗${NC} .env文件包含弱密码"
        failed_checks=$((failed_checks + 1))
    else
        echo -e "${GREEN}✓${NC} .env文件无弱密码"
        passed_checks=$((passed_checks + 1))
    fi
    total_checks=$((total_checks + 1))
fi

if [ -f "backend/src/main/resources/application.yml" ]; then
    if grep -q "changeme\|admin123456\|root123456" "backend/src/main/resources/application.yml" 2>/dev/null; then
        echo -e "${YELLOW}⚠${NC} application.yml可能包含弱密码"
        warnings=$((warnings + 1))
    else
        echo -e "${GREEN}✓${NC} application.yml无明显弱密码"
        passed_checks=$((passed_checks + 1))
    fi
    total_checks=$((total_checks + 1))
fi
echo ""

# 10. Git忽略配置检查
echo -e "${BLUE}10. Git忽略配置${NC}"
echo "-------------------"
check_content ".gitignore" ".env.production" ".gitignore包含.env.production"
check_content ".gitignore" "application-prod.yml" ".gitignore包含生产配置"
check_content ".gitignore" "*.pem" ".gitignore包含证书文件"
check_content ".gitignore" "secrets/" ".gitignore包含secrets目录"
echo ""

# 11. 检查脚本文件
echo -e "${BLUE}11. 辅助脚本检查${NC}"
echo "-------------------"
check_file "build.sh" "构建脚本存在"
check_file "deploy.sh" "部署脚本存在"
check_file "super-check-v6.sh" "系统检查脚本v6存在"
check_file "auto-fix.sh" "自动修复脚本存在"
echo ""

# 12. 目录结构检查
echo -e "${BLUE}12. 目录结构检查${NC}"
echo "-------------------"
check_dir "backend/src/main/java/com/enterprise/mail" "后端源码目录存在"
check_dir "frontend/src/views" "前端视图目录存在"
check_dir "frontend/src/components" "前端组件目录存在"
check_dir "frontend/src/api" "前端API目录存在"
check_dir "frontend/src/types" "前端类型定义目录存在"
echo ""

# 统计报告
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   验证统计报告${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# 计算通过率
pass_rate=$((passed_checks * 100 / total_checks))

echo -e "总检查项: ${total_checks}"
echo -e "${GREEN}通过: ${passed_checks}${NC}"
echo -e "${RED}失败: ${failed_checks}${NC}"
echo -e "${YELLOW}警告: ${warnings}${NC}"
echo ""

# 进度条
echo -n "通过率: ["
for i in {1..20}; do
    if [ $((i * 5)) -le $pass_rate ]; then
        echo -n "█"
    else
        echo -n "░"
    fi
done
echo "] ${pass_rate}%"
echo ""

# 最终评估
if [ $pass_rate -ge 90 ]; then
    echo -e "${GREEN}✅ 系统状态: 优秀${NC}"
    echo "系统已准备就绪，可以进行部署。"
elif [ $pass_rate -ge 75 ]; then
    echo -e "${GREEN}✅ 系统状态: 良好${NC}"
    echo "系统基本就绪，建议处理警告项后部署。"
elif [ $pass_rate -ge 60 ]; then
    echo -e "${YELLOW}⚠ 系统状态: 一般${NC}"
    echo "系统存在一些问题，建议修复后再部署。"
else
    echo -e "${RED}❌ 系统状态: 需要修复${NC}"
    echo "系统存在较多问题，必须修复后才能部署。"
fi
echo ""

# 修复建议
if [ $failed_checks -gt 0 ] || [ $warnings -gt 0 ]; then
    echo -e "${BLUE}修复建议:${NC}"
    echo "-------------------"
    
    if [ ! -f "frontend/src/api/user.ts" ]; then
        echo "• 运行 auto-fix.sh 创建缺失的API文件"
    fi
    
    if [ ! -f "backend/src/main/resources/application-dev.yml" ]; then
        echo "• 运行 auto-fix.sh 创建环境配置文件"
    fi
    
    if grep -q "root123456\|admin123456" ".env" 2>/dev/null; then
        echo "• 更新.env文件中的弱密码"
    fi
    
    if [ ! -f ".env.production.template" ]; then
        echo "• 创建生产环境配置模板"
    fi
    
    echo ""
fi

# 下一步操作
echo -e "${MAGENTA}下一步操作:${NC}"
echo "-------------------"
if [ $pass_rate -ge 75 ]; then
    echo "1. 运行构建: ./build.sh"
    echo "2. 本地测试: docker-compose up -d"
    echo "3. 生产部署: ./deploy.sh"
else
    echo "1. 运行修复: ./auto-fix.sh"
    echo "2. 重新检查: ./final-check.sh"
    echo "3. 查看日志: tail -f logs/*.log"
fi
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   检查完成 - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}========================================${NC}"

# 返回状态码
if [ $failed_checks -eq 0 ]; then
    exit 0
else
    exit 1
fi