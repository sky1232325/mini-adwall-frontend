# 宝塔面板部署指南 - Mini广告墙项目

本指南详细说明如何将前后端项目部署到运行宝塔面板的服务器上。

---

## 📋 前置准备

### 您需要以下信息：
1. **服务器地址**（IP 或域名）
2. **SSH 登录凭证**（用户名/密码 或密钥）
3. **宝塔面板访问地址和账号**
4. **域名**（可选，建议有）

### 请检查以下条件：
- [ ] 宝塔面板已安装
- [ ] Node.js 已安装（v16+）
- [ ] Nginx 已安装或准备好在宝塔中使用
- [ ] SSL 证书已配置（HTTPS）

---

## 🚀 部署步骤

### **第一步：准备文件上传**

#### 1.1 本地打包项目

在你的电脑上执行以下命令：

```bash
# 进入项目目录
cd d:\VS code\miniAdWall_rebuild

# 安装所有依赖
npm install
cd server && npm install && cd ..

# 构建前端（已做过）
npm run build

# 创建部署包（包含所需的所有文件）
```

#### 1.2 准备上传的文件结构

创建一个部署文件夹，包含以下内容：

```
miniadwall-deploy/
├── dist/                    # 前端构建输出（从 dist 文件夹复制）
├── server/                  # 后端服务器
│   ├── index.js            # 服务器入口文件
│   ├── package.json        # 依赖配置
│   └── package-lock.json   # 锁定版本
├── README.md               # 项目说明
└── deploy-info.txt         # 部署信息
```

**建议方式**：使用 Git 克隆到服务器（推荐）

---

## 🔧 通过宝塔面板部署

### **第二步：通过宝塔面板创建网站**

#### 2.1 创建前端网站（React 静态应用）

1. **登录宝塔面板** → 进入 **网站** 菜单
2. 点击 **添加站点**
3. 填写以下信息：
   - **域名**：你的前端域名（如 `adwall.example.com`）
   - **根目录**：选择 `/home/wwwroot/你的项目名`
   - **PHP版本**：选择 **纯静态**（不需要PHP）
   - **是否启用SSL**：勾选（推荐）

4. 创建后，进入网站设置：
   - 点击你刚创建的网站
   - 选择 **网站目录** → 进入根目录
   - **上传** 或 **复制** `dist` 文件夹中的所有内容到此目录

#### 2.2 配置前端 Nginx 反向代理

1. 进入网站设置 → **配置文件**
2. 找到 `location / { }` 块，修改为：

```nginx
location / {
    # 支持 React Router 的 History 模式
    try_files $uri $uri/ /index.html;
    
    # 禁用缓存 HTML 文件
    add_header Cache-Control "no-cache, no-store, must-revalidate";
}

# 缓存静态资源
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

3. 保存配置，Nginx 会自动重启

---

### **第三步：部署后端 Node.js 应用**

#### 3.1 使用宝塔的 Node.js 项目管理

1. **登录宝塔面板** → 进入 **应用商店** 或 **软件管理**
2. 搜索并安装 **Node.js** 和 **PM2**（如果未安装）

#### 3.2 通过 SSH 上传并运行后端

使用 SSH 工具（如 PuTTY、Xshell 或 VS Code Remote）：

```bash
# 1. SSH 连接到服务器
ssh root@你的服务器IP

# 2. 进入宝塔应用目录
cd /home/wwwroot/

# 3. 克隆项目（推荐）或上传文件
git clone https://github.com/sky1232325/mini-adwall.git miniadwall-api

# 4. 进入后端目录
cd miniadwall-api/server

# 5. 安装依赖
npm install

# 6. 使用 PM2 启动服务
pm2 start index.js --name "miniadwall-api"

# 7. 保存 PM2 配置
pm2 save

