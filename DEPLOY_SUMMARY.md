# 部署总结和快速参考

## 📦 项目部署概览

```
┌─────────────────────────────────────────────────────────────┐
│                     用户浏览器                               │
│                  (访问 HTTPS 域名)                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        ▼                             ▼
   ┌─────────────┐            ┌──────────────┐
   │   Nginx     │            │   Nginx      │
   │   :443      │            │   :80→:443   │
   │             │            │              │
   │ ┌─────────┐ │            │ (重定向)     │
   │ │ 前端静态 │ │            │              │
   │ │   文件  │ │            │              │
   │ └─────────┘ │            │              │
   │ (dist/)     │            │              │
   │             │            │              │
   │ ┌─────────┐ │            │              │
   │ │/api代理 │ │            │              │
   │ │→:3001  │─┼────────────┼─→  ┌───────┐ │
   │ └─────────┘ │            │    │Node.js│ │
   └─────────────┘            │    │:3001  │ │
                              │    │       │ │
                              │    └───────┘ │
                              │ (PM2管理)   │
                              └──────────────┘

宝塔面板 Linux 服务器
```

---

## 🎯 部署核心步骤

### 1️⃣ **前期准备**（本地电脑）

```powershell
# 确保项目已构建
cd d:\VS code\miniAdWall_rebuild
npm run build      # ✓ 生成 dist 文件夹
```

### 2️⃣ **上传到服务器**（3 种方式）

#### ✅ 方式 A：Git 克隆（推荐，便于更新）
```bash
ssh root@你的服务器IP
cd /home/wwwroot
git clone https://github.com/sky1232325/mini-adwall.git miniadwall
cd miniadwall
npm install && npm run build
cd server && npm install
```

#### ✅ 方式 B：宝塔文件管理器上传
- 登录宝塔面板 → 文件 → 上传整个项目文件夹
- SSH 进入目录执行 npm install

#### ✅ 方式 C：SFTP 工具（如 FileZilla）
- 下载并配置 SFTP 客户端
- 上传到 `/home/wwwroot/`

### 3️⃣ **配置前端网站**（宝塔面板）

```
网站菜单 → 添加站点
├─ 域名: adwall.example.com
├─ 根目录: /home/wwwroot/miniadwall/dist
├─ PHP版本: 纯静态
└─ SSL: ✓ 启用 (Let's Encrypt 免费)
```

### 4️⃣ **配置 Nginx**（宝塔面板）

```
网站设置 → 配置文件 → 替换以下部分：

location / {
    try_files $uri $uri/ /index.html;
    add_header Cache-Control "no-cache, no-store, must-revalidate";
}

location /api/ {
    proxy_pass http://127.0.0.1:3001;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

### 5️⃣ **启动后端服务**（SSH）

```bash
cd /home/wwwroot/miniadwall/server
npm install
pm2 start index.js --name "miniadwall-api" --instances 2
pm2 save
pm2 startup
```

---

## 🗂️ 服务器目录结构

```
/home/wwwroot/
├── miniadwall/                    ← 项目根目录
│   ├── dist/                      ← 前端静态文件（Nginx 访问）
│   │   ├── index.html
│   │   ├── assets/
│   │   └── ...
│   ├── server/                    ← 后端 Node.js 项目
│   │   ├── index.js               ← 服务器入口
│   │   ├── package.json
│   │   ├── uploads/               ← 上传文件保存位置
│   │   └── .env                   ← 环境配置（需创建）
│   ├── src/                       ← 源代码（可选）
│   ├── package.json
│   └── README.md
```

---

## 🔍 验证部署

### ✅ 前端检查
```
在浏览器打开：https://你的域名.com
应该看到：Mini 广告墙应用正常加载
```

### ✅ 后端检查
```bash
# 方式 1：通过宝塔终端
curl http://127.0.0.1:3001/api/health
# 返回：{"status":"ok","message":"Server is running"}

# 方式 2：通过前端域名
curl https://你的域名.com/api/health
```

### ✅ API 连接检查
```
打开浏览器开发者工具 (F12)
→ Network 标签
→ 刷新页面
→ 检查是否有请求到 /api/ 的网络连接
→ 确保状态码是 200（成功）
```

### ✅ 日志检查
```bash
# 查看后端实时日志
pm2 logs miniadwall-api --lines 50

# 查看 Nginx 错误
tail -f /www/wwwlogs/你的域名.log

# 查看系统日志
journalctl -u nginx -n 50

# 监控系统资源
pm2 monit
```

---

## ⚙️ 常用命令速查

### PM2 命令（后端管理）

| 命令 | 说明 |
|------|------|
| `pm2 start index.js --name "api"` | 启动服务 |
| `pm2 stop miniadwall-api` | 停止服务 |
| `pm2 restart miniadwall-api` | 重启服务 |
| `pm2 delete miniadwall-api` | 删除服务 |
| `pm2 status` | 查看运行状态 |
| `pm2 logs miniadwall-api` | 查看日志 |
| `pm2 monit` | 实时监控 |
| `pm2 save` | 保存配置 |
| `pm2 startup` | 开机自启 |

### Nginx 命令（前端服务）

| 命令 | 说明 |
|------|------|
| `systemctl start nginx` | 启动 Nginx |
| `systemctl stop nginx` | 停止 Nginx |
| `systemctl restart nginx` | 重启 Nginx |
| `nginx -t` | 测试配置 |
| `systemctl status nginx` | 查看状态 |

### 文件权限命令

| 命令 | 说明 |
|------|------|
| `chmod -R 755 路径` | 目录可读取 |
| `chmod -R 777 路径` | 目录完全权限 |
| `chown -R www:www 路径` | 更改所有者 |

---

## 🚨 常见问题速解

### ❌ 前端 404 错误

```bash
# 检查静态文件
ls -la /home/wwwroot/miniadwall/dist/index.html

