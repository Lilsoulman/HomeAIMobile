import { todoApi } from '@/services/api'

const PRIORITY_RANK = { high: 3, mid: 2, low: 1 }

const state = () => ({
  todos: [],
  loaded: false
})

const mutations = {
  HYDRATE (state, payload) {
    state.todos = payload.todos || []
    state.loaded = !!payload.loaded
  },
  SET_TODOS (state, list) { state.todos = list; state.loaded = true },
  ADD_TODO (state, todo) { state.todos.unshift(todo) },
  UPDATE_TODO (state, todo) {
    const i = state.todos.findIndex(t => t.id === todo.id)
    if (i >= 0) state.todos.splice(i, 1, { ...state.todos[i], ...todo })
  },
  REMOVE_TODO (state, id) {
    state.todos = state.todos.filter(t => t.id !== id)
  }
}

const actions = {
  async load ({ commit, state }) {
    if (state.loaded) return
    const res = await todoApi.list()
    commit('SET_TODOS', res.data || res)
  },
  async add ({ commit }, body) {
    const res = await todoApi.create(body)
    const todo = res.data || res
    commit('ADD_TODO', todo)
    return todo
  },
  async toggle ({ commit, state }, id) {
    const t = state.todos.find(x => x.id === id)
    if (!t) return
    const next = { ...t, done: !t.done, completedAt: !t.done ? Date.now() : null }
    const res = await todoApi.update(id, { done: next.done, completedAt: next.completedAt })
    commit('UPDATE_TODO', res.data || res)
  }
}

const getters = {
  pendingCount: state => state.todos.filter(t => !t.done).length,
  doneCount: state => state.todos.filter(t => t.done).length,
  todayCount: state => {
    const start = new Date(); start.setHours(0, 0, 0, 0)
    const end = new Date(); end.setHours(23, 59, 59, 999)
    return state.todos.filter(t => t.dueDate && t.dueDate >= start.getTime() && t.dueDate <= end.getTime() && !t.done).length
  },
  overdueCount: state => {
    const now = Date.now()
    return state.todos.filter(t => !t.done && t.dueDate && t.dueDate < now).length
  },
  // 复刻 TabFlow todo.js:2221-2230 排序
  homeList: state => {
    const topLevelPending = state.todos.filter(t => !t.parentId && !t.done)
    const completedWithSubs = state.todos.filter(t => !t.parentId && t.done && state.todos.some(s => s.parentId === t.id && !s.done))
    return [...topLevelPending, ...completedWithSubs]
      .sort((a, b) => {
        if (a.done !== b.done) return a.done ? 1 : -1
        if (a.pinned !== b.pinned) return a.pinned ? -1 : 1
        return (PRIORITY_RANK[b.priority] || 0) - (PRIORITY_RANK[a.priority] || 0)
      })
      .slice(0, 6)
  }
}

export default { namespaced: true, state, mutations, actions, getters }
