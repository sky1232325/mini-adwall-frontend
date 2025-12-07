# Nginx 配置示例 - 在宝塔面板中使用

## 场景 1：简单配置（推荐新手）

将以下内容复制到 **网站设置 → 配置文件** 中，替换整个配置文件：

```nginx
# ========================================
# Mini广告墙 - 简单 Nginx 配置
# ========================================

server {
    # HTTPS 配置（由宝塔自动生成，保留原样）
    listen 443 ssl http2;
    server_name adwall.example.com;
    
    # SSL 证书路径（宝塔自动配置，保留）
    ssl_certificate /www/server/nginx/conf/ssl/adwall.example.com/fullchain.pem;
    ssl_certificate_key /www/server/nginx/conf/ssl/adwall.example.com/privkey.pem;
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # 根目录（指向前端构建输出）
    root /home/wwwroot/miniadwall/dist;
    index index.html;
    
    # 日志
    access_log /www/wwwlogs/adwall.example.com.log;
    error_log /www/wwwlogs/adwall.example.com.error.log;
    
    # ========== 前端路由配置 ==========
    location / {
        # React Router History 模式支持
        try_files $uri $uri/ /index.html;
        
        # 禁用缓存 HTML
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # ========== API 反向代理 ==========
    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        
        # 传递请求头
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "upgrade";
        proxy_set_header Upgrade $http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # ========== 静态资源缓存 ==========
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # ========== 禁止访问某些文件 ==========
    location ~ /\. {
        deny all;
    }
    
    # HTTP 重定向到 HTTPS（宝塔可能自动配置）
}

# HTTP to HTTPS 重定向
server {
    listen 80;
    server_name adwall.example.com;
    rewrite ^(.*) https://$server_name$1 permanent;
}
```

---

## 场景 2：高级配置（性能优化）

```nginx
# ========================================
# Mini广告墙 - 高级 Nginx 配置
# ========================================

# 上游服务器定义
upstream backend {
    server 127.0.0.1:3001;
    keepalive 32;
}

server {
    listen 443 ssl http2;
    server_name adwall.example.com www.adwall.example.com;
    
    # SSL 配置
    ssl_certificate /www/server/nginx/conf/ssl/adwall.example.com/fullchain.pem;
    ssl_certificate_key /www/server/nginx/conf/ssl/adwall.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;
    
    # 根目录
    root /home/wwwroot/miniadwall/dist;
    index index.html;
    
    # 日志
    access_log /www/wwwlogs/adwall.example.com.log;
    error_log /www/wwwlogs/adwall.example.com.error.log;
    
    # ========== 前端路由 ==========
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    # ========== API 代理 ==========
    location /api/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        
        # 请求头
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        
        # 缓冲
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        
        # 超时
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # ========== 上传文件 ==========
    location /uploads/ {
        alias /home/wwwroot/miniadwall/server/uploads/;
        expires 7d;
        add_header Cache-Control "public";
    }
    
    # ========== 静态资源 ==========
    location ~* \.(js|css)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    location ~* \.(png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 7d;
        add_header Cache-Control "public";
    }
    
    # ========== 隐藏敏感文件 ==========
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.git {
        deny all;
    }
    
    # ========== 安全头 ==========
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}

# HTTP 重定向
server {
    listen 80;
    server_name adwall.example.com www.adwall.example.com;
    rewrite ^(.*) https://$server_name$1 permanent;
}
```

---

## 如何在宝塔中应用配置

### 方法 1：通过宝塔面板 UI（推荐）

1. 登录宝塔面板
2. 左侧菜单 → **网站**
3. 找到你的网站 → 点击**设置**
4. 选择标签 **配置文件**
5. 将上述配置复制到编辑器
6. 修改 `server_name` 为你的实际域名
7. 修改 `root` 和 `ssl_certificate` 路径为实际路径
8. 点击**保存**
9. 系统会自动测试配置并重启 Nginx

### 方法 2：通过 SSH 编辑

```bash
# 编辑网站配置文件
sudo nano /www/server/nginx/conf.d/adwall.example.com.conf

# 或使用 vi 编辑器
sudo vi /www/server/nginx/conf.d/adwall.example.com.conf

# 修改后测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

---

## 常见配置问题

### 问题 1：SSL 证书路径找不到

**解决**：
```bash
# 查看宝塔配置的证书路径
ls -la /www/server/nginx/conf/ssl/
```

### 问题 2：API 调用返回 504

**原因**：后端未运行或超时
**解决**：
```bash
# 检查后端服务
pm2 status

# 增加代理超时时间（在配置中修改）
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;
```

### 问题 3：静态文件 404 Not Found

**原因**：文件路径不对
**解决**：
```bash
# 检查文件是否存在
ls -la /home/wwwroot/miniadwall/dist/

# 确认权限
chmod -R 755 /home/wwwroot/miniadwall/dist/
```

---

## 性能优化建议

1. **启用 Gzip 压缩**：减小传输大小
2. **设置缓存头**：让浏览器缓存静态文件
3. **使用 HTTP/2**：提升多文件加载速度
4. **限制 proxy_buffer**：防止内存过度使用
5. **添加安全头**：提升网站安全性

---

## 测试配置

部署后测试：

```bash
# 1. 测试 HTML 加载
curl -I https://adwall.example.com/

# 2. 测试 API
curl https://adwall.example.com/api/health

# 3. 测试文件上传
curl -F "file=@test.jpg" https://adwall.example.com/api/upload

# 4. 检查日志
tail -f /www/wwwlogs/adwall.example.com.log
```