# 8. 开机自启
pm2 startup
pm2 save
```

#### 3.3 在宝塔中创建反向代理（前端调用后端）

后端需要通过 Nginx 反向代理暴露。在前端网站配置中添加：

```nginx
# 添加到前端网站的 Nginx 配置
location /api/ {
    proxy_pass http://127.0.0.1:3001;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # 增加超时时间
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
}
```

---

### **第四步：配置环境变量和数据库（如需要）

创建后端配置文件 `server/.env`：

```env
NODE_ENV=production
PORT=3001
UPLOAD_DIR=/home/wwwroot/miniadwall-api/server/uploads
CORS_ORIGIN=https://你的前端域名.com
```

修改 `server/index.js` 支持环境变量：

```javascript
require('dotenv').config();
const CORS_ORIGIN = process.env.CORS_ORIGIN || '*';
app.use(cors({ origin: CORS_ORIGIN }));
```

---

## 🔒 安全性配置

### 4.1 防火墙设置

在宝塔面板 → **安全** → **防火墙**：
- 开放端口 **80**（HTTP）
- 开放端口 **443**（HTTPS）
- 可选：开放 **3001**（仅内部使用）

### 4.2 SSL 证书

1. 宝塔面板 → 网站设置 → **SSL**
2. 使用免费证书（Let's Encrypt）或付费证书
3. 强制 HTTPS 重定向

### 4.3 文件权限

```bash
# SSH 连接后执行
chmod -R 755 /home/wwwroot/miniadwall-api
chmod -R 777 /home/wwwroot/miniadwall-api/server/uploads
```

---

## 📊 监控和日志

### 5.1 查看后端日志

```bash
# 查看 PM2 日志
pm2 logs miniadwall-api

# 查看详细日志
pm2 logs miniadwall-api --lines 100

# 实时监控
pm2 monit
```

### 5.2 在宝塔中监控

- 进入 **终端** → 可以看到实时日志
- 进入 **监控** → 查看服务器资源使用情况

---

## 🔄 更新和维护

### 6.1 更新前端

```bash
# 本地构建新版本
npm run build

# 通过 SCP 或宝塔文件管理上传新的 dist 文件
```

### 6.2 更新后端

```bash
# SSH 连接后
cd /home/wwwroot/miniadwall-api/server

# 更新代码
git pull

# 重启服务
pm2 restart miniadwall-api
```

---

## 🐛 常见问题排查

### 问题 1：前端无法加载

**原因**：Nginx 配置问题
**解决**：
```bash
# 检查 Nginx 语法
nginx -t

# 重启 Nginx
systemctl restart nginx
```

### 问题 2：API 调用 404

**原因**：反向代理配置错误
**检查**：
- 确认后端服务运行中：`pm2 status`
- 检查后端监听端口：`netstat -tlnp | grep 3001`
- 测试本地连接：`curl http://127.0.0.1:3001/api/health`

### 问题 3：CORS 错误

**原因**：跨域配置不正确
**解决**：在 `server/index.js` 中配置正确的域名

```javascript
app.use(cors({ 
  origin: ['https://你的前端域名.com', 'https://www.你的前端域名.com']
}));
```

### 问题 4：文件上传失败

**原因**：权限或路径问题
**解决**：
```bash
chmod -R 777 /home/wwwroot/miniadwall-api/server/uploads
```

---

## ✅ 部署检查清单

部署完成后，请逐一检查：

- [ ] 前端网站可访问（HTTPS）
- [ ] 前端可以正常加载，无 404 错误
- [ ] 后端 API `/api/health` 返回成功
- [ ] 前端可以正常调用后端 API
- [ ] 文件上传功能正常
- [ ] PM2 已配置开机自启
- [ ] SSL 证书有效（不过期）
- [ ] 日志监控正常

---

## 🎯 快速参考命令

```bash
# PM2 常用命令
pm2 start index.js --name "miniadwall-api"     # 启动
pm2 stop miniadwall-api                         # 停止
pm2 restart miniadwall-api                      # 重启
pm2 delete miniadwall-api                       # 删除
pm2 list                                        # 列表
pm2 logs miniadwall-api                         # 查看日志

# 文件权限
chmod -R 755 /home/wwwroot/路径                 # 只读权限
chmod -R 777 /home/wwwroot/路径                 # 完全权限

# Nginx
systemctl restart nginx                         # 重启 Nginx
nginx -t                                        # 检查配置
```

---

## 📞 获取帮助

如遇到问题，请检查：
1. 宝塔面板的错误日志
2. PM2 的日志输出
3. Nginx 的访问日志：`/www/wwwlogs/你的域名.log`

祝部署顺利！🚀
