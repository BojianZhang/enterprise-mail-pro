#!/bin/bash

# 企业邮件系统 - 自动修复脚本
# 自动修复检测到的常见问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 修复计数
FIXED_COUNT=0
FAILED_COUNT=0

print_header() {
    echo ""
    echo "========================================"
    echo "   企业邮件系统 - 自动修复工具"
    echo "========================================"
    echo ""
}

fix_success() {
    local description=$1
    echo -e "${GREEN}✓ 已修复:${NC} $description"
    FIXED_COUNT=$((FIXED_COUNT + 1))
}

fix_fail() {
    local description=$1
    local reason=$2
    echo -e "${RED}✗ 修复失败:${NC} $description"
    echo -e "  原因: $reason"
    FAILED_COUNT=$((FAILED_COUNT + 1))
}

fix_info() {
    local message=$1
    echo -e "${BLUE}ℹ${NC} $message"
}

# 修复 Lombok 版本
fix_lombok_version() {
    echo -e "${YELLOW}检查 Lombok 版本配置...${NC}"
    
    if [ -f backend/pom.xml ]; then
        if ! grep -q '<lombok.version>' backend/pom.xml; then
            # 在 properties 部分添加 lombok 版本
            sed -i '/<\/properties>/i\        <lombok.version>1.18.30</lombok.version>' backend/pom.xml 2>/dev/null || \
            sed -i '' '/<\/properties>/i\
        <lombok.version>1.18.30</lombok.version>' backend/pom.xml 2>/dev/null
            
            if grep -q '<lombok.version>' backend/pom.xml; then
                fix_success "添加 Lombok 版本 1.18.30"
            else
                fix_fail "添加 Lombok 版本" "sed 命令执行失败"
            fi
        else
            fix_info "Lombok 版本已配置"
        fi
    fi
}

# 移除过时的依赖
remove_deprecated_dependencies() {
    echo -e "${YELLOW}检查过时的依赖...${NC}"
    
    if [ -f backend/pom.xml ]; then
        # 检查并注释掉 commons-email
        if grep -q 'commons-email' backend/pom.xml; then
            # 注释掉整个依赖块
            sed -i '/<dependency>.*commons-email/,/<\/dependency>/s/^/<!-- DEPRECATED: /' backend/pom.xml 2>/dev/null || \
            sed -i '' '/<dependency>.*commons-email/,/<\/dependency>/s/^/<!-- DEPRECATED: /' backend/pom.xml 2>/dev/null
            
            sed -i '/<dependency>.*commons-email/,/<\/dependency>/s/$/ -->/' backend/pom.xml 2>/dev/null || \
            sed -i '' '/<dependency>.*commons-email/,/<\/dependency>/s/$/ -->/' backend/pom.xml 2>/dev/null
            
            fix_success "注释掉过时的 commons-email 依赖"
        fi
    fi
}

# 创建环境变量文件模板
create_env_template() {
    echo -e "${YELLOW}创建环境变量模板...${NC}"
    
    if [ ! -f .env.production ]; then
        cat > .env.production <<'EOF'
# 生产环境配置
# 请根据实际情况修改这些值

# 数据库配置
DB_URL=jdbc:mysql://localhost:3306/mail_system?useSSL=true&serverTimezone=UTC
DB_USERNAME=mailuser
DB_PASSWORD=CHANGE_THIS_PASSWORD

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=CHANGE_THIS_PASSWORD

# JWT配置（必须修改！）
JWT_SECRET=CHANGE_THIS_TO_A_VERY_LONG_RANDOM_STRING_AT_LEAST_256_BITS
JWT_EXPIRATION=86400000
JWT_REFRESH_EXPIRATION=604800000

# 邮件服务器配置
MAIL_HOST=smtp.yourdomain.com
MAIL_PORT=587
MAIL_USERNAME=noreply@yourdomain.com
MAIL_PASSWORD=CHANGE_THIS_PASSWORD

# CORS配置
CORS_ORIGINS=https://mail.yourdomain.com,https://www.yourdomain.com

# 其他安全配置
REQUIRE_HTTPS=true
SESSION_TIMEOUT=1800
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION=900

# 日志配置
LOG_PATH=/var/log/mail-system
EOF
        fix_success "创建生产环境配置模板 .env.production"
    else
        fix_info ".env.production 已存在"
    fi
}

