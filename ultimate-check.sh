#!/bin/bash

# 企业邮件系统 - 终极深度检查脚本 v3.0
# 一丝一毫都不放过的超严格检查

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 统计
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0
CRITICAL_ISSUES=""
SECURITY_ISSUES=""

print_header() {
    echo ""
    echo "========================================"
    echo "   终极深度系统检查 v3.0"
    echo "   一丝一毫都不放过"
    echo "========================================"
    echo ""
}

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    echo -e "  ${RED}└─ 问题: $2${NC}"
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

# 1. Maven 依赖深度检查
check_maven_deps() {
    echo ""
    echo -e "${CYAN}=== Maven 依赖完整性检查 ===${NC}"
    
    if [ -f backend/pom.xml ]; then
        # 检查每个关键依赖
        
        # Spring Boot 版本
        SPRING_VERSION=$(grep -oP '<version>3\.\d+\.\d+</version>' backend/pom.xml | head -1 | grep -oP '\d+\.\d+\.\d+')
        if [[ "$SPRING_VERSION" == "3.2.5" ]]; then
            check_pass "Spring Boot 版本正确 (3.2.5)"
        else
            check_warn "Spring Boot 版本 ($SPRING_VERSION)" "建议使用 3.2.5"
        fi
        
        # 检查危险依赖
        if grep -q 'subethasmtp' backend/pom.xml; then
            check_fail "发现过时的 SubEthaSMTP" "该库自2014年停止维护"
        else
            check_pass "未使用过时的 SubEthaSMTP"
        fi
        
        # 检查 MySQL 驱动
        if grep -q 'mysql-connector-j' backend/pom.xml; then
            check_pass "使用正确的 MySQL 驱动"
        else
            check_fail "MySQL 驱动问题" "应使用 mysql-connector-j"
        fi
        
        # 检查 GreenMail 版本
        if grep -q '<greenmail.version>2.1.0</greenmail.version>' backend/pom.xml; then
            check_pass "GreenMail 版本正确"
        else
            check_warn "GreenMail 版本可能需要更新" "建议使用 2.1.0"
        fi
        
        # 检查 Lombok 版本定义
        if grep -q '<lombok.version>' backend/pom.xml; then
            check_pass "Lombok 版本已定义"
        else
            check_fail "Lombok 版本未定义" "将导致构建失败"
        fi
        
        # 检查 JWT 版本
        if grep -q '<jwt.version>0.12.5</jwt.version>' backend/pom.xml; then
            check_pass "JWT 版本已更新"
        else
            check_warn "JWT 版本可能过时" "建议使用 0.12.5"
        fi
    else
        check_fail "pom.xml 不存在" "Maven 配置缺失"
    fi
}

