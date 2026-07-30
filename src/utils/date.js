// 工具：日期/问候，照搬 TabFlow newtab.js:1075
const ZH = {
  dayNames: ['周日', '周一', '周二', '周三', '周四', '周五', '周六'],
  monthNames: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
  morningGreet: '早上好',
  noonGreet: '下午好',
  eveningGreet: '晚上好',
  lateGreet: '夜深了'
}
const EN = {
  dayNames: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
  monthNames: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  morningGreet: 'Good morning',
  noonGreet: 'Good afternoon',
  eveningGreet: 'Good evening',
  lateGreet: 'Late night'
}

export function getI18n (lang = 'zh') {
  return lang === 'zh' ? ZH : EN
}

export function getGreeting (lang = 'zh') {
  const i = getI18n(lang)
  const h = new Date().getHours()
  if (h < 6) return i.lateGreet
  if (h < 12) return i.morningGreet
  if (h < 18) return i.noonGreet
  return i.eveningGreet
}

export function formatDate (lang = 'zh') {
  const i = getI18n(lang)
  const n = new Date()
  if (lang === 'zh') return `${i.dayNames[n.getDay()]} ${i.monthNames[n.getMonth()]}${n.getDate()}日`
  return `${i.dayNames[n.getDay()]} ${i.monthNames[n.getMonth()]} ${n.getDate()}`
}

export function dateKey (date) {
  const d = date instanceof Date ? date : new Date(date)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

// 计算月份网格（6 行 × 7 列），首列为周日
export function getMonthGrid (year, month) {
  const first = new Date(year, month, 1)
  const startDow = first.getDay()
  const daysInMonth = new Date(year, month + 1, 0).getDate()
  const daysInPrev = new Date(year, month, 0).getDate()

  const cells = []
  // 头部填充（取上月末尾几天）
  for (let i = startDow - 1; i >= 0; i--) {
    const d = new Date(year, month - 1, daysInPrev - i)
    cells.push({ date: d, other: true })
  }
  // 当月
  for (let i = 1; i <= daysInMonth; i++) {
    cells.push({ date: new Date(year, month, i), other: false })
  }
  // 尾部填充到 42 格
  while (cells.length < 42) {
    const last = cells[cells.length - 1].date
    const d = new Date(last)
    d.setDate(d.getDate() + 1)
    cells.push({ date: d, other: true })
  }
  return cells
}

export function isSameDay (a, b) {
  return a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
}
