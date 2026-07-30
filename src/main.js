import Vue from 'vue'
import ElementUI from 'element-ui'
import 'element-ui/lib/theme-chalk/index.css'
import Vant, { Lazyload } from 'vant'
import 'vant/lib/index.css'

import App from './App.vue'
import router from './router'
import store from './store'
import ThemeProvider from './components/common/ThemeProvider.vue'
import './assets/styles/index.css'
import './assets/styles/themes.css'
import './assets/styles/animations.css'

Vue.use(ElementUI, { size: 'small' })
Vue.use(Vant)
Vue.use(Lazyload)
Vue.component('ThemeProvider', ThemeProvider)

Vue.config.productionTip = false

new Vue({
  router,
  store,
  render: h => h(App)
}).$mount('#app')
