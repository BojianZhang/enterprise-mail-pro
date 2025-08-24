@echo off
REM 项目完整性检查脚本

echo ======================================
echo 企业邮件系统 - 项目完整性检查
echo ======================================
echo.

set TOTAL_CHECKS=0
set PASSED_CHECKS=0
set FAILED_CHECKS=0

echo 1. 检查项目结构
echo --------------------------------------
call :check_dir "backend" "后端项目目录"
call :check_dir "frontend" "前端项目目录"
call :check_dir "backend\src\main\java" "Java源代码目录"
call :check_dir "frontend\src" "前端源代码目录"
echo.

echo 2. 检查配置文件
echo --------------------------------------
call :check_file "docker-compose.yml" "Docker Compose配置"
call :check_file "backend\pom.xml" "Maven配置文件"
call :check_file "frontend\package.json" "前端依赖配置"
call :check_file "backend\src\main\resources\application.yml" "Spring Boot配置"
call :check_file "frontend\vite.config.ts" "Vite配置文件"
echo.

echo 3. 检查Docker文件
echo --------------------------------------
call :check_file "backend\Dockerfile" "后端Dockerfile"
call :check_file "frontend\Dockerfile" "前端Dockerfile"
call :check_file "frontend\nginx.conf" "Nginx配置"
echo.

echo 4. 检查部署脚本
echo --------------------------------------
call :check_file "deploy.sh" "Linux部署脚本"
call :check_file "deploy.bat" "Windows部署脚本"
call :check_file "test.sh" "Linux测试脚本"
call :check_file "test.bat" "Windows测试脚本"
echo.

echo 5. 检查核心源文件
echo --------------------------------------
call :check_file "backend\src\main\java\com\enterprise\mail\EnterpriseMailApplication.java" "Spring Boot主类"
call :check_file "backend\src\main\java\com\enterprise\mail\entity\User.java" "用户实体"
call :check_file "backend\src\main\java\com\enterprise\mail\entity\Email.java" "邮件实体"
call :check_file "backend\src\main\java\com\enterprise\mail\controller\AuthController.java" "认证控制器"
call :check_file "backend\src\main\java\com\enterprise\mail\service\EmailService.java" "邮件服务"
call :check_file "frontend\src\main.ts" "前端入口文件"
call :check_file "frontend\src\App.vue" "Vue根组件"
call :check_file "frontend\src\router\index.ts" "路由配置"
echo.

echo 6. 检查文档
echo --------------------------------------
call :check_file "README.md" "项目说明文档"
call :check_file "DEPLOYMENT_GUIDE.md" "部署指南"
call :check_file "QUICK_START.md" "快速启动指南"
call :check_file "PROJECT_SUMMARY.md" "项目总结"
echo.

echo 7. 检查数据库脚本
echo --------------------------------------
call :check_file "backend\src\main\resources\init.sql" "数据库初始化脚本"
echo.

echo ======================================
echo 检查结果汇总
echo ======================================
echo 总检查项: %TOTAL_CHECKS%
echo 通过: %PASSED_CHECKS%
echo 失败: %FAILED_CHECKS%
echo.

if %FAILED_CHECKS% equ 0 (
    echo √ 项目完整性检查通过！
    echo 您可以运行 deploy.bat 来部署项目
) else (
    echo × 项目完整性检查失败！
    echo 请检查缺失的文件或目录
)

pause
exit /b

:check_file
set /a TOTAL_CHECKS+=1
if exist %~1 (
    echo √ %~2
    set /a PASSED_CHECKS+=1
) else (
    echo × %~2 ^(缺失: %~1^)
    set /a FAILED_CHECKS+=1
)
goto :eof

:check_dir
set /a TOTAL_CHECKS+=1
if exist %~1 (
    echo √ %~2
    set /a PASSED_CHECKS+=1
) else (
    echo × %~2 ^(缺失: %~1^)
    set /a FAILED_CHECKS+=1
)
goto :eof