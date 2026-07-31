// 极简 localStorage 封装
// 品牌：HomeMind（M0.5 起；启动时 migrate 一次性把 homeai_ 复制到 homemind_）
const PREFIX = 'homemind_'

export const storage = {
  get (key, fallback = null) {
    try {
      const raw = localStorage.getItem(PREFIX + key)
      if (raw == null) return fallback
      return JSON.parse(raw)
    } catch (e) {
      return fallback
    }
  },
  set (key, value) {
    try {
      localStorage.setItem(PREFIX + key, JSON.stringify(value))
    } catch (e) { /* quota exceeded, ignore */ }
  },
  remove (key) {
    localStorage.removeItem(PREFIX + key)
  },
  clearAll () {
    Object.keys(localStorage)
      .filter(k => k.startsWith(PREFIX))
      .forEach(k => localStorage.removeItem(k))
  }
}