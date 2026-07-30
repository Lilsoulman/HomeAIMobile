// 极简 localStorage 封装
const PREFIX = 'homeai_'

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
