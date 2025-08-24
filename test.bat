@echo off
REM 测试脚本 - 验证企业邮件系统功能

echo ======================================
echo 企业邮件系统 - 功能测试
echo ======================================
echo.

echo 1. 基础服务测试
echo --------------------------------------

REM 测试健康检查
echo 测试健康检查接口...
curl -s -o nul -w "后端健康检查: HTTP %%{http_code}\n" http://localhost:8080/api/actuator/health
curl -s -o nul -w "前端健康检查: HTTP %%{http_code}\n" http://localhost/health
echo.

REM 测试数据库连接
echo 测试数据库连接...
docker exec mail-mysql mysql -u mailuser -pmail123456 -e "SELECT 1" mail_system >nul 2>&1
if %errorlevel% equ 0 (
    echo √ 数据库连接正常
) else (
    echo × 数据库连接失败
)

REM 测试Redis连接
echo 测试Redis连接...
docker exec mail-redis redis-cli ping >nul 2>&1
if %errorlevel% equ 0 (
    echo √ Redis连接正常
) else (
    echo × Redis连接失败
)
echo.

echo 2. API接口测试
echo --------------------------------------

REM 测试登录
echo 测试用户登录...
curl -s -X POST http://localhost:8080/api/auth/login -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"admin123456\"}" | findstr "token" >nul
if %errorlevel% equ 0 (
    echo √ 登录接口正常
) else (
    echo × 登录接口失败
)
echo.

echo 3. 邮件服务端口测试
echo --------------------------------------

REM 测试SMTP端口
echo 测试SMTP端口...
netstat -an | findstr :25 >nul
if %errorlevel% equ 0 (
    echo √ SMTP端口 (25) 正常
) else (
    echo × SMTP端口 (25) 未开放
)

REM 测试IMAP端口
echo 测试IMAP端口...
netstat -an | findstr :143 >nul
if %errorlevel% equ 0 (
    echo √ IMAP端口 (143) 正常
) else (
    echo × IMAP端口 (143) 未开放
)

REM 测试POP3端口
echo 测试POP3端口...
netstat -an | findstr :110 >nul
if %errorlevel% equ 0 (
    echo √ POP3端口 (110) 正常
) else (
    echo × POP3端口 (110) 未开放
)
echo.

echo ======================================
echo 测试完成！
echo ======================================

pause