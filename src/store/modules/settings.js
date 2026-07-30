const state = () => ({
  theme: 'violet', // violet | ocean | light
  lang: 'zh',
  weatherCity: '北京市',
  weatherLat: 39.9042,
  weatherLon: 116.4074,
  weatherRefreshInterval: 30
})

const mutations = {
  HYDRATE (state, payload) { Object.assign(state, payload) },
  SET_THEME (state, theme) { state.theme = theme },
  SET_LANG (state, lang) { state.lang = lang },
  SET_WEATHER_CITY (state, { city, lat, lon }) {
    state.weatherCity = city
    if (lat) state.weatherLat = lat
    if (lon) state.weatherLon = lon
  }
}

const actions = {
  setTheme ({ commit }, theme) { commit('SET_THEME', theme) },
  setLang ({ commit }, lang) { commit('SET_LANG', lang) }
}

export default { namespaced: true, state, mutations, actions }
