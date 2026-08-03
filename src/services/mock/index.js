// Mock 入口：按 VUE_APP_USE_MOCK 决定是否挂载
// 用法：main.js 中 setupHttp() → 内部调 setupMock(http)
import MockAdapter from 'axios-mock-adapter'
import { USE_MOCK } from '@/utils/env'
import { registerAuth } from './auth.mock'
import { registerTodos } from './todos.mock'

export function setupMock (httpInstance) {
  if (!USE_MOCK) return
  const mock = new MockAdapter(httpInstance, { delayResponse: 120 })
  registerAuth(mock)
  registerTodos(mock)
  // 第 2 批：registerCalendar / registerSkills / registerAi / registerWeather / registerAttachments
  if (typeof window !== 'undefined') {
    // eslint-disable-next-line no-console
    console.info('[HomeMind] axios-mock-adapter 已挂载（VUE_APP_USE_MOCK=true）')
  }
  return mock
}
