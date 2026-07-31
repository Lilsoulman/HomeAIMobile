import { todoApi } from '@/services/api'

const PRIORITY_RANK = { high: 3, mid: 2, low: 1 }

// 视图模式常量
export const TODO_VIEWS = { KANBAN: 'kanban', LIST: 'list' }
// 时间筛选常量
export const TIME_RANGES = { ALL: 'all', TODAY: 'today', WEEK: 'week', LASTWEEK: 'lastweek', MONTH: 'month', CUSTOM: 'custom' }
// 排序字段
export const SORT_BY = { CREATED: 'createdAt', DUE: 'dueDate', PRIORITY: 'priority' }

const DEFAULT_FILTERS = {
  status: 'all',      // all | pending | completed
  type: 'all',        // all | work | life | study | other
  time: TIME_RANGES.ALL,
  priority: 'all',    // all | high | mid | low
  color: 'all',       // all | #rrggbb
  keyword: '',
  customRange: null   // { from: ts, to: ts } 仅 time === 'custom' 时使用
}

const DEFAULT_SORT = { by: SORT_BY.DUE, dir: 'asc' }

const state = () => ({
  todos: [],
  loaded: false,
  // === M1.1 新增子 state ===
  filters: { ...DEFAULT_FILTERS },
  sort: { ...DEFAULT_SORT },
  selected: [],         // 批量多选 id 列表（M1.5 用，本轮预埋）
  view: TODO_VIEWS.KANBAN  // 'kanban' | 'list'
})

const mutations = {
  HYDRATE (state, payload) {
    state.todos = payload.todos || []
    state.loaded = !!payload.loaded
    if (payload.filters) state.filters = { ...DEFAULT_FILTERS, ...payload.filters }
    if (payload.sort) state.sort = { ...DEFAULT_SORT, ...payload.sort }
    if (Array.isArray(payload.selected)) state.selected = payload.selected.slice()
    if (payload.view === TODO_VIEWS.KANBAN || payload.view === TODO_VIEWS.LIST) {
      state.view = payload.view
    }
  },
  SET_TODOS (state, list) { state.todos = list; state.loaded = true },
  ADD_TODO (state, todo) {
    if (!todo || !todo.id) return
    // 避免重复添加（id 已存在则更新）
    const i = state.todos.findIndex(t => t.id === todo.id)
    if (i >= 0) state.todos.splice(i, 1, { ...state.todos[i], ...todo })
    else state.todos.unshift(todo)
  },
  UPDATE_TODO (state, todo) {
    const i = state.todos.findIndex(t => t.id === todo.id)
    if (i >= 0) state.todos.splice(i, 1, { ...state.todos[i], ...todo })
  },
  REMOVE_TODO (state, id) {
    state.todos = state.todos.filter(t => t.id !== id)
  },
  // === M1.1 mutations ===
  SET_FILTER (state, { key, value }) {
    if (key in state.filters) state.filters[key] = value
  },
  RESET_FILTERS (state) { state.filters = { ...DEFAULT_FILTERS } },
  SET_SORT (state, sort) { state.sort = { ...DEFAULT_SORT, ...sort } },
  SET_VIEW (state, view) {
    if (view === TODO_VIEWS.KANBAN || view === TODO_VIEWS.LIST) state.view = view
  },
  TOGGLE_SELECT (state, id) {
    const i = state.selected.indexOf(id)
    if (i >= 0) state.selected.splice(i, 1)
    else state.selected.push(id)
  },
  CLEAR_SELECT (state) { state.selected = [] }
}

// ---- helpers（纯函数）----
function inTimeRange (dueDate, range, customRange) {
  if (!range || range === TIME_RANGES.ALL) return true
  if (!dueDate) return false
  const d = new Date(dueDate)
  const start = new Date(); start.setHours(0, 0, 0, 0)
  const end = new Date(); end.setHours(23, 59, 59, 999)
  if (range === TIME_RANGES.TODAY) {
    return d.getTime() >= start.getTime() && d.getTime() <= end.getTime()
  }
  if (range === TIME_RANGES.WEEK) {
    const weekEnd = new Date(start); weekEnd.setDate(weekEnd.getDate() + 7)
    return d.getTime() >= start.getTime() && d.getTime() < weekEnd.getTime()
  }
  if (range === TIME_RANGES.LASTWEEK) {
    const weekStart = new Date(start); weekStart.setDate(weekStart.getDate() - 7)
    return d.getTime() >= weekStart.getTime() && d.getTime() < start.getTime()
  }
  if (range === TIME_RANGES.MONTH) {
    const monthEnd = new Date(start.getFullYear(), start.getMonth() + 1, 0, 23, 59, 59, 999)
    return d.getTime() >= start.getTime() && d.getTime() <= monthEnd.getTime()
  }
  if (range === TIME_RANGES.CUSTOM && customRange && customRange.from && customRange.to) {
    return d.getTime() >= customRange.from && d.getTime() <= customRange.to
  }
  return true
}

