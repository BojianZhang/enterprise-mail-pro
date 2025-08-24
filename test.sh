#!/bin/bash

# 测试脚本 - 验证企业邮件系统功能

set -e

API_BASE="http://localhost:8080/api"
WEB_BASE="http://localhost"
TOKEN=""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印函数
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}➜ $1${NC}"
}

# 测试API健康检查
test_health() {
    print_info "测试健康检查接口..."
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE/actuator/health")
    if [ "$response" = "200" ]; then
        print_success "后端健康检查通过"
    else
        print_error "后端健康检查失败 (HTTP $response)"
        return 1
    fi
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$WEB_BASE/health")
    if [ "$response" = "200" ]; then
        print_success "前端健康检查通过"
    else
        print_error "前端健康检查失败 (HTTP $response)"
        return 1
    fi
}

# 测试用户注册
test_register() {
    print_info "测试用户注册..."
    
    response=$(curl -s -X POST "$API_BASE/auth/register" \
        -H "Content-Type: application/json" \
        -d '{
            "username": "testuser",
            "email": "testuser@enterprise.mail",
            "password": "Test123456",
            "firstName": "Test",
            "lastName": "User"
        }' \
        -w "\n%{http_code}")
    
    http_code=$(echo "$response" | tail -n 1)
    
    if [ "$http_code" = "201" ] || [ "$http_code" = "400" ]; then
        print_success "注册接口响应正常"
    else
        print_error "注册接口失败 (HTTP $http_code)"
        return 1
    fi
}

# 测试用户登录
test_login() {
    print_info "测试用户登录..."
    
    response=$(curl -s -X POST "$API_BASE/auth/login" \
        -H "Content-Type: application/json" \
        -d '{
            "username": "admin",
            "password": "admin123456"
        }')
    
    TOKEN=$(echo "$response" | grep -o '"token":"[^"]*' | sed 's/"token":"//')
    
    if [ -n "$TOKEN" ]; then
        print_success "登录成功，获取到Token"
    else
        print_error "登录失败，未获取到Token"
        return 1
    fi
}

# 测试获取邮件列表
test_get_emails() {
    print_info "测试获取邮件列表..."
    
    if [ -z "$TOKEN" ]; then
        print_error "未登录，跳过邮件列表测试"
        return 1
    fi
    
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $TOKEN" \
        "$API_BASE/emails")
    
    if [ "$response" = "200" ]; then
        print_success "获取邮件列表成功"
    else
        print_error "获取邮件列表失败 (HTTP $response)"
        return 1
    fi
}

# 测试SMTP端口
test_smtp() {
    print_info "测试SMTP端口..."
    
    nc -zv localhost 25 2>/dev/null
    if [ $? -eq 0 ]; then
        print_success "SMTP端口 (25) 可访问"
    else
        print_error "SMTP端口 (25) 无法访问"
    fi
}

# 测试IMAP端口
test_imap() {
    print_info "测试IMAP端口..."
    
    nc -zv localhost 143 2>/dev/null
    if [ $? -eq 0 ]; then
        print_success "IMAP端口 (143) 可访问"
    else
        print_error "IMAP端口 (143) 无法访问"
    fi
}

# 测试POP3端口
test_pop3() {
    print_info "测试POP3端口..."
    
    nc -zv localhost 110 2>/dev/null
    if [ $? -eq 0 ]; then
        print_success "POP3端口 (110) 可访问"
    else
        print_error "POP3端口 (110) 无法访问"
    fi
}

# 测试数据库连接
test_database() {
    print_info "测试数据库连接..."
    
    docker exec mail-mysql mysql -u mailuser -pmail123456 -e "SELECT 1" mail_system 2>/dev/null
    if [ $? -eq 0 ]; then
        print_success "数据库连接正常"
    else
        print_error "数据库连接失败"
    fi
}

# 测试Redis连接
test_redis() {
    print_info "测试Redis连接..."
    
    docker exec mail-redis redis-cli ping 2>/dev/null | grep -q PONG
    if [ $? -eq 0 ]; then
        print_success "Redis连接正常"
    else
        print_error "Redis连接失败"
    fi
}

# 主测试函数
main() {
    echo "======================================"
    echo "企业邮件系统 - 功能测试"
    echo "======================================"
    echo ""
    
    # 基础服务测试
    echo "1. 基础服务测试"
    echo "--------------------------------------"
    test_health
    test_database
    test_redis
    echo ""
    
    # API测试
    echo "2. API接口测试"
    echo "--------------------------------------"
    test_register
    test_login
    test_get_emails
    echo ""
    
    # 邮件服务测试
    echo "3. 邮件服务端口测试"
    echo "--------------------------------------"
    test_smtp
    test_imap
    test_pop3
    echo ""
    
    echo "======================================"
    echo "测试完成！"
    echo "======================================"
}

# 执行测试
main