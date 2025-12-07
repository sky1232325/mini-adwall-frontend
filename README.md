# Mini广告墙 - 开发说明

面向演示的广告墙项目，提供前后端一体的最小可用实现，重点覆盖：技术选型、架构设计、复杂逻辑与开发细节、运行/部署方法。

**线上落地页**：https://miniadwall.1232325.xyz/

## 技术选型
- 前端：React 19 + TypeScript + Vite 7，UI 采用 Ant Design 6，uuid 生成主键。
- 状态与存储：本地状态 + localStorage 持久化（无远端持久化）。
- 后端：Node.js/Express 5，CORS、body-parser、Multer 上传，环境变量由 dotenv 可选加载。
- 构建/工具：Vite 打包，ESLint 配置已就绪，tsconfig.app/node 负责前端/工具链。

## 目录结构（关键部分）
- `src/` 前端源码
  - `components/AdCard.tsx` 卡片交互（编辑/复制/删除/点击）
  - `components/AdModal.tsx` 新增/编辑/复制弹窗，输出 FormData
  - `components/VideoPlayerModal.tsx` 视频播放弹窗，结束后跳转落地页
  - `utils/ranking.ts` 广告排序逻辑
  - `utils/api.ts` 前端 API 封装（健康检查、上传、广告列表）
  - `types.ts` `Ad` 类型定义
- `server/index.js` Express 服务（/api/health、/api/upload、/api/ads、静态 /uploads）
- `server/.env.example` 环境变量模板
- `public/` 静态资源，`dist/` 为构建输出

## 架构与数据流
- 展示层：栅格卡片 + 弹窗，所有数据在浏览器端管理。
- 排序策略：`score = price + price * clicks * 0.42`，点击越多、出价越高的广告靠前。
- 持久化：`localStorage` 保存广告数组，变更后即时写入并排序。
- 交互流程：
  1) 创建/编辑/复制广告 → 生成 `FormData` → 本地保存为 `Ad` 结构
  2) 点击广告 → 点击数 +1 → 若有视频列表随机播放；无视频则直接新开落地页
  3) 视频播放完成 → 自动跳转落地页
- 后端职责：
  - `/api/health` 健康检查
  - `/api/upload` 单文件上传（字段名 `file`），保存到 `server/uploads`
  - `/api/ads` 示例返回空数据（可对接真实数据源）
  - 静态 `/uploads` 提供上传文件访问

## 复杂/关键逻辑说明
- **排序公式**：`calculateScore = price + price * clicks * 0.42`，在 `sortAdsByScore` 中对广告列表排序。
- **点击播放逻辑**：点击卡片 → 增加点击数并持久化 → 如有视频随机选一个展示 → 关闭或结束后跳转落地页。
- **表单与文件**：`AdModal` 通过 `FormData` 汇总字段与上传文件（字段名 `videos`，当前前端本地保存，不直传后端）。
- **上传接口**：后端 `Multer` 保存文件到 `UPLOAD_DIR`，返回 `url`、`filename` 等元数据。

## 运行与开发
```bash
# 安装依赖
npm install
cd server && npm install && cd ..

# 本地开发（前端 Vite）
npm run dev

# 前端构建
npm run build

# 后端本地启动
cd server
npm start   # 或 node index.js
```

## 环境变量（后端）
复制 `server/.env.example` 为 `.env`，可配置：
- `PORT` 默认 3001
- `HOST` 默认 127.0.0.1
- `CORS_ORIGIN` 允许的前端源，默认 `*`
- `UPLOAD_DIR` 上传目录，默认 `server/uploads`
- `MAX_FILE_SIZE` 上传大小（字节），默认 50MB

## API 约定（后端）
- `GET /api/health` → `{ status, message, timestamp, uptime }`
- `POST /api/upload` → `multipart/form-data`，字段 `file`，返回 `{ url, filename, size }`
- `GET /api/ads` → 示例 `{ success: true, data: [], total: 0 }`

## 部署要点（简版）
- 前端：`npm run build` 后将 `dist/` 部署至静态站点（Nginx 根目录指向 dist，`try_files $uri $uri/ /index.html`）。
- 后端：`cd server && npm install && pm2 start index.js --name miniadwall-api && pm2 save`。
- 反向代理：在前端站点 Nginx 中添加 `/api/` 代理到 `http://127.0.0.1:3001`，`/uploads/` 映射到 `server/uploads`。
- 上传目录：确保 `server/uploads` 可写（如 `chmod -R 755` 或按需提升）。

## 快速问题排查
- `/api/health` 返回 404：确认运行的后端版本为仓库内 `server/index.js`，并已重启 PM2。
- 前端 API 502：检查 Nginx 代理到 3001，`nginx -t` 后重载；确认 PM2 进程在线。
- 上传失败：检查上传目录权限与 `MAX_FILE_SIZE` 限制。

## 版本与分支
- 当前分支：`miniadwall前端`
- 远端：`origin`（主仓库）与 `frontend`（前端仓库），已推送完整代码与文档精简版。
