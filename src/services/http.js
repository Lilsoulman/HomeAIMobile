// axios 实例 + JWT 拦截器。首版用 mock，留好真实后端的接缝
import axios from 'axios'
import { storage } from '@/utils/storage'

const http = axios.create({
  baseURL: '/api',
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

export default http
