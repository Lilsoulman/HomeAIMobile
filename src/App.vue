<template>
  <div id="app-root">
    <ThemeProvider>
      <div class="app-shell">
        <AppHeader />
        <main class="app-main">
          <router-view v-slot="{ Component }">
            <transition name="page" mode="out-in">
              <component :is="Component" />
            </transition>
          </router-view>
        </main>
        <TabBar />
      </div>
    </ThemeProvider>
  </div>
</template>

<script>
import AppHeader from '@/components/layout/AppHeader.vue'
import TabBar from '@/components/layout/TabBar.vue'

export default {
  name: 'App',
  components: { AppHeader, TabBar }
}
</script>

<style>
.app-shell {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: var(--bg-primary);
  color: var(--text-primary);
  padding-bottom: env(safe-area-inset-bottom);
}
.app-main {
  flex: 1;
  padding-bottom: 120px; /* 给 TabBar 留位 */
}
.page-enter-active, .page-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.page-enter, .page-leave-to {
  opacity: 0;
  transform: translateY(8px);
}
</style>
