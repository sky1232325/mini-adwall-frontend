@echo off
REM Mini广告墙 - 本地构建和准备脚本
REM 用于在 Windows 上快速构建项目并准备部署

SETLOCAL ENABLEDELAYEDEXPANSION

echo ==========================================
echo Mini广告墙 - 本地部署准备
echo ==========================================
echo.

REM 检查 Node.js
echo [1/6] 检查 Node.js 环境...
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js 未安装，请先安装 Node.js v16+
    pause
    exit /b 1
)
echo ✓ Node.js 版本：
node --version
npm --version
echo.

REM 安装前端依赖
echo [2/6] 安装前端依赖...
call npm install
if errorlevel 1 (
    echo ❌ 前端依赖安装失败
    pause
    exit /b 1
)
echo ✓ 前端依赖安装完成
echo.

REM 安装后端依赖
echo [3/6] 安装后端依赖...
cd server
call npm install
if errorlevel 1 (
    echo ❌ 后端依赖安装失败
    cd ..
    pause
    exit /b 1
)
echo ✓ 后端依赖安装完成
cd ..
echo.

REM 构建前端
echo [4/6] 构建前端应用...
call npm run build
if errorlevel 1 (
    echo ❌ 前端构建失败
    pause
    exit /b 1
)
echo ✓ 前端构建完成
echo.

REM 创建部署文件夹
echo [5/6] 准备部署文件...
if exist "deploy-package" rmdir /s /q deploy-package
mkdir deploy-package
mkdir deploy-package\dist
mkdir deploy-package\server
mkdir deploy-package\server\uploads

REM 复制文件
xcopy /E /I dist deploy-package\dist
xcopy /E /I server\*.js deploy-package\server\
xcopy /E /I server\package.json deploy-package\server\
xcopy /E /I server\package-lock.json deploy-package\server\
xcopy /E /I server\.env.example deploy-package\server\

copy README.md deploy-package\
copy DEPLOY_TO_BAOTA.md deploy-package\
copy DEPLOY_CHECKLIST.md deploy-package\
copy DEPLOY_SUMMARY.md deploy-package\
copy NGINX_CONFIG.md deploy-package\

echo ✓ 部署文件准备完成
echo.

REM 显示信息
echo [6/6] 部署信息
echo.
echo ==========================================
echo ✓ 部署准备完成！
echo ==========================================
echo.
echo 📁 部署包位置：%cd%\deploy-package\
echo.
echo 下一步操作：
echo 1. 使用 FTP/SFTP 工具或宝塔文件管理器上传 deploy-package 文件夹
echo 2. 在服务器上运行部署脚本或手动执行以下命令：
echo.
echo    cd /home/wwwroot/
echo    git clone https://github.com/sky1232325/mini-adwall.git miniadwall
echo    cd miniadwall
echo    npm install
echo    npm run build
echo    cd server
echo    npm install
echo    pm2 start index.js --name "miniadwall-api"
echo.
echo 3. 在宝塔面板中创建网站并配置 Nginx
echo.
echo 详细指南请查看：DEPLOY_CHECKLIST.md 或 DEPLOY_TO_BAOTA.md
echo ==========================================
echo.

pause
