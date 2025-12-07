#!/bin/bash

# Mini广告墙 - 宝塔快速部署脚本
# 在服务器上执行此脚本以自动化部署过程

set -e

echo "=========================================="
echo "Mini广告墙 - 宝塔快速部署"
echo "=========================================="

# 配置变量
PROJECT_NAME="miniadwall"
PROJECT_PATH="/home/wwwroot/${PROJECT_NAME}"
SERVER_PORT=3001
API_SERVICE_NAME="miniadwall-api"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}[1/5] 检查系统环境...${NC}"
node -v || (echo "Node.js 未安装"; exit 1)
npm -v || (echo "npm 未安装"; exit 1)
pm2 -v || (echo "PM2 未安装，正在安装..."; npm install -g pm2)

echo -e "${BLUE}[2/5] 克隆或更新项目...${NC}"
if [ ! -d "${PROJECT_PATH}" ]; then
  mkdir -p /home/wwwroot
  cd /home/wwwroot
  git clone https://github.com/sky1232325/mini-adwall.git ${PROJECT_NAME}
else
  cd ${PROJECT_PATH}
  git pull
fi

echo -e "${BLUE}[3/5] 安装前端依赖并构建...${NC}"
cd ${PROJECT_PATH}
npm install
npm run build

echo -e "${BLUE}[4/5] 安装后端依赖...${NC}"
cd ${PROJECT_PATH}/server
npm install

# 创建 .env 文件（如不存在）
if [ ! -f ".env" ]; then
  echo "创建 .env 文件..."
  cat > .env << EOF
NODE_ENV=production
PORT=${SERVER_PORT}
UPLOAD_DIR=${PROJECT_PATH}/server/uploads
CORS_ORIGIN=*
EOF
fi

echo -e "${BLUE}[5/5] 使用 PM2 启动后端服务...${NC}"
pm2 delete ${API_SERVICE_NAME} 2>/dev/null || true
pm2 start index.js --name "${API_SERVICE_NAME}" --instances 2

echo -e "${GREEN}=========================================="
echo "✓ 部署完成！"
echo "=========================================="
echo "前端路径: ${PROJECT_PATH}/dist"
echo "后端服务: http://127.0.0.1:${SERVER_PORT}"
echo "PM2 服务名: ${API_SERVICE_NAME}"
echo ""
echo "接下来需要在宝塔面板中："
echo "1. 创建网站，根目录指向: ${PROJECT_PATH}/dist"
echo "2. 在 Nginx 配置中添加反向代理 /api/ 到 127.0.0.1:${SERVER_PORT}"
echo "3. 配置 SSL 证书"
echo ""
echo "查看日志: pm2 logs ${API_SERVICE_NAME}"
echo "开机自启: pm2 startup && pm2 save"
echo "=========================================="
echo -e "${NC}"
