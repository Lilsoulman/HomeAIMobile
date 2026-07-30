<template>
  <section class="stats card fade-in">
    <div v-for="item in items" :key="item.key" class="stat">
      <span class="stat-icon">{{ item.icon }}</span>
      <span class="stat-val" :style="{ color: item.color || 'var(--text-primary)' }">{{ counts[item.key] || 0 }}</span>
      <span class="stat-lbl">{{ item.label }}</span>
    </div>
  </section>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  name: 'TodayStatsCard',
  data () {
    return {
      items: [
        { key: 'pendingCount', icon: '📋', label: '待办', color: 'var(--accent)' },
        { key: 'todayCount', icon: '⏰', label: '今日' },
        { key: 'overdueCount', icon: '⚠️', label: '逾期', color: 'var(--priority-high)' }
      ]
    }
  },
  computed: {
    ...mapGetters('todos', ['pendingCount', 'todayCount', 'overdueCount']),
    counts () {
      return {
        pendingCount: this.pendingCount,
        todayCount: this.todayCount,
        overdueCount: this.overdueCount
      }
    }
  }
}
</script>

<style scoped>
.stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  padding: 12px 8px;
  text-align: center;
}
.stat { display: flex; flex-direction: column; align-items: center; gap: 2px; padding: 4px 0; }
.stat-icon { font-size: 18px; }
.stat-val { font-size: 22px; font-weight: 600; }
.stat-lbl { font-size: 11px; color: var(--text-muted); }
</style>
