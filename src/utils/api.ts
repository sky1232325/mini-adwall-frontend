/**
 * API 配置文件
 * 在前端中使用此配置与后端通信
 */

// 根据环境设置 API 基地址
const API_BASE_URL = import.meta.env.MODE === 'production'
  ? '' // 生产环境：使用相同域名（通过 Nginx 反向代理到 /api/）
  : 'http://localhost:3001'; // 开发环境：本地后端地址

// API 端点定义
export const API_ENDPOINTS = {
  HEALTH: '/api/health',
  UPLOAD: '/api/upload',
  ADS: '/api/ads',
};

/**
 * 发起 API 请求
 * @param {string} endpoint - API 端点
 * @param {object} options - fetch 选项
 * @returns {Promise}
 */
export async function apiCall(
  endpoint: string,
  options: RequestInit = {}
) {
  const url = `${API_BASE_URL}${endpoint}`;
  
  const defaultOptions = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const response = await fetch(url, {
    ...defaultOptions,
    ...options,
    headers: {
      ...defaultOptions.headers,
      ...(options.headers as Record<string, string>),
    },
  });

  if (!response.ok) {
    const error = new Error(`API Error: ${response.status}`) as Error & { status: number };
    error.status = response.status;
    throw error;
  }

  return response.json();
}

/**
 * 上传文件
 * @param {File} file - 文件对象
 * @returns {Promise}
 */
export async function uploadFile(file: File) {
  const formData = new FormData();
  formData.append('file', file);

  const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.UPLOAD}`, {
    method: 'POST',
    body: formData,
  });

  if (!response.ok) {
    throw new Error(`Upload failed: ${response.status}`);
  }

  return response.json();
}

/**
 * 获取广告列表
 * @returns {Promise}
 */
export async function getAds() {
  return apiCall(API_ENDPOINTS.ADS);
}

/**
 * 健康检查
 * @returns {Promise}
 */
export async function healthCheck() {
  return apiCall(API_ENDPOINTS.HEALTH);
}

export default {
  API_BASE_URL,
  API_ENDPOINTS,
  apiCall,
  uploadFile,
  getAds,
  healthCheck,
};
