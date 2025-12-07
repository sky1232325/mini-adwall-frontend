# Mini广告墙 - 宝塔部署快速清单

## 📝 部署前检查清单

### 本地准备（你的电脑上）

- [ ] 项目已构建：运行 `npm run build` 完成
- [ ] dist 文件夹生成成功
- [ ] server/index.js 文件存在
- [ ] server/package.json 配置正确

**验证命令**：
```powershell
# 在 d:\VS code\miniAdWall_rebuild 目录
dir dist          # 应该看到 index.html 等文件
dir server        # 应该看到 index.js 和 package.json
```

---

### 服务器准备（宝塔面板）

- [ ] Node.js v16+ 已安装
- [ ] PM2 已安装或准备安装
- [ ] Nginx 已运行
- [ ] SSL 证书已配置（或准备配置）

**宝塔中验证**：
1. 进入 **软件管理** → 检查 Node.js 版本
2. 进入 **应用商店** → 搜索 PM2 并确认状态
3. 进入 **网站** → Nginx 应该在运行

---

## 🚀 快速部署流程（3步）

### 步骤 1：上传项目到服务器

**方案 A：使用 Git（推荐，更新方便）**

通过宝塔面板的终端或 SSH 执行：
```bash
cd /home/wwwroot
git clone https://github.com/sky1232325/mini-adwall.git miniadwall
cd miniadwall
npm install
cd server && npm install && cd ..
npm run build
```

**方案 B：通过宝塔文件管理上传**

1. 在宝塔面板 → **文件** 菜单
2. 进入 `/home/wwwroot/` 目录
3. 上传整个项目文件夹
4. 通过终端运行安装命令

---

### 步骤 2：配置前端网站

在宝塔面板执行：

1. **创建网站**
   - 网站 → 添加站点
   - 域名：`adwall.example.com`
   - 根目录：`/home/wwwroot/miniadwall/dist`
   - PHP 版本：纯静态
   - SSL：勾选（使用 Let's Encrypt 免费证书）

2. **修改 Nginx 配置**
   - 网站设置 → 配置文件
   - **重要**：宝塔会生成很多配置代码，不要删除！
   - 在 `#REWRITE-END` 之后、`access_log` 之前，**添加以下代码**：

```nginx
    #React Router 支持
    location / {
        try_files $uri $uri/ /index.html;
    }

    #后端 API 反向代理
    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    #上传文件目录
    location /uploads/ {
        alias /www/wwwroot/mini-adwall/server/uploads/;
        expires 7d;
    }

    #静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 30d;
        error_log /dev/null;
        access_log /dev/null;
    }
```

   - 保存并重启 Nginx

---

### 步骤 3：启动后端服务

通过宝塔终端或 SSH 执行：

```bash
# 进入后端目录
cd /home/wwwroot/miniadwall/server

# 使用 PM2 启动
pm2 start index.js --name "miniadwall-api" --instances 2

# 保存 PM2 配置（开机自启）
pm2 save
pm2 startup

# 验证服务运行
pm2 status
pm2 logs miniadwall-api
```

---

## ✅ 部署验证

部署完成后，执行以下测试：

### 1. 前端访问测试
```
在浏览器访问：https://你的域名.com
应该看到 Mini 广告墙应用加载
```

### 2. 后端 API 测试
```bash
# 通过宝塔终端或 SSH
curl http://127.0.0.1:3001/api/health
# 应该返回：{"status":"ok","message":"Server is running"}
```

### 3. 前端调用后端测试
```bash
# 打开浏览器开发者工具（F12）
# 检查 Network 标签
# 访问应用的任何需要调用 API 的功能
# 确保请求能成功（状态码 200）
```

### 4. 日志检查
```bash
# 检查后端日志
pm2 logs miniadwall-api

# 检查 Nginx 错误
tail -f /www/wwwlogs/你的域名.log

# 查看系统资源占用
pm2 monit
```

---

## 🔧 常见问题快速修复

### 问题：前端显示"Cannot GET /"

**原因**：Nginx 配置错误或静态文件路径不对
**修复**：
```bash
# 检查静态文件是否存在
ls -la /home/wwwroot/miniadwall/dist/

# 重新部署前端
cd /home/wwwroot/miniadwall
npm run build

# 重启 Nginx
systemctl restart nginx
```

### 问题：API 调用失败，显示 502 Bad Gateway

**原因**：后端未运行或反向代理配置错误
**修复**：
```bash
# 检查后端是否运行
pm2 status

# 检查端口是否监听
netstat -tlnp | grep 3001

# 重启后端
pm2 restart miniadwall-api

# 检查 Nginx 配置
nginx -t
systemctl restart nginx
```

### 问题：样式文件加载失败或 JS 报错

**原因**：构建文件有问题
**修复**：
```bash
# 重新构建
cd /home/wwwroot/miniadwall
npm run build

# 清空浏览器缓存后刷新（Ctrl+Shift+Delete）
```

### 问题：文件上传不工作

**原因**：上传目录权限不足
**修复**：
```bash
# 设置上传目录权限
chmod -R 777 /home/wwwroot/miniadwall/server/uploads
```

---

## 📊 监控和维护

### 定期检查
```bash
# 每天检查服务状态
pm2 status

# 每周检查日志
pm2 logs miniadwall-api --lines 500 | grep -i error

# 检查磁盘空间
df -h /home/wwwroot/
```

### 更新应用
```bash
# 更新前端
cd /home/wwwroot/miniadwall
git pull
npm run build
# 不需要重启，自动更新

# 更新后端
cd /home/wwwroot/miniadwall
git pull
cd server && npm install && cd ..
pm2 restart miniadwall-api
```

---

## 🎯 总结

| 组件 | 位置 | 启动方式 |
|------|------|---------|
| 前端 | `/home/wwwroot/miniadwall/dist` | Nginx 静态服务 |
| 后端 | `/home/wwwroot/miniadwall/server` | PM2 (Node.js) |
| API 反向代理 | Nginx 配置 | 通过 `/api/*` 路由到 :3001 |

---

## 💡 提示

- 保持 git 仓库最新：定期运行 `git pull`
- 监控日志：`pm2 logs miniadwall-api --lines 50 --follow`
- 定期备份上传文件：`tar -czf uploads-backup.tar.gz /home/wwwroot/miniadwall/server/uploads`
- 设置日志轮转防止日志文件过大：`pm2 install pm2-logrotate`

祝部署顺利！如有问题，参考详细指南 `DEPLOY_TO_BAOTA.md`
