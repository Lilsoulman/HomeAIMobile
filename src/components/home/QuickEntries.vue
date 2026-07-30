<template>
  <section class="quick-entries fade-in">
    <button
      v-for="(it, i) in items"
      :key="i"
      class="qe"
      :style="{ '--qe-color': it.color }"
      @click="onClick(it)"
    >
      <span class="qe-icon">{{ it.icon }}</span>
      <span class="qe-label">{{ it.label }}</span>
    </button>
  </section>
</template>

<script>
import { Toast } from 'vant'

export default {
  name: 'QuickEntries',
  data () {
    return {
      items: [
        { key: 'add', icon: '➕', label: '新建', color: 'var(--accent)' },
        { key: 'search', icon: '🔍', label: '搜索', color: '#38bdf8' },
        { key: 'skill', icon: '🧠', label: '技能', color: '#a855f7' },
        { key: 'ai', icon: '🤖', label: 'AI', color: '#10b981' }
      ]
    }
  },
  methods: {
    onClick (it) {
      if (it.key === 'add') this.$router.push('/todo')
      else Toast(`「${it.label}」将在 M1~M3 阶段开放（见 PROJECT_PLAN.md §3）`)
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
