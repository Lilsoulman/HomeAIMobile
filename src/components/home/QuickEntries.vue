<template>
  <section class="quick-entries fade-in">
    <button
      v-for="it in items"
      :key="it.key"
      class="qe"
      :style="{ '--qe-color': it.color }"
      @click="go(it)"
    >
      <span class="qe-icon">{{ it.icon }}</span>
      <span class="qe-label">{{ it.label }}</span>
    </button>
  </section>
</template>

<script>
import { track } from '@/utils/track'

export default {
  name: 'QuickEntries',
  data () {
    return {
      items: [
        { key: 'todo', icon: '✅', label: '待办', color: 'var(--accent)', to: '/todo' },
        { key: 'calendar', icon: '📅', label: '日历', color: '#38bdf8', to: '/calendar' },
        { key: 'ai', icon: '🤖', label: 'AI 报告', color: '#a855f7', to: '/me' },
        { key: 'me', icon: '👤', label: '我的', color: '#10b981', to: '/me' }
      ]
    }
  },
  methods: {
    go (it) {
      track('quick_entry_click', { key: it.key })
      this.$router.push(it.to)
    }
  }
}
</script>

<style scoped>
.quick-entries {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
  padding: 12px 0 0;
}
.qe {
  display: flex; flex-direction: column; align-items: center; gap: 4px;
  padding: 10px 4px;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 12px;
  color: var(--text-primary);
  font-size: 11px;
  transition: transform 0.15s ease, background 0.15s ease;
}
.qe:active { transform: scale(0.96); background: var(--bg-card-hover); }
.qe-icon {
  font-size: 20px;
  filter: drop-shadow(0 0 4px var(--qe-color, var(--accent-glow)));
}
.qe-label { color: var(--text-secondary); }
</style>