# 检查权限
chmod -R 755 /home/wwwroot/miniadwall/dist/

# 重建前端
cd /home/wwwroot/miniadwall
npm run build

# 重启 Nginx
systemctl restart nginx
```

### ❌ API 502 错误

```bash
# 检查后端是否运行
pm2 status

# 检查端口占用
netstat -tlnp | grep 3001

# 重启后端
pm2 restart miniadwall-api

# 查看错误日志
pm2 logs miniadwall-api
```

### ❌ CORS 错误

编辑 `/home/wwwroot/miniadwall/server/index.js`：
```javascript
app.use(cors({
  origin: 'https://你的域名.com',
  credentials: true
}));
```
重启：`pm2 restart miniadwall-api`

### ❌ 文件上传失败

```bash
# 创建上传目录
mkdir -p /home/wwwroot/miniadwall/server/uploads

# 设置权限
chmod -R 777 /home/wwwroot/miniadwall/server/uploads
```

---

## 📈 性能优化

### 1. 启用 Gzip 压缩
在 Nginx 配置中添加：
```nginx
gzip on;
gzip_types text/plain text/css application/json application/javascript;
gzip_comp_level 6;
```

### 2. 设置缓存策略
```nginx
# 长期缓存静态资源
location ~* \.(js|css|png|jpg)$ {
    expires 30d;
}

# 短期缓存 HTML
location ~* \.html$ {
    expires 1h;
}
```

### 3. 启用 HTTP/2
```nginx
listen 443 ssl http2;
```

### 4. 多进程运行后端
```bash
pm2 start index.js --instances max  # 使用 CPU 核数
```

---

## 🔒 安全建议

### 1. 防火墙配置（宝塔面板）
- 安全 → 防火墙
- 开放端口：80, 443
- 关闭不必要端口

### 2. 隐藏敏感文件
```nginx
location ~ /\.(env|git|gitignore) {
    deny all;
}
```

### 3. 定期备份
```bash
# 备份上传文件
tar -czf backup-uploads.tar.gz /home/wwwroot/miniadwall/server/uploads/

# 备份数据库（如有）
mysqldump -u user -p db_name > backup.sql
```

### 4. 限制上传文件大小
在 `/server/index.js` 中：
```javascript
const upload = multer({ 
  limits: { fileSize: 50 * 1024 * 1024 } // 50MB
});
```

---

## 📊 监控和日志

### 日志位置

| 日志 | 路径 |
|------|------|
| Nginx 访问日志 | `/www/wwwlogs/域名.log` |
| Nginx 错误日志 | `/www/wwwlogs/域名.error.log` |
| PM2 日志 | `pm2 logs` |
| 系统日志 | `/var/log/` |

### 定期检查
```bash
# 每天检查
pm2 status
df -h /home/      # 检查磁盘空间

# 每周检查
tail -100 /www/wwwlogs/域名.log | grep error
du -sh /home/wwwroot/miniadwall/server/uploads/
```

---

## 🔄 更新和维护

### 更新前端
```bash
cd /home/wwwroot/miniadwall
git pull
npm run build
# Nginx 会自动提供新文件，无需重启
```

### 更新后端
```bash
cd /home/wwwroot/miniadwall
git pull
cd server
npm install  # 如果依赖有变化
pm2 restart miniadwall-api
```

### 更新 Node.js 或 PM2
```bash
# 检查当前版本
node -v
pm2 -v

# 通过宝塔面板更新
# 或手动：
nvm install 20.0.0
pm2 restart all
```

---

## 📞 快速参考

### 我的服务器信息（请自行填写）

```
服务器 IP：_______________
SSH 用户：_______________
SSH 密码：_______________
域名：_______________
前端路径：/home/wwwroot/miniadwall/dist
后端路径：/home/wwwroot/miniadwall/server
后端端口：3001
```

### 我的宝塔信息（请自行填写）

```
宝塔地址：_______________
宝塔用户：_______________
宝塔密码：_______________
```

---

## ✅ 部署完成清单

部署后逐一检查：

- [ ] 前端网站在宝塔创建完成
- [ ] Nginx 配置已更新
- [ ] SSL 证书已启用（HTTPS）
- [ ] 后端服务通过 PM2 运行
- [ ] PM2 已配置开机自启
- [ ] 可以访问前端应用
- [ ] 可以调用后端 API
- [ ] 文件上传功能正常
- [ ] 日志没有错误信息
- [ ] 磁盘空间充足（>5GB）

---

## 💡 最后提示

1. **定期备份**：备份上传的文件和数据库
2. **监控日志**：定期检查错误日志，及时发现问题
3. **性能监控**：使用 `pm2 monit` 监控资源使用
4. **版本控制**：使用 Git 管理代码，便于回滚
5. **安全更新**：定期更新依赖和系统补丁

祝你的 Mini 广告墙应用部署顺利！🚀

有问题请查看详细文档：
- `DEPLOY_TO_BAOTA.md` - 详细部署指南
- `DEPLOY_CHECKLIST.md` - 部署检查清单
- `NGINX_CONFIG.md` - Nginx 配置指南
