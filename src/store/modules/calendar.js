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
  SET_EVENTS (state, list) { state.events = list; state.loaded = true },
  ADD_EVENT (state, event) { state.events.push(event) },
  UPDATE_EVENT (state, event) {
    const idx = state.events.findIndex(e => e.id === event.id)
    if (idx >= 0) {
      state.events.splice(idx, 1, event)
    }
  },
  DELETE_EVENT (state, id) {
    state.events = state.events.filter(e => e.id !== id)
  }
}

const actions = {
  async load ({ commit, state }) {
    if (state.loaded) return
    const res = await calendarApi.list()
    commit('SET_EVENTS', res.data || res)
  },
  async createEvent ({ commit }, event) {
    const res = await calendarApi.create(event)
    commit('ADD_EVENT', res.data || res)
  },
  async updateEvent ({ commit }, event) {
    const res = await calendarApi.update(event.id, event)
    commit('UPDATE_EVENT', res.data || res)
  },
  async deleteEvent ({ commit }, id) {
    await calendarApi.remove(id)
    commit('DELETE_EVENT', id)
  }
}

const getters = {
  eventsForDate: state => (key) => {
    return state.events.filter(e => dateKey(new Date(e.date)) === key)
  },
  upcoming: state => (days) => {
    const result = []
    const now = new Date()
    for (let i = 0; i < days; i++) {
      const d = new Date(now)
      d.setDate(d.getDate() + i)
      const key = dateKey(d)
      const evs = state.events.filter(e => dateKey(new Date(e.date)) === key)
      if (evs.length) {
        result.push({ offset: i, date: d, events: evs })
      }
    }
    return result
  }
}

export default { namespaced: true, state, mutations, actions, getters }