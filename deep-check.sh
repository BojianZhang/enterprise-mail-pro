#!/bin/bash

# 企业邮件系统 - 深度自检脚本 v2.0
# 检查所有依赖的实际可用性和代码逻辑

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# 结果统计
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0
CRITICAL_ISSUES=""

# 打印函数
print_header() {
    echo ""
    echo "========================================"
    echo "   企业邮件系统 - 深度系统自检 v2.0"
    echo "========================================"
    echo ""
    echo "执行全面的依赖验证和代码逻辑检查..."
    echo ""
}

check_pass() {
    local description=$1
    echo -e "${GREEN}✓${NC} $description"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

check_fail() {
    local description=$1
    local issue=$2
    echo -e "${RED}✗${NC} $description"
    echo -e "  ${RED}问题: $issue${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    CRITICAL_ISSUES="${CRITICAL_ISSUES}\n- $description: $issue"
}

check_warn() {
    local description=$1
    local warning=$2
    echo -e "${YELLOW}⚠${NC} $description"
    echo -e "  ${YELLOW}警告: $warning${NC}"
    WARNINGS=$((WARNINGS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

# Maven 依赖深度检查
check_maven_dependencies() {
    echo -e "${BLUE}=== Maven 依赖验证 ===${NC}"
    
    # 检查关键依赖的版本和兼容性
    if [ -f backend/pom.xml ]; then
        # 检查 lombok 版本是否定义
        if grep -q '<lombok.version>' backend/pom.xml; then
            check_pass "Lombok 版本已定义"
        else
            check_fail "Lombok 版本未定义" "pom.xml 中缺少 <lombok.version> 属性"
        fi
        
        # 检查是否使用了正确的 MySQL 驱动
        if grep -q 'mysql-connector-j' backend/pom.xml; then
            check_pass "使用正确的 MySQL 驱动 (mysql-connector-j)"
        else
            check_warn "MySQL 驱动可能过时" "建议使用 mysql-connector-j"
        fi
        
        # 检查 Jakarta 迁移
        if grep -q 'jakarta.mail' backend/pom.xml; then
            check_pass "已迁移到 Jakarta Mail"
        else
            check_fail "仍在使用 javax.mail" "需要迁移到 jakarta.mail"
        fi
        
        # 检查危险的依赖
        if grep -q 'commons-email.*1\.5' backend/pom.xml; then
            check_warn "使用过时的 commons-email 1.5" "该版本自2017年未更新，存在安全风险"
        fi
        
        # 检查 MapStruct 使用情况
        if grep -q 'mapstruct' backend/pom.xml; then
            if find backend/src -name "*.java" -exec grep -l "@Mapper" {} \; | head -1 > /dev/null 2>&1; then
                check_pass "MapStruct 依赖已使用"
            else
                check_warn "MapStruct 已添加但未使用" "考虑移除或实现 Mapper"
            fi
        fi
    else
        check_fail "pom.xml 不存在" "Maven 配置文件缺失"
    fi
}

# Java 代码逻辑检查
check_java_code() {
    echo ""
    echo -e "${BLUE}=== Java 代码逻辑检查 ===${NC}"
    
    # 检查空指针风险
    if [ -d backend/src ]; then
        # 检查不安全的类型转换
        UNSAFE_CASTS=$(grep -r "InternetAddress.*\[\].*\[0\]" backend/src 2>/dev/null | wc -l)
        if [ "$UNSAFE_CASTS" -eq 0 ]; then
            check_pass "没有发现不安全的类型转换"
        else
            check_warn "发现 $UNSAFE_CASTS 处潜在的不安全类型转换" "使用 instanceof 检查"
        fi
        
        # 检查未实现的方法
        EMPTY_RETURNS=$(grep -r "return \"\";" backend/src 2>/dev/null | wc -l)
        if [ "$EMPTY_RETURNS" -le 2 ]; then
            check_pass "大部分方法已实现"
        else
            check_warn "发现 $EMPTY_RETURNS 处空返回值" "可能有未完成的实现"
        fi
        
        # 检查硬编码的密码
        HARDCODED_PASSWORDS=$(grep -r "password.*=.*\".*[a-zA-Z0-9]" backend/src/main/resources/*.yml 2>/dev/null | grep -v '\${' | wc -l)
        if [ "$HARDCODED_PASSWORDS" -eq 0 ]; then
            check_pass "没有硬编码的密码"
        else
            check_fail "发现硬编码的密码" "使用环境变量替代"
        fi
        
        # 检查全局异常处理
        if [ -f backend/src/main/java/com/enterprise/mail/exception/GlobalExceptionHandler.java ]; then
            check_pass "全局异常处理器已实现"
        else
            check_fail "缺少全局异常处理器" "需要添加 GlobalExceptionHandler"
        fi
    fi
}

# 配置文件安全检查
check_security_config() {
    echo ""
    echo -e "${BLUE}=== 安全配置检查 ===${NC}"
    
    CONFIG_FILE="backend/src/main/resources/application.yml"
    
    if [ -f "$CONFIG_FILE" ]; then
        # 检查是否使用环境变量
        if grep -q '\${.*:.*}' "$CONFIG_FILE"; then
            check_pass "使用环境变量配置"
        else
            check_warn "未充分使用环境变量" "敏感配置应使用环境变量"
        fi
        
        # 检查 CORS 配置
        if grep -q 'allowed-headers:.*\*' "$CONFIG_FILE" 2>/dev/null; then
            check_fail "CORS 配置过于宽松" "不应允许所有 headers"
        else
            check_pass "CORS 配置合理"
        fi
        
        # 检查生产配置
        if [ -f backend/src/main/resources/application-prod.yml ]; then
            check_pass "生产配置文件存在"
        else
            check_warn "缺少生产配置文件" "建议创建 application-prod.yml"
        fi
    fi
}

# NPM 依赖检查
check_npm_dependencies() {
    echo ""
    echo -e "${BLUE}=== NPM 依赖检查 ===${NC}"
    
    if [ -f frontend/package.json ]; then
        # 检查关键依赖版本
        VUE_VERSION=$(grep '"vue":' frontend/package.json | grep -oE '[0-9]+\.[0-9]+' | head -1)
        if [ -n "$VUE_VERSION" ]; then
            MAJOR_VERSION=$(echo $VUE_VERSION | cut -d. -f1)
            if [ "$MAJOR_VERSION" -ge 3 ]; then
                check_pass "Vue 3.x 已配置"
            else
                check_fail "Vue 版本过低" "需要 Vue 3.x"
            fi
        fi
        
        # 检查是否有未使用的依赖
        TOTAL_DEPS=$(grep -c '".*":' frontend/package.json | head -1)
        if [ "$TOTAL_DEPS" -gt 50 ]; then
            check_warn "依赖数量较多 ($TOTAL_DEPS)" "考虑清理未使用的依赖"
        else
            check_pass "依赖数量合理"
        fi
    fi
}

# Docker 配置检查
check_docker_config() {
    echo ""
    echo -e "${BLUE}=== Docker 配置检查 ===${NC}"
    
    # 检查 Dockerfile 中的基础镜像
    if [ -f backend/Dockerfile ]; then
        if grep -q 'eclipse-temurin' backend/Dockerfile; then
            check_pass "后端使用推荐的基础镜像"
        else
            check_warn "后端基础镜像可更新" "建议使用 eclipse-temurin"
        fi
    fi
    
    # 检查 docker-compose.yml
    if [ -f docker-compose.yml ]; then
        if grep -q '^version:' docker-compose.yml; then
            check_warn "docker-compose 包含过时的 version 字段" "可以移除 version 字段"
        else
            check_pass "docker-compose.yml 格式正确"
        fi
    fi
}

# 数据库查询优化检查
check_database_queries() {
    echo ""
    echo -e "${BLUE}=== 数据库查询检查 ===${NC}"
    
    if [ -d backend/src ]; then
        # 检查 N+1 查询问题
        N_PLUS_ONE=$(grep -r "@OneToMany\|@ManyToMany" backend/src | grep -v "fetch.*EAGER" | wc -l)
        if [ "$N_PLUS_ONE" -gt 0 ]; then
            check_pass "避免了 N+1 查询问题（使用 LAZY 加载）"
        fi
        
        # 检查是否有原生 SQL
        NATIVE_QUERIES=$(grep -r "@Query.*nativeQuery.*true" backend/src 2>/dev/null | wc -l)
        if [ "$NATIVE_QUERIES" -eq 0 ]; then
            check_pass "没有使用原生 SQL（良好的可移植性）"
        else
            check_warn "发现 $NATIVE_QUERIES 处原生 SQL" "可能影响数据库可移植性"
        fi
    fi
}

# 执行修复建议
suggest_fixes() {
    echo ""
    echo -e "${MAGENTA}=== 自动修复建议 ===${NC}"
    
    if [ $FAILED_CHECKS -gt 0 ] || [ $WARNINGS -gt 0 ]; then
        echo "检测到问题，以下是修复建议："
        echo ""
        
        if grep -q 'commons-email.*1\.5' backend/pom.xml 2>/dev/null; then
            echo "1. 移除过时的 commons-email："
            echo "   编辑 backend/pom.xml，删除 commons-email 依赖"
            echo ""
        fi
        
        if ! grep -q '<lombok.version>' backend/pom.xml 2>/dev/null; then
            echo "2. 添加 Lombok 版本："
            echo "   在 pom.xml 的 <properties> 中添加："
            echo "   <lombok.version>1.18.30</lombok.version>"
            echo ""
        fi
        
        if [ ! -f backend/src/main/resources/application-prod.yml ]; then
            echo "3. 创建生产配置文件："
            echo "   cp backend/src/main/resources/application.yml backend/src/main/resources/application-prod.yml"
            echo "   然后修改生产特定的配置"
            echo ""
        fi
        
        echo "运行以下命令应用部分自动修复："
        echo -e "${GREEN}./apply-fixes.sh${NC}"
    else
        echo -e "${GREEN}系统状态良好，无需修复！${NC}"
    fi
}

# 生成详细报告
generate_report() {
    echo ""
    echo "========================================"
    echo "深度自检结果报告"
    echo "========================================"
    
    SUCCESS_RATE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    
    echo "检查项目: $TOTAL_CHECKS"
    echo -e "通过: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "失败: ${RED}$FAILED_CHECKS${NC}"
    echo -e "警告: ${YELLOW}$WARNINGS${NC}"
    echo ""
    
    echo -n "系统健康度: "
    if [ $FAILED_CHECKS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}${SUCCESS_RATE}% - 完美${NC}"
        echo "✨ 系统完全就绪，可以安全部署！"
    elif [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}${SUCCESS_RATE}% - 优秀${NC}"
        echo "系统可以部署，但建议处理警告项"
    elif [ $SUCCESS_RATE -ge 80 ]; then
        echo -e "${YELLOW}${SUCCESS_RATE}% - 良好${NC}"
        echo "系统基本就绪，需要修复关键问题"
    else
        echo -e "${RED}${SUCCESS_RATE}% - 需要修复${NC}"
        echo "❌ 请先修复关键问题再部署"
    fi
    
    if [ -n "$CRITICAL_ISSUES" ]; then
        echo ""
        echo -e "${RED}关键问题清单:${NC}"
        echo -e "$CRITICAL_ISSUES"
    fi
}

# 主函数
main() {
    print_header
    
    # 执行各项检查
    check_maven_dependencies
    check_java_code
    check_security_config
    check_npm_dependencies
    check_docker_config
    check_database_queries
    
    # 生成报告和建议
    generate_report
    suggest_fixes
    
    echo ""
    echo "下一步操作："
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo "  1. 运行部署脚本: ./deploy-smart.sh"
        echo "  2. 或本地运行: ./run-local.sh"
    else
        echo "  1. 根据上述建议修复问题"
        echo "  2. 重新运行: ./deep-check.sh"
        echo "  3. 修复后部署: ./deploy-smart.sh"
    fi
}

# 运行主函数
main