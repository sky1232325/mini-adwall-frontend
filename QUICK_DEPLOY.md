# 🚀 一句话部署快速指南

## 本地准备（Windows 电脑）

```powershell
cd d:\VS code\miniAdWall_rebuild
npm install
npm run build
cd server && npm install && cd ..
```

## 服务器部署（通过 SSH）

```bash
ssh root@你的服务器IP

# 进入宝塔目录
cd /home/wwwroot

# 克隆项目
git clone https://github.com/sky1232325/mini-adwall.git miniadwall
cd miniadwall

# 安装和构建
npm install && npm run build

# 启动后端
cd server
npm install
pm2 start index.js --name "miniadwall-api"
pm2 save
pm2 startup

# 验证后端运行
pm2 status
```

## 宝塔面板配置

### 1. 你的网站已存在
✅ 根目录：`/www/wwwroot/mini-adwall/dist`  
✅ 域名：`miniadwall.1232325.xyz`

### 2. 修改现有 Nginx 配置

在宝塔面板中：
1. **网站** → 点击你的网站
2. **配置文件** → 找到以下位置
3. 在 `#REWRITE-END` 之后、`access_log` 之前，**添加以下配置**：

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
```

4. **保存** → Nginx 会自动测试并重启

完整的配置文件应该是这样：
```nginx
server
{
    listen 80;
    server_name miniadwall.1232325.xyz;
    index index.php index.html index.htm default.php default.htm default.html;
    root /www/wwwroot/mini-adwall/dist;
    
    # ... (中间的证书申请、扩展等配置保持不变) ...

    #REWRITE-END URL重写规则引用,修改后将导致面板设置的伪静态规则失效
    include /www/server/panel/vhost/rewrite/miniadwall.1232325.xyz.conf;
    #REWRITE-END

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

    # ... (后面的禁止访问、静态资源缓存等配置保持不变) ...

    access_log  /www/wwwlogs/miniadwall.1232325.xyz.log;
    error_log  /www/wwwlogs/miniadwall.1232325.xyz.error.log;
}
```

## 验证部署

```bash
# 1. 前端：在浏览器访问
https://你的域名.com

# 2. 后端 API：执行
curl https://你的域名.com/api/health
```

---

## 常用命令

```bash
# 后端相关
pm2 status                    # 查看运行状态
pm2 logs miniadwall-api      # 查看日志
pm2 restart miniadwall-api   # 重启服务
pm2 delete miniadwall-api    # 删除服务

# Nginx 相关
systemctl restart nginx       # 重启 Nginx
nginx -t                      # 检查配置
tail -f /www/wwwlogs/域名.log # 查看访问日志

# 文件权限
chmod -R 755 /home/wwwroot/miniadwall/dist
chmod -R 777 /home/wwwroot/miniadwall/server/uploads
```

---

## 疑难解答

| 问题 | 解决方法 |
|------|---------|
| 前端 404 | `npm run build` 重新构建 |
| API 502 | `pm2 restart miniadwall-api` 重启后端 |
| 上传文件失败 | `chmod -R 777 server/uploads` 设置权限 |
| CORS 错误 | 检查 Nginx 配置中的反向代理 |

---

## 详细文档

- **DEPLOY_TO_BAOTA.md** - 完整部署指南
- **DEPLOY_CHECKLIST.md** - 部署检查清单
- **NGINX_CONFIG.md** - Nginx 配置详解
- **DEPLOY_SUMMARY.md** - 部署总结参考

---

## 关键信息速查

```
前端地址：https://你的域名.com
后端 API：http://127.0.0.1:3001 (服务器内部)
         https://你的域名.com/api (通过 Nginx 代理)

前端位置：/home/wwwroot/miniadwall/dist
后端位置：/home/wwwroot/miniadwall/server
上传目录：/home/wwwroot/miniadwall/server/uploads

后端进程：miniadwall-api (PM2 管理)
后端端口：3001
```

祝部署顺利！🎉
