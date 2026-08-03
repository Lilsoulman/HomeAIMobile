import Vue from 'vue'
import VueRouter from 'vue-router'
import { persistence } from '@/store/persistence'

Vue.use(VueRouter)

const routes = [
  { path: '/', name: 'home', component: () => import('@/views/Home.vue'), meta: { title: '首页' } },
  { path: '/login', name: 'login', component: () => import('@/views/Login.vue'), meta: { title: '登录' } },
  { path: '/todo', name: 'todo', component: () => import('@/views/Todo.vue'), meta: { title: '待办' } },
  { path: '/calendar', name: 'calendar', component: () => import('@/views/Calendar.vue'), meta: { title: '日历' } },
  { path: '/me', name: 'me', component: () => import('@/views/Me.vue'), meta: { title: '我的' } },
  { path: '*', redirect: '/' }
]

const router = new VueRouter({
  mode: 'hash',
  routes
})

router.afterEach(to => {
  if (to.meta && to.meta.title) document.title = `${to.meta.title} · HomeMind`
})

// 暴露 store 给 persistence 装订阅器（避免循环依赖，单独 install）
import store from '@/store'
persistence.install(store)

export default router
