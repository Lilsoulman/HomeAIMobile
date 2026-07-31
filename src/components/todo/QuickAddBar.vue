<template>
  <div class="qa-bar">
    <input
      v-model="title"
      class="qa-input"
      placeholder="快速添加待办，回车确认…"
      @keyup.enter="submit"
    />
    <button class="qa-btn" @click="submit">+</button>
  </div>
</template>

<script>
import { mapActions } from 'vuex'
import { track } from '@/utils/track'

export default {
  name: 'QuickAddBar',
  data () { return { title: '' } },
  methods: {
    ...mapActions('todos', ['add']),
    async submit () {
      const t = this.title.trim()
      if (!t) return
      await this.add({ title: t, priority: 'low', type: 'other' })
      track('todo_quick_add', { source: 'quick_add_bar' })
      this.title = ''
    }
  }
}
</script>

<style scoped>
.qa-bar {
  display: flex; align-items: center; gap: 6px;
  padding: 8px 12px;
  background: var(--bg-secondary);
  border-top: 1px solid var(--border);
}
.qa-input {
  flex: 1; background: var(--bg-card); border: 1px solid var(--border);
  border-radius: 8px; padding: 8px 12px; font-size: 13px;
  color: var(--text-primary); outline: 0;
}
.qa-input::placeholder { color: var(--text-muted); }
.qa-btn {
  width: 32px; height: 32px; border: 0; border-radius: 8px;
  background: var(--accent); color: #fff; font-size: 18px; line-height: 1;
}
</style>
