<template>
  <div class="page-placeholder">
    <div class="ph-icon">{{ icon }}</div>
    <div class="ph-title">{{ title }}</div>
    <div class="ph-sub">{{ sub }}</div>
    <div class="ph-hint">📌 完整版规划见 <code>PROJECT_PLAN.md §3</code></div>
  </div>
</template>

<script>
export default {
  name: 'PagePlaceholder',
  props: {
    icon: { type: String, default: '🚧' },
    title: { type: String, required: true },
    sub: { type: String, default: '此模块将在后续里程碑中实现' }
  }
}
</script>

<style scoped>
.page-placeholder {
  padding: 60px 20px;
  text-align: center;
  color: var(--text-muted);
}
.ph-icon { font-size: 48px; margin-bottom: 12px; }
.ph-title { font-size: 18px; color: var(--text-primary); font-weight: 600; margin-bottom: 6px; }
.ph-sub { font-size: 13px; margin-bottom: 12px; }
.ph-hint { font-size: 12px; padding: 6px 10px; background: var(--accent-bg); border-radius: 6px; display: inline-block; }
.ph-hint code { color: var(--accent); }
</style>
