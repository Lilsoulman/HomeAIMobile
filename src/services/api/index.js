// API 调用层：现在走 mockAdapter，未来接 C# 后端时只改这里
import http from '../http'
import { mockAdapter } from '../mock'

// 统一包装：先用 mock 拦截，失败再回落到真实 http
async function call (config) {
  try {
    const res = await mockAdapter(config)
    return res.data
  } catch (e) {
    // 真实后端未启用时直接拒绝，不发请求
    throw e
  }
}

export const todoApi = {
  list: () => call({ url: '/todos', method: 'GET' }),
  create: (body) => call({ url: '/todos', method: 'POST', data: body }),
  update: (id, body) => call({ url: `/todos/${id}`, method: 'PUT', data: body }),
  remove: (id) => call({ url: `/todos/${id}`, method: 'DELETE' })
}

export const calendarApi = {
  list: () => call({ url: '/calendar/events', method: 'GET' }),
  create: (body) => call({ url: '/calendar/events', method: 'POST', data: body }),
  update: (id, body) => call({ url: `/calendar/events/${id}`, method: 'PUT', data: body }),
  remove: (id) => call({ url: `/calendar/events/${id}`, method: 'DELETE' })
}

export const weatherApi = {
  get: () => call({ url: '/weather', method: 'GET' })
}

export const authApi = {
  login: (payload) => http.post('/auth/login', payload),
  register: (payload) => http.post('/auth/register', payload),
  me: () => http.get('/auth/me')
}
