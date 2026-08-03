// Todos 模块 mock：list / get / create / update / remove + subtasks
// 与旧 services/mock/todos.js 字段一致，避免改 store
import { ok, fail } from './response'

const now = Date.now()
const oneDay = 86400000
let store = [
  { id: 't1', seq: 1, title: '完成季度报告', type: 'work', priority: 'high', color: '', done: false, dueDate: now + 4 * 3600 * 1000, remindAt: null, repeat: 'none', parentId: null, tags: ['报告'], subtasks: [], pinned: true, createdAt: now - 86400000, updatedAt: now - 3600000, completedAt: null },
  { id: 't2', seq: 2, title: '整理周会纪要', type: 'work', priority: 'mid', color: '', done: false, dueDate: now + 86400000, remindAt: null, repeat: 'none', parentId: null, tags: [], subtasks: [{ id: 's1', text: '录屏整理', done: true }, { id: 's2', text: '关键决策汇总', done: false }], pinned: false, createdAt: now - 2 * 86400000, updatedAt: now - 86400000, completedAt: null },
  { id: 't3', seq: 3, title: '买菜', type: 'life', priority: 'low', color: '#10b981', done: false, dueDate: now + 2 * 86400000, remindAt: null, repeat: 'none', parentId: null, tags: [], subtasks: [], pinned: false, createdAt: now - 3 * 86400000, updatedAt: now - 3 * 86400000, completedAt: null },
  { id: 't4', seq: 4, title: '复盘本月', type: 'work', priority: 'mid', color: '', done: false, dueDate: now - 86400000, remindAt: null, repeat: 'none', parentId: null, tags: [], subtasks: [], pinned: false, createdAt: now - 5 * 86400000, updatedAt: now - 86400000, completedAt: null },
  { id: 't5', seq: 5, title: '运动 30 分钟', type: 'life', priority: 'low', color: '', done: true, dueDate: now - 86400000, remindAt: null, repeat: 'daily', parentId: null, tags: [], subtasks: [], pinned: false, createdAt: now - 7 * 86400000, updatedAt: now - 86400000, completedAt: now - 86400000 },
  { id: 't6', seq: 6, title: '阅读《代码大全》', type: 'study', priority: 'low', color: '', done: false, dueDate: null, remindAt: null, repeat: 'none', parentId: null, tags: ['书'], subtasks: [], pinned: false, createdAt: now - 86400000, updatedAt: now - 86400000, completedAt: null },
  { id: 't7', seq: 7, title: '回复客户邮件', type: 'work', priority: 'high', color: '', done: false, dueDate: now - 3 * 3600 * 1000, remindAt: null, repeat: 'none', parentId: null, tags: [], subtasks: [], pinned: false, createdAt: now - 2 * 86400000, updatedAt: now - 3 * 3600000, completedAt: null },
  { id: 't8', seq: 8, title: '团队周报', type: 'work', priority: 'mid', color: '', done: false, dueDate: now + 3 * 86400000, remindAt: null, repeat: 'weekly', parentId: null, tags: [], subtasks: [], pinned: false, createdAt: now - 6 * 86400000, updatedAt: now - 86400000, completedAt: null }
]
let seq = store.length + 1

export function registerTodos (mock) {
  // 列表：支持 ?status=&type= 简单过滤
  mock.onGet('/todos').reply(config => {
    const params = config.params || {}
    let list = store.slice()
    if (params.status === 'pending') list = list.filter(t => !t.done)
    if (params.status === 'completed') list = list.filter(t => t.done)
    if (params.type && params.type !== 'all') list = list.filter(t => t.type === params.type)
    return [200, ok(list)]
  })

  // 详情
  mock.onGet(/\/todos\/[A-Za-z0-9_-]+$/).reply(config => {
    const id = config.url.split('/').pop()
    const t = store.find(x => x.id === id)
    if (!t) return [404, fail(404, 'not found')]
    return [200, ok(t)]
  })

  // 新建
  mock.onPost('/todos').reply(config => {
    const body = typeof config.data === 'string' ? JSON.parse(config.data || '{}') : (config.data || {})
    const todo = {
      id: 't' + Date.now(),
      seq: seq++,
      title: body.title || '新待办',
      type: body.type || 'other',
      priority: body.priority || 'low',
      color: body.color || '',
      done: false,
      dueDate: body.dueDate || null,
      remindAt: null,
      repeat: 'none',
      parentId: null,
      tags: [],
      subtasks: [],
      pinned: false,
      createdAt: Date.now(),
      updatedAt: Date.now(),
      completedAt: null
    }
    store.push(todo)
    return [200, ok(todo)]
  })

  // 更新
  mock.onPut(/\/todos\/[A-Za-z0-9_-]+$/).reply(config => {
    const id = config.url.split('/').pop()
    const i = store.findIndex(t => t.id === id)
    if (i < 0) return [404, fail(404, 'not found')]
    const body = typeof config.data === 'string' ? JSON.parse(config.data || '{}') : (config.data || {})
    store[i] = { ...store[i], ...body, updatedAt: Date.now() }
    if (body.done !== undefined) {
      store[i].completedAt = body.done ? Date.now() : null
    }
    return [200, ok(store[i])]
  })

  // 删除
  mock.onDelete(/\/todos\/[A-Za-z0-9_-]+$/).reply(config => {
    const id = config.url.split('/').pop()
    const before = store.length
    store = store.filter(t => t.id !== id)
    if (store.length === before) return [404, fail(404, 'not found')]
    return [200, ok({ id })]
  })

  // 子任务：增
  mock.onPost(/\/todos\/[A-Za-z0-9_-]+\/subtasks$/).reply(config => {
    const id = config.url.split('/')[2]
    const t = store.find(x => x.id === id)
    if (!t) return [404, fail(404, 'todo not found')]
    const body = typeof config.data === 'string' ? JSON.parse(config.data || '{}') : (config.data || {})
    const sub = { id: 's' + Date.now(), text: body.text || '子任务', done: false }
    t.subtasks = Array.isArray(t.subtasks) ? t.subtasks : []
    t.subtasks.push(sub)
    t.updatedAt = Date.now()
    return [200, ok(sub)]
  })
}
