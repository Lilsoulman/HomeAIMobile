// 环境变量读取：Vue CLI 5 用 VUE_APP_ 前缀
// .env.development / .env.production 中定义 VUE_APP_USE_MOCK=true|false
export function getEnv (key, fallback) {
  if (typeof process !== 'undefined' && process.env && process.env[key] !== undefined) {
    return process.env[key]
  }
  return fallback
}

export const USE_MOCK = String(getEnv('VUE_APP_USE_MOCK', 'true')) === 'true'

export const API_BASE = getEnv('VUE_APP_API_BASE', '/api')
