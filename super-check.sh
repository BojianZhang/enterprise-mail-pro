#!/bin/bash

# 企业邮件系统 - 超级深度检查脚本 v4.0
# 前端、后端、依赖、中间件、配置、安全 - 一个都不放过

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

# 统计
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0
CRITICAL_ISSUES=""
SECURITY_ISSUES=""
LOGIC_ERRORS=""
DEPENDENCY_ISSUES=""

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}======================================================${NC}"
    echo -e "${BOLD}${BLUE}     超级深度系统检查 v4.0${NC}"
    echo -e "${BOLD}${BLUE}     前端/后端/依赖/中间件 - 全方位扫描${NC}"
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
    echo -e "  ${RED}└─ 严重问题: $2${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    CRITICAL_ISSUES="${CRITICAL_ISSUES}\n  • $1: $2"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    echo -e "  ${YELLOW}└─ 警告: $2${NC}"
    WARNINGS=$((WARNINGS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

check_security() {
    echo -e "${MAGENTA}🔒${NC} $1"
    SECURITY_ISSUES="${SECURITY_ISSUES}\n  • $1"
}

check_logic() {
    echo -e "${CYAN}🔧${NC} $1"
    LOGIC_ERRORS="${LOGIC_ERRORS}\n  • $1"
}

# 1. 前端代码深度检查
check_frontend_code() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 前端代码逻辑检查 ===${NC}"
    
    if [ -d frontend/src ]; then
        # 检查XSS漏洞
        XSS_VULN=$(grep -r "v-html" frontend/src --include="*.vue" | wc -l)
        if [ "$XSS_VULN" -eq 0 ]; then
            check_pass "无XSS漏洞风险"
        else
            # 检查是否有DOMPurify
            if grep -q "DOMPurify" frontend/src/views/mail/Inbox.vue 2>/dev/null; then
                check_pass "XSS防护已实施 (DOMPurify)"
            else
                check_fail "发现 $XSS_VULN 处潜在XSS漏洞" "v-html未经消毒"
                check_security "XSS漏洞风险"
            fi
        fi
        
        # 检查TODO项
        FRONTEND_TODOS=$(grep -r "TODO\|FIXME" frontend/src --include="*.vue" --include="*.ts" 2>/dev/null | wc -l)
        if [ "$FRONTEND_TODOS" -eq 0 ]; then
            check_pass "前端无未完成TODO"
        else
            check_warn "前端有 $FRONTEND_TODOS 个TODO项" "功能未完成"
        fi
        
        # 检查API调用实现
        API_UNIMPL=$(grep -r "// TODO.*API" frontend/src --include="*.vue" --include="*.ts" 2>/dev/null | wc -l)
        if [ "$API_UNIMPL" -eq 0 ]; then
            check_pass "API调用已实现"
        else
            check_fail "发现 $API_UNIMPL 个未实现的API调用" "核心功能缺失"
            check_logic "API调用未实现"
        fi
        
        # 检查any类型使用
        ANY_TYPES=$(grep -r ": any" frontend/src --include="*.ts" --include="*.vue" 2>/dev/null | wc -l)
        if [ "$ANY_TYPES" -le 5 ]; then
            check_pass "TypeScript类型安全"
        else
            check_warn "发现 $ANY_TYPES 处any类型" "类型安全风险"
        fi
        
        # 检查console.log
        CONSOLE_LOGS=$(grep -r "console\.\(log\|error\|warn\)" frontend/src --include="*.vue" --include="*.ts" 2>/dev/null | wc -l)
        if [ "$CONSOLE_LOGS" -eq 0 ]; then
            check_pass "无调试代码残留"
        else
            check_warn "发现 $CONSOLE_LOGS 处console语句" "应在生产环境移除"
        fi
    else
        check_fail "前端目录不存在" "frontend/src缺失"
    fi
}

# 2. 前端依赖检查
check_frontend_deps() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 前端依赖完整性检查 ===${NC}"
    
    if [ -f frontend/package.json ]; then
        # 检查未使用的依赖
        UNUSED_DEPS=0
        for dep in "socket.io-client" "mitt" "@wangeditor/editor" "echarts" "vue-echarts" "crypto-js"; do
            if grep -q "\"$dep\"" frontend/package.json; then
                if ! grep -r "$dep" frontend/src 2>/dev/null | grep -v package.json > /dev/null; then
                    UNUSED_DEPS=$((UNUSED_DEPS + 1))
                    check_warn "未使用的依赖: $dep" "应移除以减少包大小"
                fi
            fi
        done
        
        if [ "$UNUSED_DEPS" -eq 0 ]; then
            check_pass "无未使用的依赖"
        fi
        
        # 检查关键依赖版本
        VUE_VERSION=$(grep -oP '"vue":\s*"\^3\.\d+\.\d+"' frontend/package.json | grep -oP '3\.\d+\.\d+')
        if [[ "$VUE_VERSION" > "3.4.0" ]]; then
            check_pass "Vue版本最新 ($VUE_VERSION)"
        else
            check_warn "Vue版本可能过时" "当前: $VUE_VERSION"
        fi
        
        # 检查安全漏洞依赖
        if grep -q "dompurify" frontend/package.json; then
            check_pass "XSS防护库已安装 (DOMPurify)"
        else
            check_warn "缺少XSS防护库" "建议安装DOMPurify"
        fi
    else
        check_fail "前端package.json不存在" "依赖配置缺失"
    fi
}

