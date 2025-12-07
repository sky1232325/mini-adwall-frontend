# 🔧 前端连接不到后端 - 快速诊断指南

你的后端服务已成功启动（PM2 显示 online），但前端无法连接。让我们逐一检查原因。

---

## 📋 快速诊断清单

### 第 1 步：检查后端是否真正在运行

```bash
# 检查端口是否监听
netstat -tlnp | grep 3001

# 应该看到类似这样的输出：
# tcp        0      0 127.0.0.1:3001          0.0.0.0:*               LISTEN      12345/node
```

**如果没有显示 3001 端口**，说明后端实际没有启动。

---

### 第 2 步：检查后端日志

```bash
# 查看 PM2 日志
pm2 logs miniadwall-api --lines 50

# 查找是否有 ERROR 或启动错误信息
# 正常应该看到：
# [2025-12-07 10:30:15] Server is running on port 3001
# [2025-12-07 10:30:15] API base: http://127.0.0.1:3001/api
```

**如果看到 ERROR**，记下错误信息，可能是：
- 依赖未安装
- 端口被占用
- 配置文件错误

---

### 第 3 步：直接测试后端 API

在服务器上执行：

```bash
# 测试本地连接（服务器内部）
curl http://127.0.0.1:3001/api/health

# 应该返回：
# {"status":"ok","message":"Server is running","timestamp":"...","uptime":...}
```

**如果无法连接**，说明后端服务有问题。

**如果能连接**，继续检查第 4 步。

---

### 第 4 步：检查 Nginx 反向代理配置

你的 Nginx 配置是否正确添加了反向代理？

在宝塔面板检查：
1. 网站 → miniadwall.1232325.xyz
2. 配置文件 → 查找这段代码：

```nginx
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
```

**如果没有这段代码**：
- 参考 BAOTA_CONFIG_GUIDE.md 添加它
- 保存后重启 Nginx

**如果已有这段代码**，继续下一步。

---

### 第 5 步：测试通过 Nginx 的连接

```bash
# 测试通过域名访问 API
curl http://miniadwall.1232325.xyz/api/health

# 应该返回同样的 JSON 结果
```

**如果返回 502 或其他错误**：
- 说明 Nginx 反向代理有问题
- 检查 Nginx 错误日志：`tail -50 /www/wwwlogs/miniadwall.1232325.xyz.error.log`

**如果正常返回**，继续第 6 步。

---

### 第 6 步：检查前端代码

打开浏览器 F12，检查：

1. **Console 标签**
   - 有什么错误信息吗？
   - 记下具体的错误

2. **Network 标签**
   - 刷新页面
   - 查找 `/api/*` 开头的请求
   - 点击该请求，查看：
     - **URL**：显示的完整 URL 是什么？
     - **Status**：状态码是多少？
     - **Response**：返回内容是什么？

3. **常见错误类型**
   - `404`：后端接口不存在
   - `502`：Nginx 无法连接到后端
   - `CORS error`：跨域问题
   - `timeout`：连接超时

---

## 🔍 常见原因和解决方案

### ❌ 问题 1：后端服务未真正启动

**症状**：PM2 显示 online，但无法连接

**原因**：
- 后端程序启动但立即崩溃
- 端口被占用
- 依赖缺失

**解决**：
```bash
# 查看详细日志
pm2 logs miniadwall-api

# 查看是否有错误

# 如果有错误，重新安装依赖
cd /www/wwwroot/mini-adwall/server
npm install

# 重启服务
pm2 restart miniadwall-api

# 检查日志
pm2 logs miniadwall-api --lines 30
```

---

### ❌ 问题 2：Nginx 反向代理未配置

**症状**：浏览器 F12 显示 `/api/*` 请求返回 404

**原因**：
- Nginx 配置中没有 `location /api/` 块
- 配置有语法错误

**解决**：
```bash
# 检查 Nginx 配置
nginx -t

# 如果有语法错误，会显示具体位置

# 在宝塔面板修改配置
# 参考 BAOTA_CONFIG_GUIDE.md 添加反向代理配置

# 修改后重启 Nginx
systemctl restart nginx
```

---

### ❌ 问题 3：Nginx 反向代理配置错误

**症状**：`/api/*` 请求返回 502 Bad Gateway

**原因**：
- `proxy_pass` 地址错误
- 后端服务确实未运行
- 防火墙阻止了连接

**解决**：
```bash
# 检查后端是否运行
pm2 status

# 检查端口监听
netstat -tlnp | grep 3001

# 查看 Nginx 错误日志
tail -50 /www/wwwlogs/miniadwall.1232325.xyz.error.log

# 确保配置中是 http://127.0.0.1:3001
# 不要写成 http://localhost:3001 或其他地址
```

---

### ❌ 问题 4：前端 API 调用地址错误

**症状**：Network 标签显示请求 URL 不对

