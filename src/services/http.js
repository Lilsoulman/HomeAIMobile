// axios 实例 + JWT 拦截器 + 统一响应解包
// 用法：main.js 中 import { setupHttp } 并调一次，启用 mock 拦截
import axios from 'axios'
import { storage } from '@/utils/storage'
import { API_BASE, USE_MOCK } from '@/utils/env'
import { setupMock } from '@/services/mock'

const http = axios.create({
  baseURL: API_BASE,
  timeout: 10000
})

http.interceptors.request.use(cfg => {
  const token = storage.get('user_token')
  if (token) cfg.headers.Authorization = `Bearer ${token}`
  return cfg
})

http.interceptors.response.use(
  res => {
    const data = res.data
    // 统一解包 { code, msg, data }，无包装则原样返回
    if (data && typeof data === 'object' && 'code' in data) {
      if (data.code !== 0 && data.code !== 200) {
        return Promise.reject(new Error(data.msg || 'Request failed'))
      }
      return data.data
    }
    return data
  },
  err => Promise.reject(err)
)

let inited = false
export function setupHttp () {
  if (inited) return http
  inited = true
  if (USE_MOCK) {
    setupMock(http)
  }
  return http
}

export default http
