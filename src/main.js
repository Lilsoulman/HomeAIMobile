import Vue from 'vue'
import ElementUI from 'element-ui'
import 'element-ui/lib/theme-chalk/index.css'
import Vant, { Lazyload } from 'vant'
import 'vant/lib/index.css'

import App from './App.vue'
import router from './router'
import store from './store'
import ThemeProvider from './components/common/ThemeProvider.vue'
import { migrateLocalStorage } from './utils/migrate'
import './assets/styles/index.css'
import './assets/styles/themes.css'
import './assets/styles/animations.css'

// 品牌迁移必须在 store hydration 之前完成
migrateLocalStorage()

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
