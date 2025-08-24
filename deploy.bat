@echo off
REM 企业邮件系统 - Windows 部署脚本

echo ======================================
echo 企业邮件系统 - 部署脚本
echo ======================================

REM 检查 Docker
echo 检查 Docker 是否安装...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Docker 未安装
    echo 请访问 https://docs.docker.com/desktop/install/windows-install/ 安装 Docker Desktop
    pause
    exit /b 1
)
echo √ Docker 已安装

REM 检查 Docker Compose
echo 检查 Docker Compose 是否安装...
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Docker Compose 未安装
    pause
    exit /b 1
)
echo √ Docker Compose 已安装

REM 创建必要的目录
echo 创建必要的目录...
if not exist logs mkdir logs
if not exist nginx\ssl mkdir nginx\ssl
if not exist data\mysql mkdir data\mysql
if not exist data\redis mkdir data\redis
if not exist data\mail mkdir data\mail
echo √ 目录创建完成

REM 生成环境配置文件
if not exist .env (
    echo 生成环境配置文件...
    (
        echo # MySQL Configuration
        echo MYSQL_ROOT_PASSWORD=root123456
        echo MYSQL_DATABASE=mail_system
        echo MYSQL_USER=mailuser
        echo MYSQL_PASSWORD=mail123456
        echo.
        echo # Redis Configuration
        echo REDIS_PASSWORD=
        echo.
        echo # JWT Configuration
        echo JWT_SECRET=ThisIsAVerySecureSecretKeyForJWTTokenGenerationPleaseChangeInProduction2024
        echo.
        echo # Mail Server Configuration
        echo MAIL_DOMAIN=enterprise.mail
        echo MAIL_ADMIN_USER=admin
        echo MAIL_ADMIN_PASSWORD=admin123456
        echo.
        echo # Application Ports
        echo BACKEND_PORT=8080
        echo FRONTEND_PORT=80
        echo SMTP_PORT=25
        echo IMAP_PORT=143
        echo POP3_PORT=110
    ) > .env
    echo √ .env 文件已生成
) else (
    echo √ .env 文件已存在
)

REM 构建和启动服务
echo.
echo 构建 Docker 镜像...
docker-compose build

echo.
echo 启动服务...
docker-compose up -d

echo.
echo 等待服务启动...
timeout /t 10 /nobreak >nul

REM 检查服务状态
echo.
echo 检查服务状态...
docker-compose ps

echo.
echo ======================================
echo 部署完成！
echo ======================================
echo 访问地址:
echo   Web界面: http://localhost
echo   API文档: http://localhost:8080/api/swagger-ui.html
echo.
echo 默认管理员账号:
echo   用户名: admin
echo   密码: admin123456
echo.
echo 邮件服务端口:
echo   SMTP: 25, 465(SSL)
echo   IMAP: 143, 993(SSL)
echo   POP3: 110, 995(SSL)
echo.
echo 查看日志:
echo   docker-compose logs -f
echo.
echo 停止服务:
echo   docker-compose down
echo ======================================

pause