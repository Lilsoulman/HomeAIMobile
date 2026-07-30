import { calendarApi } from '@/services/api'
import { dateKey } from '@/utils/date'

const state = () => ({
  events: [],
  loaded: false,
  agendaDays: 3
})

const mutations = {
  HYDRATE (state, payload) {
    state.events = payload.events || []
    state.loaded = !!payload.loaded
  },
  SET_EVENTS (state, list) { state.events = list; state.loaded = true }
}

const actions = {
  async load ({ commit, state }) {
    if (state.loaded) return
    const res = await calendarApi.list()
    commit('SET_EVENTS', res.data || res)
  }
}

const getters = {
  eventsForDate: state => (key) => {
    return state.events.filter(e => dateKey(e.date) === key)
  },
  upcoming: state => (days) => {
    const result = []
    const now = new Date()
    for (let i = 0; i < days; i++) {
      const d = new Date(now)
      d.setDate(d.getDate() + i)
      const key = dateKey(d)
      const evs = state.events.filter(e => dateKey(e.date) === key)
      if (evs.length) {
        result.push({ offset: i, date: d, events: evs })
      }
    }
    return result
  }
}

export default { namespaced: true, state, mutations, actions, getters }
