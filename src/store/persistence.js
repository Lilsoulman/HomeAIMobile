// 简易持久化：把指定模块的 state 同步到 localStorage
import { storage } from '@/utils/storage'

const PERSIST_KEYS = {
  settings: 'settings',
  todos: 'todos',
  calendar: 'calendar',
  user: 'user'
}

export const persistence = {
  hydrate (store) {
    Object.entries(PERSIST_KEYS).forEach(([module, key]) => {
      const data = storage.get(key)
      if (data) store.commit(`${module}/HYDRATE`, data)
    })
  },
  install (store) {
    store.subscribe((mutation, state) => {
      const m = mutation.type.split('/')[0]
      if (PERSIST_KEYS[m]) {
        storage.set(PERSIST_KEYS[m], state[m])
      }
    })
  }
}
