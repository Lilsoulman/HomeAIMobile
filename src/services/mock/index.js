// 首版假后端：拦截 /api/* 请求并返回内存数据
// 后续接 C# 后端时，删除本文件、修改 src/services/api/* 走真实地址即可
import { mockTodos } from './todos'
import { mockCalendar } from './calendar'
import { mockWeather } from './weather'

// 路由表
const routes = [
  { match: /^\/todos(?:\/(\d+))?$/, methods: ['GET', 'POST', 'PUT', 'DELETE'], handler: mockTodos },
  { match: /^\/calendar\/events(?:\/(\d+))?$/, methods: ['GET', 'POST', 'PUT', 'DELETE'], handler: mockCalendar },
  { match: /^\/weather$/, methods: ['GET'], handler: mockWeather }
]

export function mockAdapter (config) {
  const path = (config.url || '').replace(/^\/api/, '')
  const method = (config.method || 'get').toUpperCase()
  for (const r of routes) {
    const m = path.match(r.match)
    if (m && r.methods.includes(method)) {
      const id = m[1] || null
      const body = typeof config.data === 'string' ? safeParse(config.data) : config.data
      const ctx = { method, id, body, query: config.params }
      
      // handler 是对象时，根据 method 调用对应方法
      if (typeof r.handler === 'object') {
        switch (method) {
          case 'GET':
            return Promise.resolve({ status: 200, data: id ? r.handler.get(id) : r.handler.list(ctx) })
          case 'POST':
            return Promise.resolve({ status: 200, data: r.handler.create(body) })
          case 'PUT':
            return Promise.resolve({ status: 200, data: r.handler.update(id, body) })
          case 'DELETE':
            return Promise.resolve({ status: 200, data: r.handler.remove(id) })
          default:
            return Promise.reject(new Error('Mock unsupported method: ' + method))
        }
      }
      
      // handler 是函数时（兼容旧写法）
      return Promise.resolve({ status: 200, data: r.handler(ctx) })
    }
  }
  return Promise.reject(new Error('Mock 404: ' + path))
}

function safeParse (s) { try { return JSON.parse(s) } catch (e) { return {} } }