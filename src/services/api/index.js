// API 调用层统一出口
// 现阶段：auth + todos 已实装（第 1 批），其余模块留 stub 供 store 引用
// 真实后端接入时只换 services/http 的 baseURL + VUE_APP_USE_MOCK=false 即可
import { authApi } from './auth'
import { todoApi } from './todos'

// 旧名兼容：保留 calendarApi / weatherApi 名称以免破坏 store/calendar.js 等已有引用
// 第 2 批将替换为真实模块
const calendarApi = {
  list: () => Promise.reject(new Error('calendarApi.list 尚未实装（第 2 批）')),
  create: () => Promise.reject(new Error('calendarApi.create 尚未实装（第 2 批）')),
  update: () => Promise.reject(new Error('calendarApi.update 尚未实装（第 2 批）')),
  remove: () => Promise.reject(new Error('calendarApi.remove 尚未实装（第 2 批）'))
}

const weatherApi = {
  get: () => Promise.reject(new Error('weatherApi.get 尚未实装（第 2 批）'))
}

export { authApi, todoApi, calendarApi, weatherApi }

export default { authApi, todoApi, calendarApi, weatherApi }
