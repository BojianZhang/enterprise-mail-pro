#!/bin/bash

# 企业邮件系统 - 超级深度自检 v7.0
# 终极零容忍模式 - 不放过任何细节

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 错误统计
total_checks=0
critical_errors=0
major_errors=0
minor_errors=0
warnings=0

# 日志函数
log_critical() {
    echo -e "${RED}[CRITICAL]${NC} $1"
    critical_errors=$((critical_errors + 1))
    total_checks=$((total_checks + 1))
}

log_major() {
    echo -e "${MAGENTA}[MAJOR]${NC} $1"
    major_errors=$((major_errors + 1))
    total_checks=$((total_checks + 1))
}

log_minor() {
    echo -e "${YELLOW}[MINOR]${NC} $1"
    minor_errors=$((minor_errors + 1))
    total_checks=$((total_checks + 1))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    warnings=$((warnings + 1))
    total_checks=$((total_checks + 1))
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
    total_checks=$((total_checks + 1))
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

echo -e "${WHITE}========================================${NC}"
echo -e "${WHITE}   超级深度自检 v7.0 - 终极扫描${NC}"
echo -e "${WHITE}========================================${NC}"
echo ""

# 1. 前端代码逻辑检查
echo -e "${BLUE}═══ 1. 前端代码逻辑检查 ═══${NC}"

# 检查console语句
log_info "扫描console语句..."
if grep -r "console\.\(log\|error\|warn\|debug\)" frontend/src --include="*.ts" --include="*.vue" --include="*.js" 2>/dev/null | grep -v "node_modules" | head -5; then
    log_minor "发现console语句未清理"
else
    log_success "无console语句"
fi

# 检查TODO/FIXME
log_info "扫描TODO/FIXME注释..."
if grep -r "TODO\|FIXME\|XXX\|HACK" frontend/src --include="*.ts" --include="*.vue" 2>/dev/null | head -5; then
    log_warning "发现未完成的TODO/FIXME"
else
    log_success "无TODO/FIXME注释"
fi

# 检查硬编码的URL
log_info "扫描硬编码URL..."
if grep -r "http://localhost\|https://localhost\|http://127.0.0.1" frontend/src --include="*.ts" --include="*.vue" 2>/dev/null | grep -v "/api" | head -5; then
    log_minor "发现硬编码的localhost URL"
else
    log_success "无硬编码URL"
fi

# 检查未使用的导入
log_info "检查TypeScript类型导入..."
if ! [ -f "frontend/src/types/user.ts" ]; then
    log_critical "缺失user.ts类型定义文件"
fi

echo ""

# 2. 后端代码逻辑检查
echo -e "${BLUE}═══ 2. 后端代码逻辑检查 ═══${NC}"

# 检查System.out.println
log_info "扫描System.out.println..."
if find backend/src -name "*.java" -exec grep -l "System\.out\.println" {} \; 2>/dev/null | head -5; then
    log_minor "发现System.out.println语句"
else
    log_success "无System.out.println"
fi

# 检查TODO注释
log_info "扫描Java TODO注释..."
if grep -r "TODO\|FIXME\|XXX" backend/src --include="*.java" 2>/dev/null | head -5; then
    log_warning "发现Java TODO注释"
else
    log_success "无Java TODO注释"
fi

# 检查空的catch块
log_info "检查空的catch块..."
if grep -A 2 "catch.*{$" backend/src --include="*.java" -r 2>/dev/null | grep -B 1 "^[[:space:]]*}$" | head -5; then
    log_major "发现空的catch块"
else
    log_success "无空的catch块"
fi

echo ""

# 3. 依赖版本检查
echo -e "${BLUE}═══ 3. 依赖版本检查 ═══${NC}"

# 检查前端依赖
log_info "检查前端package.json..."
if [ -f "frontend/package.json" ]; then
    # 检查是否有过时的依赖
    if grep -E '"vue":\s*"\^2\.' frontend/package.json; then
        log_major "Vue版本过旧（应该是3.x）"
    else
        log_success "Vue版本正确"
    fi
    
    # 检查是否有安全漏洞的包
    if grep -E '"lodash":\s*"[<^]4\.17\.19"' frontend/package.json; then
        log_critical "lodash版本有安全漏洞"
    fi
else
    log_critical "frontend/package.json不存在"
fi

# 检查后端依赖
log_info "检查后端pom.xml..."
if [ -f "backend/pom.xml" ]; then
    # 检查Spring Boot版本
    if grep -E "<version>2\.[0-4]\." backend/pom.xml; then
        log_major "Spring Boot版本过旧"
    else
        log_success "Spring Boot版本合适"
    fi
    
    # 检查是否有未使用的依赖配置
    if grep "mapstruct" backend/pom.xml | grep -v "<!--"; then
        if ! grep "<artifactId>mapstruct</artifactId>" backend/pom.xml; then
            log_minor "MapStruct配置存在但依赖缺失"
        fi
    fi
else
    log_critical "backend/pom.xml不存在"
fi

echo ""

# 4. 配置文件一致性检查
echo -e "${BLUE}═══ 4. 配置文件一致性 ═══${NC}"

# 检查密码配置
log_info "检查弱密码..."
weak_passwords="changeme|password|123456|admin|root|test|demo"
if grep -E "$weak_passwords" backend/src/main/resources/application*.yml 2>/dev/null | grep -v "^#"; then
    log_critical "配置文件包含弱密码"
else
    log_success "无明显弱密码"
fi

# 检查重复配置
log_info "检查重复配置项..."
if [ -f "backend/src/main/resources/application.yml" ]; then
    duplicate_keys=$(grep -E "^[[:space:]]*[a-z-]+:" backend/src/main/resources/application.yml | sort | uniq -d)
    if [ -n "$duplicate_keys" ]; then
        echo "$duplicate_keys"
        log_major "发现重复的配置键"
    else
        log_success "无重复配置"
    fi
fi

# 检查环境变量一致性
log_info "检查环境变量命名..."
if [ -f ".env" ]; then
    # 检查.env和docker-compose的一致性
    env_vars=$(grep -E "^[A-Z_]+=" .env | cut -d= -f1)
    for var in $env_vars; do
        if ! grep -q "\${$var" docker-compose.yml 2>/dev/null; then
            log_warning ".env中的$var在docker-compose.yml中未使用"
        fi
    done
fi

echo ""

# 5. API契约检查
echo -e "${BLUE}═══ 5. API契约一致性 ═══${NC}"

# 检查前端API调用路径
log_info "检查API路径一致性..."
frontend_apis=$(grep -h "url:" frontend/src/api/*.ts 2>/dev/null | sed "s/.*['\"]\/\(.*\)['\"].*/\1/" | sort -u)
backend_mappings=$(grep -h "@.*Mapping" backend/src/main/java/com/enterprise/mail/controller/*.java 2>/dev/null | sed 's/.*["\(]\([^")]*\).*/\1/' | sort -u)

# 简单对比（实际需要更复杂的逻辑）
log_info "前端定义了 $(echo "$frontend_apis" | wc -l) 个API"
log_info "后端定义了 $(echo "$backend_mappings" | wc -l) 个映射"

echo ""

# 6. Docker配置检查
echo -e "${BLUE}═══ 6. Docker配置检查 ═══${NC}"

# 检查Dockerfile
for dockerfile in backend/Dockerfile frontend/Dockerfile; do
    if [ -f "$dockerfile" ]; then
        # 检查是否使用latest标签
        if grep "FROM.*:latest" "$dockerfile"; then
            log_warning "$dockerfile 使用了latest标签"
        else
            log_success "$dockerfile 版本固定"
        fi
        
        # 检查是否有健康检查
        if ! grep -q "HEALTHCHECK" "$dockerfile"; then
            log_minor "$dockerfile 缺少HEALTHCHECK"
        fi
    else
        log_critical "$dockerfile 不存在"
    fi
done

# 检查docker-compose端口映射
log_info "检查端口冲突..."
ports=$(grep -E "^[[:space:]]*-.*:[0-9]+" docker-compose.yml 2>/dev/null | sed 's/.*"\?\([0-9]*\):.*/\1/' | sort)
duplicate_ports=$(echo "$ports" | uniq -d)
if [ -n "$duplicate_ports" ]; then
    echo "重复端口: $duplicate_ports"
    log_major "发现端口冲突"
else
    log_success "无端口冲突"
fi

echo ""

# 7. 安全配置检查
echo -e "${BLUE}═══ 7. 安全配置检查 ═══${NC}"

# 检查JWT密钥长度
log_info "检查JWT密钥强度..."
if [ -f ".env" ]; then
    jwt_secret=$(grep "^JWT_SECRET=" .env | cut -d= -f2)
    if [ ${#jwt_secret} -lt 32 ]; then
        log_critical "JWT密钥太短（少于32字符）"
    else
        log_success "JWT密钥长度合适"
    fi
fi

# 检查CORS配置
log_info "检查CORS配置..."
if grep -q "allowed-origins:.*\*" backend/src/main/resources/application*.yml 2>/dev/null; then
    log_warning "CORS允许所有来源（仅开发环境可接受）"
fi

# 检查SSL/TLS配置
if ! grep -q "require-https.*true" backend/src/main/resources/application-prod.yml 2>/dev/null; then
    log_major "生产环境未强制HTTPS"
fi

echo ""

# 8. 数据库检查
echo -e "${BLUE}═══ 8. 数据库配置检查 ═══${NC}"

# 检查数据库初始化脚本
for sql_file in backend/src/main/resources/*.sql; do
    if [ -f "$sql_file" ]; then
        # 检查是否有DROP语句
        if grep -i "DROP TABLE\|DROP DATABASE" "$sql_file" 2>/dev/null; then
            log_warning "$sql_file 包含DROP语句"
        fi
        
        # 检查是否有明文密码
        if grep -i "PASSWORD.*=.*['\"]" "$sql_file" 2>/dev/null | grep -v "PASSWORD('"; then
            log_critical "$sql_file 可能包含明文密码"
        fi
    fi
done

# 检查连接池配置
log_info "检查数据库连接池..."
if ! grep -q "maximum-pool-size" backend/src/main/resources/application.yml 2>/dev/null; then
    log_minor "未配置连接池大小"
fi

echo ""

# 9. 日志配置检查
echo -e "${BLUE}═══ 9. 日志配置检查 ═══${NC}"

# 检查日志级别
log_info "检查日志级别..."
if grep -q "level:.*DEBUG" backend/src/main/resources/application-prod.yml 2>/dev/null; then
    log_major "生产环境日志级别为DEBUG"
fi

# 检查日志文件大小限制
if ! grep -q "max-size\|max-history" backend/src/main/resources/application.yml 2>/dev/null; then
    log_minor "未配置日志文件大小限制"
else
    log_success "日志文件有大小限制"
fi

echo ""

# 10. 性能配置检查
echo -e "${BLUE}═══ 10. 性能优化检查 ═══${NC}"

# 检查缓存配置
log_info "检查缓存配置..."
if ! grep -q "cache:.*redis" backend/src/main/resources/application.yml 2>/dev/null; then
    log_warning "未启用Redis缓存"
else
    log_success "Redis缓存已配置"
fi

# 检查Gzip压缩
if ! grep -q "gzip on" frontend/nginx.conf 2>/dev/null; then
    log_minor "Nginx未启用Gzip压缩"
else
    log_success "Nginx Gzip已启用"
fi

echo ""

# ============ 生成报告 ============
echo -e "${WHITE}========================================${NC}"
echo -e "${WHITE}   扫描结果汇总${NC}"
echo -e "${WHITE}========================================${NC}"
echo ""

echo -e "扫描项目总数: ${WHITE}$total_checks${NC}"
echo -e "${RED}致命错误: $critical_errors${NC}"
echo -e "${MAGENTA}重大问题: $major_errors${NC}"
echo -e "${YELLOW}次要问题: $minor_errors${NC}"
echo -e "${YELLOW}警告: $warnings${NC}"
echo ""

# 计算健康度
total_issues=$((critical_errors + major_errors + minor_errors + warnings))
if [ $total_checks -gt 0 ]; then
    health_score=$((100 - (total_issues * 100 / total_checks)))
else
    health_score=0
fi

# 显示健康度
echo -n "系统健康度: ["
for i in {1..20}; do
    if [ $((i * 5)) -le $health_score ]; then
        if [ $health_score -ge 80 ]; then
            echo -n -e "${GREEN}█${NC}"
        elif [ $health_score -ge 60 ]; then
            echo -n -e "${YELLOW}█${NC}"
        else
            echo -n -e "${RED}█${NC}"
        fi
    else
        echo -n "░"
    fi
done
echo "] ${health_score}%"
echo ""

# 系统评级
if [ $critical_errors -gt 0 ]; then
    echo -e "系统评级: ${RED}F - 严重问题，禁止部署${NC}"
elif [ $major_errors -gt 0 ]; then
    echo -e "系统评级: ${MAGENTA}D - 重大问题，需立即修复${NC}"
elif [ $minor_errors -gt 5 ]; then
    echo -e "系统评级: ${YELLOW}C - 较多问题，建议修复${NC}"
elif [ $minor_errors -gt 0 ] || [ $warnings -gt 5 ]; then
    echo -e "系统评级: ${CYAN}B - 轻微问题，可以部署${NC}"
else
    echo -e "系统评级: ${GREEN}A - 优秀，生产就绪${NC}"
fi

echo ""

# 关键修复建议
if [ $critical_errors -gt 0 ] || [ $major_errors -gt 0 ]; then
    echo -e "${WHITE}关键修复建议:${NC}"
    echo "-------------------"
    
    if grep -q "changeme\|password\|123456" backend/src/main/resources/application*.yml 2>/dev/null; then
        echo "1. 立即更新所有弱密码"
    fi
    
    if [ $critical_errors -gt 0 ]; then
        echo "2. 修复所有致命错误后才能部署"
    fi
    
    if [ $major_errors -gt 0 ]; then
        echo "3. 解决主要问题以确保系统稳定"
    fi
    
    echo ""
fi

# 下一步行动
echo -e "${WHITE}建议下一步:${NC}"
echo "-------------------"
if [ $critical_errors -gt 0 ]; then
    echo "1. 运行: ./auto-fix.sh"
    echo "2. 手动修复致命错误"
    echo "3. 重新运行: ./super-check-v7.sh"
elif [ $health_score -ge 80 ]; then
    echo "1. 系统已准备就绪"
    echo "2. 运行: docker-compose build"
    echo "3. 部署: docker-compose up -d"
else
    echo "1. 查看上述问题清单"
    echo "2. 逐项修复问题"
    echo "3. 重新检查: ./super-check-v7.sh"
fi

echo ""
echo -e "${WHITE}========================================${NC}"
echo -e "${WHITE}   扫描完成 - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${WHITE}========================================${NC}"

# 根据严重程度返回不同的退出码
if [ $critical_errors -gt 0 ]; then
    exit 2
elif [ $major_errors -gt 0 ]; then
    exit 1
else
    exit 0
fi