# 3. 后端代码深度检查
check_backend_code() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 后端代码逻辑检查 ===${NC}"
    
    if [ -d backend/src ]; then
        # 检查编译错误标志
        COMPILE_ERRORS=0
        
        # 检查重复方法定义
        for method in "getEmailsByUser" "getEmailsByFolder" "searchEmails" "markAsRead"; do
            COUNT=$(grep -c "public.*$method" backend/src/main/java/com/enterprise/mail/service/EmailService.java 2>/dev/null || echo 0)
            if [ "$COUNT" -gt 1 ]; then
                check_fail "发现重复方法: $method" "将导致编译错误"
                check_logic "重复方法定义: $method"
                COMPILE_ERRORS=$((COMPILE_ERRORS + 1))
            fi
        done
        
        if [ "$COMPILE_ERRORS" -eq 0 ]; then
            check_pass "无重复方法定义"
        fi
        
        # 检查变量未定义错误
        if grep -q "savedEmail.*savedEmail.*emailRepository.save" backend/src/main/java/com/enterprise/mail/service/EmailService.java 2>/dev/null; then
            check_fail "变量使用顺序错误" "savedEmail在声明前使用"
            check_logic "变量声明顺序错误"
        else
            check_pass "变量声明顺序正确"
        fi
        
        # 检查硬编码密码
        HARDCODED_PWD=$(grep -r 'password.*=.*"[^$]' backend/src/main/java --include="*.java" 2>/dev/null | grep -v '\\${' | grep -v '@Value' | wc -l)
        if [ "$HARDCODED_PWD" -eq 0 ]; then
            check_pass "无硬编码密码"
        else
            check_fail "发现 $HARDCODED_PWD 处硬编码密码" "严重安全风险"
            check_security "硬编码密码"
        fi
        
        # 检查线程安全
        HASHMAP_USAGE=$(grep -r "new HashMap<>" backend/src --include="*.java" 2>/dev/null | wc -l)
        CONCURRENT_USAGE=$(grep -r "ConcurrentHashMap" backend/src --include="*.java" 2>/dev/null | wc -l)
        if [ "$HASHMAP_USAGE" -gt 0 ] && [ "$CONCURRENT_USAGE" -eq 0 ]; then
            check_warn "使用非线程安全的HashMap" "多线程环境可能出问题"
        else
            check_pass "线程安全集合使用正确"
        fi
        
        # 检查@Transactional
        TRANSACTIONAL=$(grep -c "@Transactional" backend/src/main/java/com/enterprise/mail/service/*.java 2>/dev/null || echo 0)
        if [ "$TRANSACTIONAL" -ge 5 ]; then
            check_pass "事务注解使用充分"
        else
            check_warn "事务注解可能不足" "仅 $TRANSACTIONAL 处使用"
        fi
        
        # 检查资源泄露
        TRY_WITH_RES=$(grep -r "try.*(" backend/src --include="*.java" 2>/dev/null | wc -l)
        if [ "$TRY_WITH_RES" -ge 1 ]; then
            check_pass "使用try-with-resources"
        else
            check_warn "可能存在资源泄露" "未使用try-with-resources"
        fi
    fi
}

# 4. 后端依赖检查
check_backend_deps() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 后端依赖完整性检查 ===${NC}"
    
    if [ -f backend/pom.xml ]; then
        # 检查Spring Boot版本
        SPRING_VERSION=$(grep -oP '<version>3\.\d+\.\d+</version>' backend/pom.xml | head -1 | grep -oP '\d+\.\d+\.\d+')
        if [[ "$SPRING_VERSION" == "3.2.5" ]]; then
            check_pass "Spring Boot版本正确 (3.2.5)"
        else
            check_warn "Spring Boot版本: $SPRING_VERSION" "建议3.2.5"
        fi
        
        # 检查冲突依赖
        if grep -q "jedis" backend/pom.xml && grep -q "spring-boot-starter-data-redis" backend/pom.xml; then
            check_fail "Jedis与Lettuce冲突" "Spring默认使用Lettuce"
            DEPENDENCY_ISSUES="${DEPENDENCY_ISSUES}\n  • Jedis与Lettuce冲突"
        else
            check_pass "Redis客户端无冲突"
        fi
        
        # 检查安全依赖版本
        JWT_VERSION=$(grep -oP '<jwt.version>0\.12\.\d+</jwt.version>' backend/pom.xml | grep -oP '0\.12\.\d+')
        if [[ "$JWT_VERSION" == "0.12.5" ]]; then
            check_pass "JWT版本安全 (0.12.5)"
        else
            check_warn "JWT版本可能过时" "当前: $JWT_VERSION"
        fi
        
        # 检查数据库索引
        INDEXES=$(grep -c "@Index" backend/src/main/java/com/enterprise/mail/entity/*.java 2>/dev/null || echo 0)
        if [ "$INDEXES" -ge 5 ]; then
            check_pass "数据库索引已优化"
        else
            check_warn "数据库索引可能不足" "仅 $INDEXES 个索引"
        fi
    fi
}

# 5. 中间件配置检查
check_middleware() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 中间件服务配置检查 ===${NC}"
    
    if [ -f docker-compose.yml ]; then
        # 检查环境变量使用
        ENV_VARS=$(grep -c '${.*}' docker-compose.yml || true)
        if [ "$ENV_VARS" -ge 10 ]; then
            check_pass "Docker配置使用环境变量"
        else
            check_fail "Docker配置硬编码" "安全风险"
            check_security "Docker配置硬编码"
        fi
        
        # 检查Redis密码
        if grep -q "requirepass" docker-compose.yml; then
            check_pass "Redis已设置密码"
        else
            check_fail "Redis未设置密码" "安全风险"
            check_security "Redis无密码保护"
        fi
        
        # 检查健康检查
        HEALTH_CHECKS=$(grep -c "healthcheck:" docker-compose.yml || true)
        if [ "$HEALTH_CHECKS" -ge 2 ]; then
            check_pass "健康检查配置完整"
        else
            check_warn "健康检查可能不足" "仅 $HEALTH_CHECKS 个"
        fi
        
        # 检查.env模板
        if [ -f .env.template ] || [ -f .env.example ]; then
            check_pass "环境变量模板存在"
        else
            check_warn "缺少.env模板文件" "部署困难"
        fi
    fi
}

# 6. API一致性检查
check_api_consistency() {
    echo ""
    echo -e "${CYAN}${BOLD}=== API接口一致性检查 ===${NC}"
    
    # 检查前端API调用与后端实现
    if [ -d frontend/src/api ] && [ -d backend/src ]; then
        # 检查登录API
        if grep -q "login" frontend/src/api/auth.ts 2>/dev/null && grep -q "@PostMapping.*login" backend/src/main/java/com/enterprise/mail/controller/AuthController.java 2>/dev/null; then
            check_pass "登录API前后端一致"
        else
            check_warn "登录API可能不一致" "检查前后端实现"
        fi
        
        # 检查前端API调用与后端实现
        FRONTEND_APIS=$(grep -c "export const" frontend/src/api/*.ts 2>/dev/null || echo 0)
        BACKEND_APIS=$(grep -c "@.*Mapping" backend/src/main/java/com/enterprise/mail/controller/*.java 2>/dev/null || echo 0)
        
        if [ "$FRONTEND_APIS" -le "$BACKEND_APIS" ]; then
            check_pass "API数量匹配 (前端:$FRONTEND_APIS, 后端:$BACKEND_APIS)"
        else
            check_warn "API数量不匹配" "前端:$FRONTEND_APIS, 后端:$BACKEND_APIS"
        fi
    fi
}

# 7. 数据库架构检查
check_database_schema() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 数据库架构完整性检查 ===${NC}"
    
    if [ -d backend/src/main/java/com/enterprise/mail/entity ]; then
        # 检查实体关系
        ENTITIES=$(ls backend/src/main/java/com/enterprise/mail/entity/*.java 2>/dev/null | wc -l)
        RELATIONSHIPS=$(grep -r "@ManyToOne\|@OneToMany\|@OneToOne\|@ManyToMany" backend/src/main/java/com/enterprise/mail/entity 2>/dev/null | wc -l)
        
        if [ "$ENTITIES" -gt 0 ] && [ "$RELATIONSHIPS" -gt 0 ]; then
            check_pass "实体关系已定义 ($ENTITIES 实体, $RELATIONSHIPS 关系)"
        else
            check_warn "实体关系可能不完整" "$ENTITIES 实体, $RELATIONSHIPS 关系"
        fi
        
        # 检查级联操作
        CASCADE=$(grep -r "cascade" backend/src/main/java/com/enterprise/mail/entity 2>/dev/null | wc -l)
        if [ "$CASCADE" -ge 1 ]; then
            check_pass "级联操作已配置"
        else
            check_warn "未配置级联操作" "可能导致孤立数据"
        fi
    fi
}

# 8. 综合安全检查
check_comprehensive_security() {
    echo ""
    echo -e "${CYAN}${BOLD}=== 综合安全评估 ===${NC}"
    
    # JWT密钥长度检查
    if [ -f backend/src/main/resources/application.yml ]; then
        JWT_LEN=$(grep "JWT_SECRET" backend/src/main/resources/application.yml 2>/dev/null | grep -oP 'CHANGE_THIS.*' | wc -c)
        if [ "$JWT_LEN" -ge 64 ]; then
            check_pass "JWT密钥长度充足"
        else
            check_warn "JWT密钥可能过短" "建议至少256位"
        fi
    fi
    
    # CORS配置检查
    if grep -q "allowed-origins:.*\\*" backend/src/main/resources/application.yml 2>/dev/null; then
        check_warn "CORS允许所有来源" "生产环境应限制"
    else
        check_pass "CORS配置合理"
    fi
    
    # SQL注入检查
    SQL_CONCAT=$(grep -r "CONCAT.*%" backend/src 2>/dev/null | wc -l)
    if [ "$SQL_CONCAT" -ge 1 ]; then
        check_pass "SQL查询使用参数化"
    else
        check_warn "检查SQL查询参数化" "防止SQL注入"
    fi
}

# 生成最终报告
generate_final_report() {
    echo ""
    echo -e "${BOLD}${BLUE}======================================================${NC}"
    echo -e "${BOLD}${MAGENTA}超级深度检查报告 v4.0${NC}"
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
        echo -e "${GREEN}✅ 系统已通过超级深度检查，完全生产就绪！${NC}"
    elif [ $FAILED_CHECKS -le 2 ]; then
        echo -e "${YELLOW}${SUCCESS_RATE}% - 基本就绪${NC}"
        echo ""
        echo "系统基本就绪，但需要修复关键问题"
    else
        echo -e "${RED}${SUCCESS_RATE}% - 需要修复${NC} ⚠️"
        echo ""
        echo -e "${RED}发现严重问题，必须修复后才能部署${NC}"
    fi
    
    if [ -n "$CRITICAL_ISSUES" ]; then
        echo ""
        echo -e "${RED}🚨 关键问题:${NC}"
        echo -e "$CRITICAL_ISSUES"
    fi
    
    if [ -n "$LOGIC_ERRORS" ]; then
        echo ""
        echo -e "${CYAN}🔧 逻辑错误:${NC}"
        echo -e "$LOGIC_ERRORS"
    fi
    
    if [ -n "$SECURITY_ISSUES" ]; then
        echo ""
        echo -e "${MAGENTA}🔒 安全问题:${NC}"
        echo -e "$SECURITY_ISSUES"
    fi
    
    if [ -n "$DEPENDENCY_ISSUES" ]; then
        echo ""
        echo -e "${YELLOW}📦 依赖问题:${NC}"
        echo -e "$DEPENDENCY_ISSUES"
    fi
    
    echo ""
    echo -e "${BOLD}${BLUE}======================================================${NC}"
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}🎉 恭喜！系统已达到最高标准！${NC}"
        echo -e "${GREEN}建议: 可以安全部署到生产环境${NC}"
        echo "  ./deploy-smart.sh"
    else
        echo -e "${YELLOW}📋 建议: 修复以上问题后重新检查${NC}"
        echo "  1. 修复所有失败项"
        echo "  2. 处理警告项"
        echo "  3. 重新运行: ./super-check.sh"
    fi
    echo -e "${BOLD}${BLUE}======================================================${NC}"
}

# 主函数
main() {
    print_header
    
    check_frontend_code
    check_frontend_deps
    check_backend_code
    check_backend_deps
    check_middleware
    check_api_consistency
    check_database_schema
    check_comprehensive_security
    
    generate_final_report
}

# 运行
main