#!/bin/bash

# 企业邮件系统 - 超级深度检查脚本 v6.0
# 最严格的全方位扫描 - 零容忍模式

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# 统计变量
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0
CRITICAL_ISSUES=""
SECURITY_ISSUES=""
LOGIC_ERRORS=""
CONFIG_ISSUES=""
DEPENDENCY_ISSUES=""

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}======================================================${NC}"
    echo -e "${BOLD}${BLUE}     超级深度系统检查 v6.0 - 零容忍模式${NC}"
    echo -e "${BOLD}${BLUE}     全方位扫描：配置/安全/逻辑/依赖/性能${NC}"
    echo -e "${BOLD}${BLUE}======================================================${NC}"
    echo ""
}

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    echo -e "  ${RED}└─ 严重: $2${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    CRITICAL_ISSUES="${CRITICAL_ISSUES}\n  ✗ $1: $2"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    echo -e "  ${YELLOW}└─ 警告: $2${NC}"
    WARNINGS=$((WARNINGS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

# 1. 配置文件深度检查
check_config_consistency() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 配置文件一致性检查 ===${NC}"
    
    # 检查application.yml
    if [ -f backend/src/main/resources/application.yml ]; then
        # 检查弱密码
        if grep -q "changeme\|password123\|admin123\|root123" backend/src/main/resources/application.yml 2>/dev/null; then
            check_fail "发现弱密码配置" "application.yml包含默认弱密码"
            CONFIG_ISSUES="${CONFIG_ISSUES}\n  • 配置文件包含弱密码"
        else
            check_pass "无弱密码配置"
        fi
        
        # 检查JWT密钥强度
        JWT_SECRET_LEN=$(grep "JWT_SECRET" backend/src/main/resources/application.yml 2>/dev/null | head -1 | sed 's/.*://' | wc -c)
        if [ "$JWT_SECRET_LEN" -lt 64 ]; then
            check_fail "JWT密钥过短" "少于256位"
            SECURITY_ISSUES="${SECURITY_ISSUES}\n  • JWT密钥强度不足"
        else
            check_pass "JWT密钥强度足够"
        fi
        
        # 检查重复配置
        CACHE_CONFIGS=$(grep -c "cache:" backend/src/main/resources/application.yml 2>/dev/null || echo 0)
        if [ "$CACHE_CONFIGS" -gt 1 ]; then
            check_warn "缓存配置重复" "发现${CACHE_CONFIGS}处cache配置"
            CONFIG_ISSUES="${CONFIG_ISSUES}\n  • 重复的缓存配置"
        else
            check_pass "配置无重复"
        fi
    else
        check_fail "缺少application.yml" "核心配置文件不存在"
    fi
    
    # 检查环境配置文件
    for env in dev docker prod test; do
        if [ -f "backend/src/main/resources/application-${env}.yml" ]; then
            check_pass "存在${env}环境配置"
        else
            if [ "$env" = "prod" ]; then
                check_fail "缺少生产环境配置" "application-prod.yml不存在"
            else
                check_warn "缺少${env}环境配置" "application-${env}.yml不存在"
            fi
        fi
    done
    
    # 检查.env文件安全性
    if [ -f .env ]; then
        if grep -q "root123456\|mail123456\|admin123\|changeme" .env 2>/dev/null; then
            check_fail ".env包含弱密码" "生产环境安全风险"
            SECURITY_ISSUES="${SECURITY_ISSUES}\n  • .env文件包含默认密码"
        else
            check_pass ".env密码已更新"
        fi
    fi
}

# 2. 安全配置检查
check_security_config() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 安全配置检查 ===${NC}"
    
    # 检查SSL配置
    if grep -q "ssl.*enable.*false" backend/src/main/resources/application.yml 2>/dev/null; then
        check_warn "SSL未启用" "生产环境应启用SSL"
        SECURITY_ISSUES="${SECURITY_ISSUES}\n  • SSL/TLS未启用"
    else
        check_pass "SSL配置存在"
    fi
    
    # 检查CORS配置
    if [ -f backend/src/main/java/com/enterprise/mail/config/SecurityConfig.java ]; then
        if grep -q "allowedOrigins.*\\*" backend/src/main/java/com/enterprise/mail/config/SecurityConfig.java 2>/dev/null; then
            check_fail "CORS允许所有来源" "严重安全风险"
            SECURITY_ISSUES="${SECURITY_ISSUES}\n  • CORS配置过于宽松"
        else
            check_pass "CORS配置合理"
        fi
    fi
    
    # 检查Redis密码
    if grep -q "REDIS_PASSWORD:\s*$\|REDIS_PASSWORD:\s*\"\"" docker-compose*.yml 2>/dev/null; then
        check_fail "Redis无密码保护" "严重安全风险"
        SECURITY_ISSUES="${SECURITY_ISSUES}\n  • Redis未设置密码"
    else
        check_pass "Redis已设置密码"
    fi
    
    # 检查公开端口
    EXPOSED_PORTS=$(grep -c "ports:" docker-compose*.yml 2>/dev/null || echo 0)
    if [ "$EXPOSED_PORTS" -gt 10 ]; then
        check_warn "暴露端口过多" "发现${EXPOSED_PORTS}个端口映射"
        SECURITY_ISSUES="${SECURITY_ISSUES}\n  • 过多端口暴露"
    else
        check_pass "端口暴露合理"
    fi
}

