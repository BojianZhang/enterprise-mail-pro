#!/bin/bash

# 企业邮件系统 - 系统自检脚本
# 检查所有组件的兼容性和正确性

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 结果统计
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# 打印函数
print_header() {
    echo ""
    echo "========================================"
    echo "   企业邮件系统 - 系统自检 v1.0"
    echo "========================================"
    echo ""
}

check_item() {
    local description=$1
    local command=$2
    local expected=$3
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "检查: $description ... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ 通过${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ 失败${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_file() {
    local file=$1
    local description=$2
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "检查文件: $description ... "
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ 存在${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ 不存在${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_directory() {
    local dir=$1
    local description=$2
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "检查目录: $description ... "
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓ 存在${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ 不存在${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_maven_dependency() {
    local groupId=$1
    local artifactId=$2
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "Maven 依赖: $groupId:$artifactId ... "
    
    if grep -q "$artifactId" backend/pom.xml 2>/dev/null; then
        echo -e "${GREEN}✓ 已配置${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ 未找到${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_npm_dependency() {
    local package=$1
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "NPM 依赖: $package ... "
    
    if grep -q "\"$package\"" frontend/package.json 2>/dev/null; then
        echo -e "${GREEN}✓ 已配置${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ 未找到${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# 主检查流程
main() {
    print_header
    
    echo "=== 1. 项目结构检查 ==="
    check_directory "backend" "后端目录"
    check_directory "frontend" "前端目录"
    check_directory "backend/src/main/java" "Java 源码目录"
    check_directory "frontend/src" "前端源码目录"
    
    echo ""
    echo "=== 2. 配置文件检查 ==="
    check_file "backend/pom.xml" "Maven 配置"
    check_file "frontend/package.json" "NPM 配置"
    check_file "docker-compose.yml" "Docker Compose 配置"
    check_file "backend/src/main/resources/application.yml" "Spring Boot 配置"
    check_file "frontend/vite.config.ts" "Vite 配置"
    
    echo ""
    echo "=== 3. 后端依赖检查 ==="
    check_maven_dependency "org.springframework.boot" "spring-boot-starter-web"
    check_maven_dependency "com.mysql" "mysql-connector-j"
    check_maven_dependency "com.sun.mail" "jakarta.mail"
    check_maven_dependency "com.icegreen" "greenmail"
    check_maven_dependency "org.simplejavamail" "simple-java-mail"
    check_maven_dependency "io.jsonwebtoken" "jjwt-api"
    
    echo ""
    echo "=== 4. 前端依赖检查 ==="
    check_npm_dependency "vue"
    check_npm_dependency "vue-router"
    check_npm_dependency "pinia"
    check_npm_dependency "axios"
    check_npm_dependency "element-plus"
    check_npm_dependency "vite"
    check_npm_dependency "typescript"
    
    echo ""
    echo "=== 5. 代码兼容性检查 ==="
    
    # 检查 javax 到 jakarta 的迁移
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "检查 javax 导入（应该都迁移到 jakarta）... "
    if grep -r "import javax.mail" backend/src 2>/dev/null | grep -v ".git"; then
        echo -e "${YELLOW}⚠ 发现旧的 javax.mail 导入${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✓ 已迁移到 jakarta${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
    
    # 检查 MySQL 驱动类名
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "检查 MySQL 驱动配置... "
    if grep -q "com.mysql.cj.jdbc.Driver" backend/src/main/resources/application.yml 2>/dev/null; then
        echo -e "${GREEN}✓ 正确${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗ 驱动类名可能不正确${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
    
    echo ""
    echo "=== 6. Docker 配置检查 ==="
    
    # 检查 Dockerfile 基础镜像
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "检查后端 Dockerfile... "
    if [ -f backend/Dockerfile ]; then
        if grep -q "eclipse-temurin" backend/Dockerfile 2>/dev/null; then
            echo -e "${GREEN}✓ 使用推荐的基础镜像${NC}"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            echo -e "${YELLOW}⚠ 基础镜像可能需要更新${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${RED}✗ 文件不存在${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
    
    echo ""
    echo "=== 7. 脚本文件检查 ==="
    check_file "deploy-smart.sh" "智能部署脚本"
    check_file "run-local.sh" "本地运行脚本"
    check_file "stop-local.sh" "停止脚本"
    
    # 检查脚本执行权限
    for script in deploy-smart.sh run-local.sh stop-local.sh; do
        if [ -f "$script" ]; then
            TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
            echo -n "检查 $script 执行权限... "
            if [ -x "$script" ]; then
                echo -e "${GREEN}✓ 可执行${NC}"
                PASSED_CHECKS=$((PASSED_CHECKS + 1))
            else
                echo -e "${YELLOW}⚠ 需要添加执行权限${NC}"
                WARNINGS=$((WARNINGS + 1))
                chmod +x "$script"
            fi
        fi
    done
    
    echo ""
    echo "========================================"
    echo "自检结果汇总"
    echo "========================================"
    echo "总检查项: $TOTAL_CHECKS"
    echo -e "${GREEN}通过: $PASSED_CHECKS${NC}"
    echo -e "${RED}失败: $FAILED_CHECKS${NC}"
    echo -e "${YELLOW}警告: $WARNINGS${NC}"
    
    SUCCESS_RATE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    echo ""
    echo -n "总体健康度: "
    if [ $SUCCESS_RATE -ge 90 ]; then
        echo -e "${GREEN}${SUCCESS_RATE}% - 优秀${NC}"
        echo "系统已准备就绪，可以部署！"
    elif [ $SUCCESS_RATE -ge 70 ]; then
        echo -e "${YELLOW}${SUCCESS_RATE}% - 良好${NC}"
        echo "系统基本就绪，但建议修复警告项"
    else
        echo -e "${RED}${SUCCESS_RATE}% - 需要修复${NC}"
        echo "请先修复失败的检查项"
    fi
    
    echo ""
    echo "推荐的下一步操作："
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo "  ./deploy-smart.sh  # 运行智能部署脚本"
    else
        echo "  1. 修复上述失败的检查项"
        echo "  2. 重新运行此自检脚本"
        echo "  3. 运行 ./deploy-smart.sh 进行部署"
    fi
}

# 运行主函数
main