// 预留：JWT 用户模块
const state = () => ({
  token: '',
  userInfo: { name: '用户', avatar: '' }
})

const mutations = {
  HYDRATE (state, payload) { Object.assign(state, payload) },
  SET_TOKEN (state, token) { state.token = token },
  SET_USER (state, user) { state.userInfo = { ...state.userInfo, ...user } },
  LOGOUT (state) { state.token = '' }
}

const actions = {
  setToken ({ commit }, token) { commit('SET_TOKEN', token) },
  setUser ({ commit }, user) { commit('SET_USER', user) },
  logout ({ commit }) { commit('LOGOUT') }
}

export default { namespaced: true, state, mutations, actions }