**原因**：
- 前端代码中 API_BASE_URL 设置错误
- 前端没有正确指向后端

**解决**：
```javascript
// 检查 src/utils/api.ts 中的配置
// 应该是：
const API_BASE_URL = process.env.NODE_ENV === 'production'
  ? ''  // 生产环境：使用相同域名
  : 'http://localhost:3001';  // 开发环境

// 确保请求地址是 /api/* 而不是绝对 URL
// 正确：fetch('/api/health')
// 错误：fetch('http://..../api/health')
```

如果需要修改，重新构建：
```bash
cd /www/wwwroot/mini-adwall
npm run build
```

---

### ❌ 问题 5：CORS 跨域错误

**症状**：浏览器 Console 显示 CORS 错误

**原因**：
- 后端未配置 CORS
- 前端域名与后端域名不匹配

**解决**：
```bash
# 检查后端 server/index.js 中的 CORS 配置
cat /www/wwwroot/mini-adwall/server/index.js | grep -A 5 "cors"

# 应该看到类似：
# app.use(cors({ origin: CORS_ORIGIN }));

# 或者确保 Nginx 反向代理包含了正确的 Header
# proxy_set_header Host $host;
# proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

---

## 🔧 快速修复步骤

### 如果你不确定问题在哪，按这个顺序做：

**步骤 1：重启后端服务**
```bash
cd /www/wwwroot/mini-adwall/server
pm2 restart miniadwall-api
pm2 logs miniadwall-api --lines 30
```

**步骤 2：重启 Nginx**
```bash
nginx -t
systemctl restart nginx
```

**步骤 3：重新构建前端**
```bash
cd /www/wwwroot/mini-adwall
npm run build
```

**步骤 4：清除浏览器缓存**
- 打开浏览器 F12
- 右键刷新按钮 → 选择"清空缓存并硬性重新加载"
- 或按 Ctrl+Shift+Delete 清除缓存

**步骤 5：再次测试**
- 打开页面
- 按 F12，查看 Console 和 Network
- 检查 `/api/*` 请求的状态

---

## 📊 诊断流程图

```
前端连接不到后端
    ↓
[检查 PM2 状态]
    ├─ online → 继续检查
    └─ stopped → 重启 pm2 start index.js
    ↓
[测试本地 API]
    curl http://127.0.0.1:3001/api/health
    ├─ 成功 → 继续检查
    └─ 失败 → 查看 PM2 日志，解决依赖问题
    ↓
[检查 Nginx 配置]
    ├─ 没有反向代理 → 添加配置（BAOTA_CONFIG_GUIDE.md）
    └─ 有反向代理 → 继续检查
    ↓
[测试通过域名的 API]
    curl http://miniadwall.1232325.xyz/api/health
    ├─ 成功 → 问题可能在前端
    └─ 502 → Nginx 配置有问题
    ↓
[检查浏览器 F12]
    ├─ 404 → /api/ 路由未配置
    ├─ 502 → 后端未运行
    ├─ CORS error → CORS 配置问题
    └─ 其他 → 记下错误信息
    ↓
✅ 问题定位成功
```

---

## 🆘 我需要更多帮助

如果按照上面的步骤还是无法解决，请提供以下信息：

1. **PM2 日志最后 30 行**
   ```bash
   pm2 logs miniadwall-api --lines 30
   ```

2. **浏览器 F12 Network 标签中的错误**
   - 截图或说明具体错误

3. **Nginx 错误日志最后 20 行**
   ```bash
   tail -20 /www/wwwlogs/miniadwall.1232325.xyz.error.log
   ```

4. **后端启动后立即运行的命令**
   ```bash
   curl http://127.0.0.1:3001/api/health
   ```
   返回了什么？

有了这些信息，我们可以更准确地定位问题。

---

## 💡 快速参考

### 常用命令

```bash
# PM2 相关
pm2 status                           # 查看进程状态
pm2 logs miniadwall-api             # 查看日志
pm2 logs miniadwall-api --lines 50  # 查看最后 50 行日志
pm2 restart miniadwall-api          # 重启服务
pm2 delete miniadwall-api           # 删除服务

# Nginx 相关
nginx -t                             # 测试 Nginx 配置
systemctl restart nginx             # 重启 Nginx
tail -f /www/wwwlogs/miniadwall.1232325.xyz.error.log  # 实时查看错误日志

# 网络测试
netstat -tlnp | grep 3001           # 检查 3001 端口
curl http://127.0.0.1:3001/api/health               # 测试本地 API
curl http://miniadwall.1232325.xyz/api/health       # 测试通过域名的 API

# 文件检查
ls -la /www/wwwroot/mini-adwall/dist/index.html     # 检查前端文件
cat /www/wwwroot/mini-adwall/server/index.js        # 查看后端代码
```

---

现在按照上面的诊断步骤逐一检查，应该能找到问题所在。

记住：**先检查 PM2 日志，问题通常都在那里！**
