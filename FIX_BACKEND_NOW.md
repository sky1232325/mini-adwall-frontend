# 🚨 快速修复：后端版本问题

## 问题诊断

你的测试结果显示：

```
curl http://127.0.0.1:3001/api/health
❌ Cannot GET /api/health
```

这证明：
- ✅ 后端进程在运行（PM2 显示 online）
- ❌ **但运行的是旧版本的代码**（日志显示"服务器上是你修改之前的版本"）

## 🔧 立即修复方案

### 方案 1：用 SCP 快速替换文件（推荐，5 分钟）

**在你的本地 Windows 机器上执行**：

```powershell
# 使用 SCP 从本地上传新的 server/index.js
scp -r "d:\VS code\miniAdWall_rebuild\server" root@iZj6c50bv98266n15s3316Z:/www/wwwroot/mini-adwall/

# 输入密码后，会替换服务器上的文件
```

**然后在服务器上重启**：

```bash
pm2 restart miniadwall-api
pm2 logs miniadwall-api --lines 20
```

---

### 方案 2：如果没有 SCP，用以下命令直接编辑服务器文件

**在你的服务器上执行**：

```bash
# 停止运行的 PM2 进程
pm2 stop miniadwall-api

# 进入服务器目录
cd /www/wwwroot/mini-adwall/server

# 查看当前文件内容
cat index.js

# 备份旧文件
cp index.js index.js.bak

# 使用 nano 编辑
nano index.js
```

然后把下面的完整代码**粘贴替换**整个文件内容：

```javascript
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// 加载环境变量（可选）
try {
  require('dotenv').config();
} catch (e) {
  console.log('dotenv not installed, using default environment variables');
}

const app = express();
const PORT = process.env.PORT || 3001;
const HOST = process.env.HOST || '127.0.0.1';
const CORS_ORIGIN = process.env.CORS_ORIGIN || '*';
const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(__dirname, 'uploads');

console.log(`[${new Date().toISOString()}] Starting server...`);
console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
console.log(`Upload directory: ${UPLOAD_DIR}`);
console.log(`CORS origin: ${CORS_ORIGIN}`);

// 配置 multer 用于文件上传
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
  console.log(`Created upload directory: ${UPLOAD_DIR}`);
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, UPLOAD_DIR);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    const name = path.basename(file.originalname, ext);
    cb(null, name + '-' + uniqueSuffix + ext);
  }
});

const upload = multer({ 
  storage,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE || 52428800) // 50MB default
  }
});

// 中间件
app.use(cors({
  origin: CORS_ORIGIN,
  credentials: true
}));
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));

// 静态文件服务
app.use('/uploads', express.static(UPLOAD_DIR));

// 请求日志中间件
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// ============ API 路由 ============

// 健康检查接口
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Server is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// 上传接口
app.post('/api/upload', upload.single('file'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }
    
    res.json({
      success: true,
      filename: req.file.filename,
      originalName: req.file.originalname,
      size: req.file.size,
      url: `/uploads/${req.file.filename}`,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: 'Upload failed', details: error.message });
  }
});

// 广告接口示例
app.get('/api/ads', (req, res) => {
  res.json({
    success: true,
    data: [],
    total: 0
  });
});

// 404 处理
app.use((req, res) => {
  res.status(404).json({ error: 'Not found', path: req.path });
});

// 错误处理中间件
app.use((err, req, res, next) => {
  console.error(`[ERROR] ${new Date().toISOString()}:`, err);
  res.status(err.status || 500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Unknown error'
  });
});

// ============ 启动服务器 ============
app.listen(PORT, HOST, () => {
  console.log(`✓ Server is running on http://${HOST}:${PORT}`);
  console.log(`✓ API base: http://${HOST}:${PORT}/api`);
  console.log(`✓ Uploads: http://${HOST}:${PORT}/uploads`);
  console.log(`✓ Ready to accept connections...`);
});
```

编辑完后：
- 按 `Ctrl + X`
- 输入 `Y`
- 按 `Enter` 保存

---

### 修复后的验证步骤

**1. 启动后端**

```bash
pm2 start index.js --name "miniadwall-api"
```

**2. 查看日志**

```bash
pm2 logs miniadwall-api --lines 20

# 你应该看到：
# ✓ Server is running on http://127.0.0.1:3001
# ✓ API base: http://127.0.0.1:3001/api
# ✓ Uploads: http://127.0.0.1:3001/uploads
# ✓ Ready to accept connections...
```

**3. 测试 API**

```bash
curl http://127.0.0.1:3001/api/health

# 应该返回：
# {"status":"ok","message":"Server is running","timestamp":"...","uptime":...}
```

**4. 通过域名测试**

```bash
curl http://miniadwall.1232325.xyz/api/health

# 应该返回同样的 JSON
```

**5. 在浏览器测试**

打开：`http://miniadwall.1232325.xyz`

按 F12 → Network，刷新页面。你应该看到 API 请求成功返回（状态码 200）。

---

## 为什么会这样？

服务器上的代码可能被以下几种情况覆盖了：

1. **之前的构建/部署** - 可能有自动化脚本覆盖了你的代码
2. **上传过程中出错** - 文件没有完全上传
3. **版本控制** - Git 分支切换导致代码回滚

现在用新代码替换，就可以解决问题。

---

## ✅ 预期结果

修复后，你会看到：

```bash
$ curl http://127.0.0.1:3001/api/health
{"status":"ok","message":"Server is running","timestamp":"2025-12-07T...","uptime":123.45}

$ curl http://miniadwall.1232325.xyz/api/health  
{"status":"ok","message":"Server is running","timestamp":"2025-12-07T...","uptime":123.45}
```

前端也能成功连接到后端！

---

现在选择上面的方案 1 或方案 2 执行修复，告诉我结果！
