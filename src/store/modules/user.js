// 用户模块：接 authApi，提供 login / refresh / fetchMe / logout / loginWithWechat
import { authApi } from '@/services/api'
import { storage } from '@/utils/storage'

const state = () => ({
  token: '',
  refreshToken: '',
  userInfo: { id: null, name: '用户', avatar: '', phone: '', wechatOpenId: '' }
})

const mutations = {
  HYDRATE (state, payload) { Object.assign(state, payload) },
  SET_TOKEN (state, token) { state.token = token },
  SET_REFRESH_TOKEN (state, rt) { state.refreshToken = rt },
  SET_USER (state, user) { state.userInfo = { ...state.userInfo, ...user } },
  LOGOUT (state) {
    state.token = ''
    state.refreshToken = ''
  }
}

const actions = {
  async login ({ commit }, payload) {
    const res = await authApi.login(payload)
    if (!res) return null
    commit('SET_TOKEN', res.accessToken || '')
    commit('SET_REFRESH_TOKEN', res.refreshToken || '')
    commit('SET_USER', res.user || {})
    storage.set('user_token', res.accessToken || '')
    return res
  },
  async register ({ commit }, payload) {
    const res = await authApi.register(payload)
    if (!res) return null
    commit('SET_TOKEN', res.accessToken || '')
    commit('SET_REFRESH_TOKEN', res.refreshToken || '')
    commit('SET_USER', res.user || {})
    storage.set('user_token', res.accessToken || '')
    return res
  },
  async loginWithWechat ({ commit }, { code }) {
    if (!code) throw new Error('wechat code required')
    const res = await authApi.wechatLogin(code)
    if (!res) return null
    commit('SET_TOKEN', res.accessToken || '')
    commit('SET_REFRESH_TOKEN', res.refreshToken || '')
    commit('SET_USER', res.user || {})
    storage.set('user_token', res.accessToken || '')
    return res
  },
  async refresh ({ commit }, refreshToken) {
    const rt = refreshToken || (state().refreshToken)
    if (!rt) throw new Error('no refresh token')
    const res = await authApi.refresh(rt)
    if (!res) return null
    commit('SET_TOKEN', res.accessToken || '')
    commit('SET_REFRESH_TOKEN', res.refreshToken || '')
    storage.set('user_token', res.accessToken || '')
    return res
  },
  async fetchMe ({ commit }) {
    const me = await authApi.me()
    if (me) commit('SET_USER', me)
    return me
  },
  async logout ({ commit }) {
    commit('LOGOUT')
    storage.remove('user_token')
  },
  setToken ({ commit }, token) { commit('SET_TOKEN', token) },
  setUser ({ commit }, user) { commit('SET_USER', user) }
}

const getters = {
  isLoggedIn: state => !!state.token && !!state.userInfo.id
}

export default { namespaced: true, state, mutations, actions, getters }
