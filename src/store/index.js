import Vue from 'vue'
import Vuex from 'vuex'
import settings from './modules/settings'
import todos from './modules/todos'
import calendar from './modules/calendar'
import user from './modules/user'
import { storage } from '@/utils/storage'
import { persistence } from './persistence'

Vue.use(Vuex)

const store = new Vuex.Store({
  modules: { settings, todos, calendar, user },
  strict: process.env.NODE_ENV !== 'production'
})

// 启动时从 localStorage 还原
persistence.hydrate(store)

export default store
