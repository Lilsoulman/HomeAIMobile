// 一次性迁移：扫所有 homeai_* key → 复制到 homemind_* 后删除
// 幂等；新装/已迁移都不会报错
const OLD = 'homeai_'
const NEW = 'homemind_'

export function migrateLocalStorage () {
  if (typeof localStorage === 'undefined') return
  const toRemove = []
  for (let i = 0; i < localStorage.length; i++) {
    const k = localStorage.key(i)
    if (k && k.startsWith(OLD)) {
      const nk = NEW + k.slice(OLD.length)
      const v = localStorage.getItem(k)
      if (v != null && localStorage.getItem(nk) == null) {
        try { localStorage.setItem(nk, v) } catch (e) { /* quota */ }
      }
      toRemove.push(k)
    }
  }
  toRemove.forEach(k => localStorage.removeItem(k))
}
