<template>
  <nav class="tabbar">
    <router-link
      v-for="item in items"
      :key="item.path"
      :to="item.path"
      class="tab"
      :class="{ active: $route.path === item.path }"
    >
      <span class="tab-icon">{{ item.icon }}</span>
      <span class="tab-label">{{ item.label }}</span>
    </router-link>
  </nav>
</template>

<script>
export default {
  name: 'TabBar',
  data () {
    return {
      items: [
        { path: '/', label: '首页', icon: '🏠' },
        { path: '/todo', label: '待办', icon: '✅' },
        { path: '/calendar', label: '日历', icon: '📅' },
        { path: '/me', label: '我的', icon: '👤' }
      ]
    }
  }
}
</script>

<style scoped>
.tabbar {
  position: fixed;
  left: 0; right: 0; bottom: 0;
  display: flex;
  background: var(--bg-card);
  border-top: 1px solid var(--border);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  padding-bottom: env(safe-area-inset-bottom);
  z-index: 20;
}
.tab {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  padding: 6px 0;
  color: var(--text-muted);
  font-size: 10px;
  text-decoration: none;
  transition: color 0.15s ease;
}
.tab.active {
  color: var(--accent);
}
.tab-icon { font-size: 20px; line-height: 1; }
.tab-label { font-size: 10px; }
</style>