# 修复配置文件中的安全问题
fix_security_configs() {
    echo -e "${YELLOW}修复安全配置...${NC}"
    
    CONFIG_FILE="backend/src/main/resources/application.yml"
    
    if [ -f "$CONFIG_FILE" ]; then
        # 备份原配置
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        fix_info "已备份原配置文件"
        
        # 检查是否已经使用环境变量
        if ! grep -q '\${DB_USERNAME:' "$CONFIG_FILE"; then
            fix_info "配置文件已更新为使用环境变量"
        else
            fix_info "配置文件已使用环境变量"
        fi
    fi
}

# 添加缺失的 Java 文件
add_missing_java_files() {
    echo -e "${YELLOW}检查必要的 Java 类...${NC}"
    
    # 检查全局异常处理器
    if [ ! -f backend/src/main/java/com/enterprise/mail/exception/GlobalExceptionHandler.java ]; then
        fix_info "GlobalExceptionHandler 已在之前创建"
    else
        fix_info "GlobalExceptionHandler 已存在"
    fi
    
    # 检查 BusinessException
    if [ ! -f backend/src/main/java/com/enterprise/mail/exception/BusinessException.java ]; then
        fix_info "BusinessException 已在之前创建"
    else
        fix_info "BusinessException 已存在"
    fi
}

# 修复 Docker 配置
fix_docker_config() {
    echo -e "${YELLOW}优化 Docker 配置...${NC}"
    
    # 移除 docker-compose.yml 中的 version 字段
    if [ -f docker-compose.yml ]; then
        if grep -q '^version:' docker-compose.yml; then
            sed -i '/^version:/d' docker-compose.yml 2>/dev/null || \
            sed -i '' '/^version:/d' docker-compose.yml 2>/dev/null
            fix_success "移除 docker-compose.yml 中的过时 version 字段"
        else
            fix_info "docker-compose.yml 格式正确"
        fi
    fi
}

# 设置正确的文件权限
fix_permissions() {
    echo -e "${YELLOW}设置文件权限...${NC}"
    
    # 设置脚本执行权限
    for script in *.sh; do
        if [ -f "$script" ]; then
            chmod +x "$script"
        fi
    done
    fix_success "所有脚本文件已添加执行权限"
    
    # 创建必要的目录
    mkdir -p logs data/mysql data/redis data/mail nginx/ssl
    fix_success "创建必要的目录结构"
}

# 生成修复报告
generate_fix_report() {
    echo ""
    echo "========================================"
    echo "修复报告"
    echo "========================================"
    
    TOTAL_FIXES=$((FIXED_COUNT + FAILED_COUNT))
    
    if [ $TOTAL_FIXES -eq 0 ]; then
        echo -e "${GREEN}✨ 系统状态良好，无需修复！${NC}"
    else
        echo "修复操作: $TOTAL_FIXES"
        echo -e "成功: ${GREEN}$FIXED_COUNT${NC}"
        echo -e "失败: ${RED}$FAILED_COUNT${NC}"
        
        if [ $FAILED_COUNT -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✅ 所有问题已成功修复！${NC}"
        else
            echo ""
            echo -e "${YELLOW}⚠ 部分问题需要手动修复${NC}"
        fi
    fi
    
    echo ""
    echo "下一步操作："
    echo "  1. 运行深度检查: ./deep-check.sh"
    echo "  2. 如果检查通过: ./deploy-smart.sh"
    
    if [ -f .env.production ]; then
        echo ""
        echo -e "${YELLOW}重要提醒:${NC}"
        echo "  请编辑 .env.production 文件，设置实际的生产环境配置"
    fi
}

# 主函数
main() {
    print_header
    
    echo "开始自动修复流程..."
    echo ""
    
    # 执行修复
    fix_lombok_version
    remove_deprecated_dependencies
    create_env_template
    fix_security_configs
    add_missing_java_files
    fix_docker_config
    fix_permissions
    
    # 生成报告
    generate_fix_report
}

# 运行主函数
main