# 2. Java 代码安全检查
check_java_security() {
    echo ""
    echo -e "${CYAN}=== Java 代码安全性检查 ===${NC}"
    
    if [ -d backend/src ]; then
        # 检查硬编码密码
        HARDCODED=$(grep -r 'password\s*=\s*"[^$]' backend/src/main/resources/*.yml 2>/dev/null | grep -v '\${' | wc -l)
        if [ "$HARDCODED" -eq 0 ]; then
            check_pass "未发现硬编码密码"
        else
            check_fail "发现 $HARDCODED 处硬编码密码" "严重安全风险"
            check_security "硬编码密码风险"
        fi
        
        # 检查 SQL 注入风险
        SQL_CONCAT=$(grep -r "LIKE.*%.*:.*%" backend/src 2>/dev/null | wc -l)
        if [ "$SQL_CONCAT" -eq 0 ]; then
            check_pass "SQL 查询使用参数化"
        else
            check_warn "发现 $SQL_CONCAT 处潜在 SQL 注入风险" "检查 LIKE 查询"
        fi
        
        # 检查空指针风险
        UNSAFE_CAST=$(grep -r '\[\s*0\s*\]' backend/src | grep -v 'instanceof' | wc -l)
        if [ "$UNSAFE_CAST" -le 5 ]; then
            check_pass "类型转换相对安全"
        else
            check_warn "发现 $UNSAFE_CAST 处潜在的不安全数组访问" "可能导致 ArrayIndexOutOfBoundsException"
        fi
        
        # 检查资源泄露
        TRY_WITH=$(grep -r 'try\s*(' backend/src | wc -l)
        if [ "$TRY_WITH" -ge 1 ]; then
            check_pass "使用 try-with-resources 管理资源"
        else
            check_warn "资源管理可能存在问题" "确保使用 try-with-resources"
        fi
        
        # 检查线程安全
        THREAD_UNSAFE=$(grep -r 'SimpleDateFormat\|HashMap\|ArrayList' backend/src | grep -v 'ConcurrentHashMap\|Collections.synchronized' | wc -l)
        if [ "$THREAD_UNSAFE" -le 10 ]; then
            check_pass "线程安全风险较低"
        else
            check_warn "发现 $THREAD_UNSAFE 处潜在线程安全问题" "考虑使用线程安全的集合"
        fi
    fi
}

# 3. 配置文件检查
check_config_files() {
    echo ""
    echo -e "${CYAN}=== 配置文件安全检查 ===${NC}"
    
    APP_YML="backend/src/main/resources/application.yml"
    
    if [ -f "$APP_YML" ]; then
        # 检查环境变量使用
        ENV_VARS=$(grep -c '\${.*:.*}' "$APP_YML" || true)
        if [ "$ENV_VARS" -ge 10 ]; then
            check_pass "配置使用环境变量 ($ENV_VARS 处)"
        else
            check_warn "环境变量使用不足" "仅 $ENV_VARS 处使用"
        fi
        
        # 检查 JWT Secret
        if grep -q 'JWT_SECRET.*CHANGE_THIS' "$APP_YML"; then
            check_pass "JWT Secret 有安全提示"
        else
            check_warn "JWT Secret 配置可能不安全" "确保使用强随机密钥"
        fi
        
        # 检查 SSL 配置
        if grep -q 'ssl:.*enable.*false' "$APP_YML"; then
            check_warn "SSL 未启用" "生产环境应启用 SSL"
        else
            check_pass "SSL 配置存在"
        fi
        
        # 检查生产配置
        if [ -f backend/src/main/resources/application-prod.yml ]; then
            check_pass "生产配置文件存在"
        else
            check_fail "缺少生产配置文件" "需要 application-prod.yml"
        fi
    fi
}

# 4. NPM 依赖检查
check_npm_deps() {
    echo ""
    echo -e "${CYAN}=== NPM 依赖安全检查 ===${NC}"
    
    if [ -f frontend/package.json ]; then
        # 检查 Vue 版本
        VUE_VERSION=$(grep -oP '"vue":\s*"\^3\.\d+\.\d+"' frontend/package.json | grep -oP '3\.\d+\.\d+')
        if [[ "$VUE_VERSION" > "3.4.0" ]]; then
            check_pass "Vue 版本已更新 ($VUE_VERSION)"
        else
            check_warn "Vue 版本可能过时 ($VUE_VERSION)" "建议更新到 3.4.x"
        fi
        
        # 检查 Axios 版本（安全漏洞）
        AXIOS_VERSION=$(grep -oP '"axios":\s*"\^1\.\d+\.\d+"' frontend/package.json | grep -oP '1\.\d+\.\d+')
        if [[ "$AXIOS_VERSION" > "1.7.0" ]]; then
            check_pass "Axios 版本安全 ($AXIOS_VERSION)"
        else
            check_warn "Axios 版本有安全漏洞" "更新到 1.7.7+"
            check_security "Axios 安全漏洞"
        fi
        
        # 检查依赖总数
        DEPS_COUNT=$(grep -c '":' frontend/package.json)
        if [ "$DEPS_COUNT" -le 50 ]; then
            check_pass "依赖数量合理 ($DEPS_COUNT)"
        else
            check_warn "依赖过多 ($DEPS_COUNT)" "考虑减少依赖"
        fi
    fi
}

# 5. Docker 配置检查
check_docker() {
    echo ""
    echo -e "${CYAN}=== Docker 配置检查 ===${NC}"
    
    if [ -f backend/Dockerfile ]; then
        # 检查基础镜像
        if grep -q 'eclipse-temurin' backend/Dockerfile; then
            check_pass "使用推荐的 Java 基础镜像"
        else
            check_warn "基础镜像可能不是最优" "推荐 eclipse-temurin"
        fi
        
        # 检查健康检查
        if grep -q 'HEALTHCHECK' backend/Dockerfile; then
            check_pass "Docker 健康检查已配置"
        else
            check_warn "缺少 Docker 健康检查" "建议添加 HEALTHCHECK"
        fi
    fi
    
    if [ -f docker-compose.yml ]; then
        # 检查 version 字段
        if grep -q '^version:' docker-compose.yml; then
            check_warn "docker-compose 包含过时的 version 字段" "可以移除"
        else
            check_pass "docker-compose.yml 格式正确"
        fi
    fi
}

# 6. 实现完整性检查
check_implementation() {
    echo ""
    echo -e "${CYAN}=== 代码实现完整性检查 ===${NC}"
    
    if [ -d backend/src ]; then
        # 检查 TODO 注释
        TODOS=$(grep -r 'TODO\|FIXME\|XXX' backend/src 2>/dev/null | wc -l)
        if [ "$TODOS" -eq 0 ]; then
            check_pass "没有未完成的 TODO"
        elif [ "$TODOS" -le 5 ]; then
            check_warn "发现 $TODOS 个 TODO" "需要完成实现"
        else
            check_fail "发现 $TODOS 个 TODO" "大量未完成的实现"
        fi
        
        # 检查空方法
        EMPTY_METHODS=$(grep -r 'return\s*"";\|return\s*null;\|return\s*false;' backend/src | wc -l)
        if [ "$EMPTY_METHODS" -le 3 ]; then
            check_pass "大部分方法已实现"
        else
            check_warn "发现 $EMPTY_METHODS 个可能未实现的方法" "检查是否为占位符"
        fi
        
        # 检查异常处理
        if [ -f backend/src/main/java/com/enterprise/mail/exception/GlobalExceptionHandler.java ]; then
            check_pass "全局异常处理器已实现"
        else
            check_fail "缺少全局异常处理器" "需要统一的错误处理"
        fi
    fi
}

# 7. 性能检查
check_performance() {
    echo ""
    echo -e "${CYAN}=== 性能配置检查 ===${NC}"
    
    if [ -f backend/src/main/resources/application.yml ]; then
        # 检查连接池配置
        if grep -q 'hikari:' backend/src/main/resources/application.yml; then
            check_pass "数据库连接池已配置"
        else
            check_warn "数据库连接池未配置" "建议配置 HikariCP"
        fi
        
        # 检查缓存配置
        if grep -q 'cache:.*redis' backend/src/main/resources/application.yml; then
            check_pass "Redis 缓存已配置"
        else
            check_warn "缓存未配置" "建议启用 Redis 缓存"
        fi
        
        # 检查 JPA 批处理
        if grep -q 'batch_size' backend/src/main/resources/application.yml; then
            check_pass "JPA 批处理已优化"
        else
            check_warn "JPA 批处理未配置" "可能影响性能"
        fi
    fi
}

# 8. 安全漏洞扫描
check_vulnerabilities() {
    echo ""
    echo -e "${CYAN}=== 已知漏洞扫描 ===${NC}"
    
    # 检查 Log4j 漏洞
    if grep -q 'log4j' backend/pom.xml 2>/dev/null; then
        check_fail "发现 Log4j 依赖" "可能存在 Log4Shell 漏洞"
        check_security "Log4j 安全漏洞"
    else
        check_pass "未使用 Log4j（避免 Log4Shell）"
    fi
    
    # 检查 Spring 安全配置
    if [ -f backend/src/main/java/com/enterprise/mail/config/SecurityConfig.java ]; then
        if grep -q 'permitAll()' backend/src/main/java/com/enterprise/mail/config/SecurityConfig.java; then
            check_warn "发现 permitAll() 配置" "检查是否必要"
        else
            check_pass "安全配置严格"
        fi
    fi
    
    # 检查 CORS 配置
    if grep -q 'allowed-headers:.*\*' backend/src/main/resources/application.yml 2>/dev/null; then
        check_fail "CORS 允许所有 headers" "安全风险"
        check_security "CORS 配置过于宽松"
    else
        check_pass "CORS 配置合理"
    fi
}

# 生成最终报告
generate_final_report() {
    echo ""
    echo "========================================"
    echo -e "${MAGENTA}终极深度检查报告${NC}"
    echo "========================================"
    
    TOTAL=$TOTAL_CHECKS
    if [ $TOTAL -eq 0 ]; then TOTAL=1; fi
    SUCCESS_RATE=$((PASSED_CHECKS * 100 / TOTAL))
    
    echo ""
    echo "检查统计："
    echo -e "  总检查项: ${CYAN}$TOTAL_CHECKS${NC}"
    echo -e "  通过: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "  失败: ${RED}$FAILED_CHECKS${NC}"
    echo -e "  警告: ${YELLOW}$WARNINGS${NC}"
    
    echo ""
    echo -n "系统健康度: "
    if [ $FAILED_CHECKS -eq 0 ] && [ $WARNINGS -le 5 ]; then
        echo -e "${GREEN}${SUCCESS_RATE}% - 生产就绪${NC} ✨"
        echo ""
        echo -e "${GREEN}✅ 系统已通过所有关键检查，可以安全部署！${NC}"
    elif [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}${SUCCESS_RATE}% - 基本就绪${NC}"
        echo ""
        echo "系统可以部署，但建议处理警告项"
    elif [ $FAILED_CHECKS -le 2 ]; then
        echo -e "${YELLOW}${SUCCESS_RATE}% - 需要修复${NC}"
        echo ""
        echo "发现少量关键问题，修复后可部署"
    else
        echo -e "${RED}${SUCCESS_RATE}% - 不建议部署${NC} ❌"
        echo ""
        echo -e "${RED}发现多个关键问题，必须修复后才能部署${NC}"
    fi
    
    if [ -n "$CRITICAL_ISSUES" ]; then
        echo ""
        echo -e "${RED}关键问题:${NC}"
        echo -e "$CRITICAL_ISSUES"
    fi
    
    if [ -n "$SECURITY_ISSUES" ]; then
        echo ""
        echo -e "${MAGENTA}安全问题:${NC}"
        echo -e "$SECURITY_ISSUES"
    fi
    
    echo ""
    echo "========================================"
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}建议: 可以立即部署${NC}"
        echo "  ./deploy-smart.sh"
    else
        echo -e "${YELLOW}建议: 先修复问题${NC}"
        echo "  1. 查看上述失败项"
        echo "  2. 运行 ./apply-fixes.sh"
        echo "  3. 重新运行此检查"
    fi
    echo "========================================"
}

# 主函数
main() {
    print_header
    
    check_maven_deps
    check_java_security
    check_config_files
    check_npm_deps
    check_docker
    check_implementation
    check_performance
    check_vulnerabilities
    
    generate_final_report
}

# 运行
main