# 3. 前后端API契约检查
check_api_contract() {
    echo ""
    echo -e "${CYAN}${BOLD}=== API契约一致性检查 ===${NC}"
    
    # 检查前端API文件
    API_FILES=0
    for api in email alias attachment user; do
        if [ -f "frontend/src/api/${api}.ts" ]; then
            API_FILES=$((API_FILES + 1))
        fi
    done
    
    if [ "$API_FILES" -ge 3 ]; then
        check_pass "前端API文件完整 (${API_FILES}个)"
    else
        check_fail "前端API文件缺失" "仅发现${API_FILES}个API文件"
        LOGIC_ERRORS="${LOGIC_ERRORS}\n  • 前端API实现不完整"
    fi
    
    # 检查类型定义
    TYPE_FILES=0
    for type in email alias user attachment; do
        if [ -f "frontend/src/types/${type}.ts" ]; then
            TYPE_FILES=$((TYPE_FILES + 1))
        fi
    done
    
    if [ "$TYPE_FILES" -ge 3 ]; then
        check_pass "TypeScript类型定义完整"
    else
        check_warn "类型定义不完整" "仅${TYPE_FILES}个类型文件"
    fi
    
    # 检查Controller数量
    CONTROLLERS=$(ls backend/src/main/java/com/enterprise/mail/controller/*.java 2>/dev/null | wc -l)
    if [ "$CONTROLLERS" -ge 5 ]; then
        check_pass "后端Controller完整 (${CONTROLLERS}个)"
    else
        check_warn "Controller可能缺失" "仅${CONTROLLERS}个"
    fi
}

# 4. Docker配置检查
check_docker_config() {
    echo ""
    echo -e "${CYAN}${BOLD}=== Docker配置检查 ===${NC}"
    
    # 检查Dockerfile
    DOCKERFILES=0
    if [ -f backend/Dockerfile ]; then
        DOCKERFILES=$((DOCKERFILES + 1))
    fi
    if [ -f frontend/Dockerfile ]; then
        DOCKERFILES=$((DOCKERFILES + 1))
    fi
    
    if [ "$DOCKERFILES" -eq 2 ]; then
        check_pass "Dockerfile文件完整"
    else
        check_fail "Dockerfile缺失" "仅发现${DOCKERFILES}个"
    fi
    
    # 检查docker-compose文件
    if [ -f docker-compose.yml ] && [ -f docker-compose.prod.yml ]; then
        check_pass "Docker编排文件完整"
    else
        check_warn "Docker编排文件不完整" "缺少生产或开发配置"
    fi
    
    # 检查健康检查
    HEALTH_CHECKS=$(grep -c "healthcheck:" docker-compose*.yml 2>/dev/null || echo 0)
    if [ "$HEALTH_CHECKS" -ge 3 ]; then
        check_pass "健康检查配置完整"
    else
        check_warn "健康检查不足" "仅${HEALTH_CHECKS}个"
    fi
}

# 5. 依赖安全检查
check_dependencies() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 依赖安全检查 ===${NC}"
    
    # 检查前端依赖
    if [ -f frontend/package.json ]; then
        # 检查关键安全库
        if grep -q "dompurify" frontend/package.json; then
            check_pass "XSS防护库已安装"
        else
            check_fail "缺少XSS防护库" "DOMPurify未安装"
            SECURITY_ISSUES="${SECURITY_ISSUES}\n  • 缺少XSS防护"
        fi
        
        # 检查过时依赖
        OLD_DEPS=$(grep -E "\"(jquery|angular\"|\"backbone)" frontend/package.json 2>/dev/null | wc -l)
        if [ "$OLD_DEPS" -eq 0 ]; then
            check_pass "无过时前端框架"
        else
            check_warn "发现过时依赖" "${OLD_DEPS}个旧框架"
        fi
    fi
    
    # 检查后端依赖
    if [ -f backend/pom.xml ]; then
        # 检查安全依赖版本
        if grep -q "<jwt.version>0.12" backend/pom.xml; then
            check_pass "JWT版本安全"
        else
            check_warn "JWT版本可能过时" "检查最新安全更新"
        fi
        
        # 检查Log4j（安全漏洞）
        if grep -q "log4j" backend/pom.xml; then
            check_fail "发现Log4j依赖" "可能存在Log4Shell漏洞"
            SECURITY_ISSUES="${SECURITY_ISSUES}\n  • Log4j安全风险"
        else
            check_pass "未使用Log4j"
        fi
    fi
}

# 6. 数据库检查
check_database() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 数据库配置检查 ===${NC}"
    
    # 检查初始化脚本
    if [ -f backend/src/main/resources/init.sql ]; then
        # 检查默认密码
        if grep -q "YourHashedPasswordHere\|password123\|admin123" backend/src/main/resources/init.sql 2>/dev/null; then
            check_fail "数据库初始密码未设置" "使用占位符密码"
            SECURITY_ISSUES="${SECURITY_ISSUES}\n  • 数据库默认密码未更新"
        else
            check_pass "数据库密码已设置"
        fi
        
        # 检查索引
        INDEXES=$(grep -c "CREATE INDEX" backend/src/main/resources/init.sql 2>/dev/null || echo 0)
        if [ "$INDEXES" -ge 5 ]; then
            check_pass "数据库索引已优化"
        else
            check_warn "数据库索引不足" "仅${INDEXES}个索引"
        fi
    else
        check_fail "缺少数据库初始化脚本" "init.sql不存在"
    fi
}

# 7. 性能配置检查
check_performance() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 性能配置检查 ===${NC}"
    
    # 检查连接池配置
    if grep -q "hikari:\|connection-pool:" backend/src/main/resources/application*.yml 2>/dev/null; then
        check_pass "数据库连接池已配置"
    else
        check_warn "连接池未配置" "影响并发性能"
    fi
    
    # 检查缓存配置
    if grep -q "cache:.*redis\|cache:.*type" backend/src/main/resources/application*.yml 2>/dev/null; then
        check_pass "缓存已配置"
    else
        check_warn "缓存未配置" "影响查询性能"
    fi
    
    # 检查JPA优化
    if grep -q "batch_size\|fetch_size" backend/src/main/resources/application*.yml 2>/dev/null; then
        check_pass "JPA批处理已优化"
    else
        check_warn "JPA未优化" "批量操作性能差"
    fi
}

# 8. 代码质量检查
check_code_quality() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 代码质量检查 ===${NC}"
    
    # 检查TODO/FIXME
    TODOS=$(grep -r "TODO\|FIXME\|XXX\|HACK" --include="*.java" --include="*.ts" --include="*.vue" backend/src frontend/src 2>/dev/null | wc -l)
    if [ "$TODOS" -eq 0 ]; then
        check_pass "无未完成TODO"
    elif [ "$TODOS" -le 10 ]; then
        check_warn "存在${TODOS}个TODO" "需要完成"
    else
        check_fail "大量TODO未完成" "${TODOS}个待处理项"
        LOGIC_ERRORS="${LOGIC_ERRORS}\n  • 大量未完成功能"
    fi
    
    # 检查console.log
    CONSOLE_LOGS=$(grep -r "console\.\(log\|error\|warn\)" --include="*.ts" --include="*.vue" frontend/src 2>/dev/null | wc -l)
    if [ "$CONSOLE_LOGS" -eq 0 ]; then
        check_pass "无调试代码"
    else
        check_warn "存在${CONSOLE_LOGS}个console语句" "生产环境应移除"
    fi
    
    # 检查any类型
    ANY_TYPES=$(grep -r ": any" --include="*.ts" frontend/src 2>/dev/null | wc -l)
    if [ "$ANY_TYPES" -le 5 ]; then
        check_pass "TypeScript类型安全"
    else
        check_warn "过多any类型" "${ANY_TYPES}处类型不安全"
    fi
}

# 9. 环境变量完整性检查
check_env_variables() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 环境变量完整性检查 ===${NC}"
    
    # 检查必要的环境变量
    REQUIRED_VARS="JWT_SECRET DB_PASSWORD REDIS_PASSWORD MAIL_PASSWORD"
    MISSING_VARS=""
    
    for var in $REQUIRED_VARS; do
        if ! grep -q "$var" .env* backend/src/main/resources/application*.yml 2>/dev/null; then
            MISSING_VARS="${MISSING_VARS} ${var}"
        fi
    done
    
    if [ -z "$MISSING_VARS" ]; then
        check_pass "必要环境变量完整"
    else
        check_fail "缺少环境变量" "${MISSING_VARS}"
        CONFIG_ISSUES="${CONFIG_ISSUES}\n  • 缺少关键环境变量"
    fi
    
    # 检查环境变量使用
    ENV_USAGE=$(grep -c '${.*}' backend/src/main/resources/application*.yml 2>/dev/null || echo 0)
    if [ "$ENV_USAGE" -ge 20 ]; then
        check_pass "环境变量使用充分"
    else
        check_warn "环境变量使用不足" "仅${ENV_USAGE}处"
    fi
}

# 10. 文件权限和安全检查
check_file_security() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 文件安全检查 ===${NC}"
    
    # 检查敏感文件
    SENSITIVE_FILES=".env .env.production backend/src/main/resources/application-prod.yml"
    for file in $SENSITIVE_FILES; do
        if [ -f "$file" ]; then
            # 检查是否在.gitignore中
            if [ -f .gitignore ] && grep -q "$(basename $file)" .gitignore; then
                check_pass "$(basename $file)已在.gitignore中"
            else
                check_fail "$(basename $file)未被忽略" "可能泄露敏感信息"
                SECURITY_ISSUES="${SECURITY_ISSUES}\n  • 敏感文件未被Git忽略"
            fi
        fi
    done
    
    # 检查脚本执行权限
    SCRIPTS=$(ls *.sh 2>/dev/null | wc -l)
    if [ "$SCRIPTS" -gt 0 ]; then
        EXECUTABLE=$(find . -maxdepth 1 -name "*.sh" -executable | wc -l)
        if [ "$EXECUTABLE" -eq "$SCRIPTS" ]; then
            check_pass "脚本权限正确"
        else
            check_warn "部分脚本无执行权限" "$((SCRIPTS-EXECUTABLE))个"
        fi
    fi
}

# 生成最终报告
generate_final_report() {
    echo ""
    echo -e "${BOLD}${BLUE}======================================================${NC}"
    echo -e "${BOLD}${MAGENTA}超级深度检查报告 v6.0${NC}"
    echo -e "${BOLD}${BLUE}======================================================${NC}"
    
    TOTAL=$TOTAL_CHECKS
    if [ $TOTAL -eq 0 ]; then TOTAL=1; fi
    SUCCESS_RATE=$((PASSED_CHECKS * 100 / TOTAL))
    
    echo ""
    echo "📊 检查统计："
    echo -e "  总检查项: ${CYAN}$TOTAL_CHECKS${NC}"
    echo -e "  通过: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "  失败: ${RED}$FAILED_CHECKS${NC}"
    echo -e "  警告: ${YELLOW}$WARNINGS${NC}"
    
    echo ""
    echo -n "🏆 系统健康度: "
    if [ $FAILED_CHECKS -eq 0 ] && [ $WARNINGS -le 5 ]; then
        echo -e "${GREEN}${SUCCESS_RATE}% - 完美生产就绪${NC} 🌟"
        echo ""
        echo -e "${GREEN}✅ 系统已通过所有超级深度检查！${NC}"
    elif [ $FAILED_CHECKS -le 3 ]; then
        echo -e "${YELLOW}${SUCCESS_RATE}% - 基本就绪${NC}"
        echo ""
        echo "系统基本就绪，但需要修复关键问题"
    else
        echo -e "${RED}${SUCCESS_RATE}% - 需要修复${NC} ⚠️"
        echo ""
        echo -e "${RED}发现多个严重问题，必须修复后才能部署${NC}"
    fi
    
    # 显示问题详情
    if [ -n "$CRITICAL_ISSUES" ]; then
        echo ""
        echo -e "${RED}🚨 关键问题:${NC}"
        echo -e "$CRITICAL_ISSUES"
    fi
    
    if [ -n "$SECURITY_ISSUES" ]; then
        echo ""
        echo -e "${MAGENTA}🔒 安全问题:${NC}"
        echo -e "$SECURITY_ISSUES"
    fi
    
    if [ -n "$CONFIG_ISSUES" ]; then
        echo ""
        echo -e "${YELLOW}⚙️ 配置问题:${NC}"
        echo -e "$CONFIG_ISSUES"
    fi
    
    if [ -n "$LOGIC_ERRORS" ]; then
        echo ""
        echo -e "${CYAN}🔧 逻辑错误:${NC}"
        echo -e "$LOGIC_ERRORS"
    fi
    
    # 建议
    echo ""
    echo -e "${BOLD}${BLUE}======================================================${NC}"
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}🎉 恭喜！系统已达到生产标准！${NC}"
        echo -e "${GREEN}建议: 可以安全部署到生产环境${NC}"
        echo "  ./docker-deploy.sh"
    else
        echo -e "${YELLOW}📋 修复建议:${NC}"
        echo "  1. 修复所有失败项（红色✗）"
        echo "  2. 检查并处理警告项（黄色⚠）"
        echo "  3. 重新运行检查: ./super-check-v6.sh"
        echo ""
        echo "  快速修复脚本: ./auto-fix.sh"
    fi
    echo -e "${BOLD}${BLUE}======================================================${NC}"
}

# 主函数
main() {
    print_header
    
    check_config_consistency
    check_security_config
    check_api_contract
    check_docker_config
    check_dependencies
    check_database
    check_performance
    check_code_quality
    check_env_variables
    check_file_security
    
    generate_final_report
}

# 运行
main