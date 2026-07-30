// 日历事件 mock
const today = new Date()
const year = today.getFullYear()
const month = today.getMonth()
const dayOf = (offset) => {
  const d = new Date(year, month, today.getDate() + offset)
  d.setHours(10, 0, 0, 0)
  return d.getTime()
}
let store = [
  { id: 'e1', title: '周会', date: dayOf(0), duration: 60, type: 'work', color: '#6366f1', allDay: false, location: '会议室 A', source: 'local' },
  { id: 'e2', title: '产品评审', date: dayOf(0) + 4 * 3600000, duration: 90, type: 'work', color: '#a855f7', allDay: false, location: '线上', source: 'local' },
  { id: 'e3', title: '瑜伽课', date: dayOf(1) + 8 * 3600000, duration: 60, type: 'life', color: '#10b981', allDay: false, source: 'local' },
  { id: 'e4', title: '提交季度报告', date: dayOf(2), duration: 0, type: 'work', color: '#ef4444', allDay: true, source: 'todo' },
  { id: 'e5', title: '妈妈生日', date: dayOf(4), duration: 0, type: 'life', color: '#ec4899', allDay: true, source: 'local' },
  { id: 'e6', title: '团建', date: dayOf(6) + 6 * 3600000, duration: 180, type: 'work', color: '#f59e0b', allDay: false, source: 'local' }
]

export const mockCalendar = {
  list () { return { code: 0, data: store } },
  get (id) { return { code: 0, data: store.find(e => e.id === id) } },
  create (body) {
    const ev = { id: 'e' + Date.now(), source: 'local', ...body }
    store.push(ev)
    return { code: 0, data: ev }
  },
  update (id, body) {
    const i = store.findIndex(e => e.id === id)
    if (i < 0) return { code: 404, msg: 'not found' }
    store[i] = { ...store[i], ...body }
    return { code: 0, data: store[i] }
  },
  remove (id) {
    store = store.filter(e => e.id !== id)
    return { code: 0, data: { id } }
  }
}
