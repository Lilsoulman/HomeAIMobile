<template>
  <div class="empty-state">
    <div class="empty-icon">{{ icon }}</div>
    <div class="empty-text">{{ text }}</div>
    <div v-if="sub" class="empty-sub">{{ sub }}</div>
  </div>
</template>

<script>
export default {
  name: 'EmptyState',
  props: {
    icon: { type: String, default: '📭' },
    text: { type: String, default: '暂无数据' },
    sub: { type: String, default: '' }
  }
}
</script>

<style scoped>
.empty-state {
  padding: 24px 12px;
  text-align: center;
  color: var(--text-muted);
}
.empty-icon { font-size: 32px; margin-bottom: 8px; }
.empty-text { font-size: 14px; color: var(--text-secondary); }
.empty-sub { font-size: 12px; margin-top: 4px; }
</style>
