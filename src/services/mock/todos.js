// 待办 mock，schema 照搬 TabFlow todo.js:179-187 makeTodo
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

export const mockTodos = {
  list () { return { code: 0, data: store } },
  get (id) { return { code: 0, data: store.find(t => t.id === id) } },
  create (body) {
    const id = 't' + Date.now()
    const todo = {
      id, seq: seq++, title: body.title || '新待办', type: body.type || 'other',
      priority: body.priority || 'low', color: body.color || '',
      done: false, dueDate: body.dueDate || null, remindAt: null, repeat: 'none',
      parentId: null, tags: [], subtasks: [], pinned: false,
      createdAt: Date.now(), updatedAt: Date.now(), completedAt: null
    }
    store.push(todo)
    return { code: 0, data: todo }
  },
  update (id, body) {
    const i = store.findIndex(t => t.id === id)
    if (i < 0) return { code: 404, msg: 'not found' }
    store[i] = { ...store[i], ...body, updatedAt: Date.now() }
    if (body.done !== undefined) {
      store[i].completedAt = body.done ? Date.now() : null
    }
    return { code: 0, data: store[i] }
  },
  remove (id) {
    store = store.filter(t => t.id !== id)
    return { code: 0, data: { id } }
  }
}