function applyFilters (todos, f) {
  const kw = (f.keyword || '').trim().toLowerCase()
  return todos.filter(t => {
    if (f.status === 'pending' && t.done) return false
    if (f.status === 'completed' && !t.done) return false
    if (f.type !== 'all' && t.type !== f.type) return false
    if (f.priority !== 'all' && t.priority !== f.priority) return false
    if (f.color !== 'all' && (t.color || '') !== f.color) return false
    if (!inTimeRange(t.dueDate, f.time, f.customRange)) return false
    if (kw && !(t.title || '').toLowerCase().includes(kw)) return false
    return true
  })
}

function applySort (todos, sort) {
  const dir = sort.dir === 'desc' ? -1 : 1
  const by = sort.by
  return todos.slice().sort((a, b) => {
    // pinned 永远在前
    if (Boolean(a.pinned) !== Boolean(b.pinned)) return a.pinned ? -1 : 1
    if (by === SORT_BY.PRIORITY) {
      return ((PRIORITY_RANK[b.priority] || 0) - (PRIORITY_RANK[a.priority] || 0)) * dir
    }
    if (by === SORT_BY.DUE) {
      const av = a.dueDate || Number.MAX_SAFE_INTEGER
      const bv = b.dueDate || Number.MAX_SAFE_INTEGER
      return (av - bv) * dir
    }
    // createdAt
    const av = a.createdAt || 0
    const bv = b.createdAt || 0
    return (av - bv) * dir
  })
}

const actions = {
  async load ({ commit, state }) {
    if (state.loaded) return
    const list = await todoApi.list()
    commit('SET_TODOS', Array.isArray(list) ? list : [])
  },
  async add ({ commit }, body) {
    const todo = await todoApi.create(body)
    if (!todo) return null
    commit('ADD_TODO', todo)
    return todo
  },
  async toggle ({ commit, state }, id) {
    const t = state.todos.find(x => x.id === id)
    if (!t) return
    const next = { ...t, done: !t.done, completedAt: !t.done ? Date.now() : null }
    const updated = await todoApi.update(id, { done: next.done, completedAt: next.completedAt })
    if (updated) commit('UPDATE_TODO', updated)
  },
  // === M1.1 actions ===
  setFilter ({ commit }, payload) { commit('SET_FILTER', payload) },
  resetFilters ({ commit }) { commit('RESET_FILTERS') },
  setSort ({ commit }, sort) { commit('SET_SORT', sort) },
  setView ({ commit }, view) { commit('SET_VIEW', view) },
  toggleSelect ({ commit }, id) { commit('TOGGLE_SELECT', id) },
  clearSelect ({ commit }) { commit('CLEAR_SELECT') }
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
  },
  // === M1.1 getters ===
  filtered: state => applyFilters(state.todos, state.filters),
  sorted: state => applySort(state.todos, state.sort),
  visible: state => applySort(applyFilters(state.todos, state.filters), state.sort),
  // 看板分组：pending / inProgress（有任意子任务且未完成）/ completed
  // M1.6 子任务完整版前，inProgress = 有 subtasks 且至少一个 done=false
  kanbanGroups: state => {
    const visible = applySort(applyFilters(state.todos, state.filters), state.sort)
    return {
      pending: visible.filter(t => !t.done && !(Array.isArray(t.subtasks) && t.subtasks.length)),
      inProgress: visible.filter(t => !t.done && Array.isArray(t.subtasks) && t.subtasks.length),
      completed: visible.filter(t => t.done)
    }
  }
}

export default { namespaced: true, state, mutations, actions, getters }
