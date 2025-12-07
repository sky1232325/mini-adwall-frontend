# 🎯 宝塔现有配置修改指南

你已经在宝塔面板创建了网站：
- **域名**：`miniadwall.1232325.xyz`
- **根目录**：`/www/wwwroot/mini-adwall/dist`
- **现有配置**：宝塔自动生成

现在需要添加 **React Router 支持** 和 **API 反向代理**。

---

## ✅ 按步骤操作

### 步骤 1：打开配置文件

1. 登录宝塔面板
2. 左侧菜单 → **网站**
3. 找到 `miniadwall.1232325.xyz` → 点击 **设置**
4. 选择 **配置文件** 标签

你会看到一个大的 Nginx 配置文件。

---

### 步骤 2：定位修改位置

在配置文件中**查找**这一行：
```
#REWRITE-END URL重写规则引用,修改后将导致面板设置的伪静态规则失效
```

在这行之后，有：
```
include /www/server/panel/vhost/rewrite/miniadwall.1232325.xyz.conf;
#REWRITE-END
```

---

### 步骤 3：添加新配置

**在 `#REWRITE-END` 之后、`access_log` 之前**，添加以下代码：

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

---

### 步骤 4：保存配置

1. 点击 **保存** 按钮
2. 宝塔会自动测试 Nginx 配置
3. 配置成功后会自动重启 Nginx

**如果出现红色错误信息**，说明有语法错误，请检查缩进是否正确。

---

## 📝 完整配置文件预览

你的配置文件最终应该大概是这样：

```nginx
server
{
    listen 80;
    server_name miniadwall.1232325.xyz;
    index index.php index.html index.htm default.php default.htm default.html;
    root /www/wwwroot/mini-adwall/dist;
    
    # ... (证书相关配置保持不变) ...
    
    #REWRITE-START URL重写规则引用,修改后将导致面板设置的伪静态规则失效
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

    #静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 30d;
        error_log /dev/null;
        access_log /dev/null;
    }

    # ... (其他宝塔配置如禁止访问文件、错误页等保持不变) ...

    access_log  /www/wwwlogs/miniadwall.1232325.xyz.log;
    error_log  /www/wwwlogs/miniadwall.1232325.xyz.error.log;
}
```

---

## ⚠️ 重要提示

### 不要删除的配置
- ✅ `listen 80;`
- ✅ `server_name miniadwall.1232325.xyz;`
- ✅ `root /www/wwwroot/mini-adwall/dist;`
- ✅ SSL 相关的注释（#CERT-APPLY-CHECK）
- ✅ 错误页配置（#ERROR-PAGE）
- ✅ 禁止访问文件的配置
- ✅ 访问日志和错误日志配置

### 要添加的配置
- ✅ React Router `location /`
- ✅ API 反向代理 `location /api/`
- ✅ 上传文件目录 `location /uploads/`
- ✅ 静态资源缓存

---

## 🔍 修改前后对比

### 修改前（宝塔默认）
```nginx
server {
    listen 80;
    server_name miniadwall.1232325.xyz;
    root /www/wwwroot/mini-adwall/dist;
    
    # 一堆宝塔的默认配置...
    # 没有反向代理
    # 没有 React Router 支持
    
    access_log /www/wwwlogs/miniadwall.1232325.xyz.log;
}
```

### 修改后（添加我们需要的配置）
```nginx
server {
    listen 80;
    server_name miniadwall.1232325.xyz;
    root /www/wwwroot/mini-adwall/dist;
    
    # 一堆宝塔的默认配置（保持不变）...
    
    #REWRITE-END  ← 在这里之后添加

    #React Router 支持 ← 新增
    location / {
        try_files $uri $uri/ /index.html;
    }

    #后端 API 反向代理 ← 新增
    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        # ... 详细配置
    }

    # 其他新增配置...
    
    access_log /www/wwwlogs/miniadwall.1232325.xyz.log;
}
```

---

## ✅ 验证修改成功

修改并保存后，立即验证：

### 1. 前端访问测试
```
在浏览器打开：http://miniadwall.1232325.xyz
应该看到应用正常加载（不是 404）
```

### 2. API 测试
```bash
# 在宝塔终端运行：
curl http://127.0.0.1:3001/api/health

# 应该返回：
# {"status":"ok","message":"Server is running","timestamp":"...","uptime":...}
```

### 3. 通过域名访问 API
```bash
curl http://miniadwall.1232325.xyz/api/health
# 应该返回同样的结果
```

---

## 🛠️ 常见问题

### 问题：保存后显示红色错误

**原因**：Nginx 语法错误

**解决**：
1. 检查你添加的代码的缩进（要用 4 个空格或 1 个 Tab）
2. 检查是否有多余或缺少的 `}`
3. 检查是否有多余的分号

### 问题：前端访问显示 404

**原因**：React Router 配置未生效

**解决**：
```
1. 检查 location / { } 配置是否添加
2. 检查 try_files $uri $uri/ /index.html; 是否存在
3. 重启 Nginx（点击保存会自动重启）
```

### 问题：API 调用返回 502

**原因**：后端未运行或反向代理配置错误

**解决**：
```bash
# 检查后端是否运行
pm2 status

# 检查端口是否监听
netstat -tlnp | grep 3001

# 如果显示 LISTEN，说明后端运行正常
```

### 问题：SSL 证书问题

**原因**：配置干扰了 SSL 申请

**解决**：
```
不要删除这两行：
#CERT-APPLY-CHECK--START
include /www/server/panel/vhost/nginx/well-known/miniadwall.1232325.xyz.conf;
#CERT-APPLY-CHECK--END

这是宝塔用来验证 SSL 的，很重要
```

---

## 📋 快速检查清单

修改完成后，检查以下项目：

- [ ] 打开配置文件
- [ ] 找到 `#REWRITE-END`
- [ ] 在其后添加 4 个 `location` 块
- [ ] 检查缩进和大括号是否正确
- [ ] 点击保存
- [ ] 看到成功提示（绿色）
- [ ] 在浏览器访问域名，页面正常加载
- [ ] 查看浏览器 Network 标签，检查 /api/* 请求

---

## 🚀 下一步

配置修改完成后：

1. **启动后端服务**（如还未启动）
   ```bash
   cd /www/wwwroot/mini-adwall/server
   pm2 start index.js --name "miniadwall-api"
   pm2 save && pm2 startup
   ```

2. **验证整体运行**
   - 访问前端：`http://miniadwall.1232325.xyz`
   - 测试 API：`curl http://miniadwall.1232325.xyz/api/health`

3. **配置 HTTPS**（可选但推荐）
   - 宝塔面板 → 网站 → 域名管理
   - 为 miniadwall.1232325.xyz 申请免费 SSL 证书

---

## 💡 提示

- 如果修改有问题，宝塔会显示错误信息
- 不要删除宝塔自动生成的代码
- 只需要添加我们需要的反向代理配置
- 修改后自动生效，无需手动重启 Nginx

祝部署顺利！有问题参考这个文档的故障排除部分。
