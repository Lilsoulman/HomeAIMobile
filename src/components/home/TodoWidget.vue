<template>
  <section class="todo-widget card fade-in">
    <header class="wd-head">
      <div class="wd-title">
        <span class="wd-icon">✅</span>
        <span>待办</span>
        <span class="wd-counts">
          <span class="wd-pending">{{ pendingCount }}</span>
          <span class="wd-done">/ {{ doneCount }} 已完成</span>
        </span>
      </div>
    </header>
    <div class="wd-input">
      <input
        v-model="newTitle"
        class="wd-input-box"
        placeholder="快速添加待办…"
        @keyup.enter="addOne"
      />
      <button class="wd-add" @click="addOne">+</button>
    </div>
    <ul class="wd-list" v-if="homeList.length">
      <li
        v-for="(t, i) in homeList"
        :key="t.id"
        class="wd-item"
        :class="{ done: t.done, [t.priority]: true }"
        :style="{ borderLeftColor: t.color || 'var(--priority-' + t.priority + ')' }"
      >
        <label class="wd-check" @click.stop>
          <input type="checkbox" :checked="t.done" @change="toggle(t.id)" />
          <span class="wd-check-mark" />
        </label>
        <div class="wd-body">
          <span class="wd-seq">#{{ t.seq || '?' }}</span>
          <span class="wd-text">{{ t.title }}</span>
        </div>
        <span v-if="t.dueDate" class="wd-due" :class="dueClass(t)">{{ formatDue(t.dueDate) }}</span>
      </li>
    </ul>
    <EmptyState v-else text="暂无待办" sub="在上方输入框快速添加" />
    <footer class="wd-foot">
      <button class="wd-viewall" @click="$router.push('/todo')">查看全部 →</button>
    </footer>
  </section>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import EmptyState from '@/components/common/EmptyState.vue'

const PRIORITY_LABEL = { high: '高', mid: '中', low: '低' }

export default {
  name: 'TodoWidget',
  components: { EmptyState },
  data () { return { newTitle: '' } },
  computed: {
    ...mapGetters('todos', ['homeList', 'pendingCount', 'doneCount'])
  },
  methods: {
    ...mapActions('todos', ['add', 'toggle']),
    async addOne () {
      const title = this.newTitle.trim()
      if (!title) return
      await this.add({ title, priority: 'low', type: 'other' })
      this.newTitle = ''
    },
    formatDue (ts) {
      const d = new Date(ts)
      const now = new Date()
      const sameDay = d.toDateString() === now.toDateString()
      if (sameDay) return '今天'
      const tomorrow = new Date(now); tomorrow.setDate(tomorrow.getDate() + 1)
      if (d.toDateString() === tomorrow.toDateString()) return '明天'
      return `${d.getMonth() + 1}/${d.getDate()}`
    },
    dueClass (t) {
      return t.dueDate < Date.now() ? 'overdue' : 'normal'
    }
  }
}
</script>

<style scoped>
.todo-widget { padding: 14px 14px 10px; }
.wd-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
.wd-title { display: flex; align-items: center; gap: 6px; font-size: 14px; font-weight: 600; }
.wd-icon { font-size: 16px; }
.wd-counts { font-size: 11px; color: var(--text-muted); margin-left: 4px; }
.wd-pending { color: var(--accent); font-weight: 600; }

.wd-input {
  display: flex; align-items: center; gap: 6px;
  background: var(--accent-bg);
  border-radius: 10px;
  padding: 4px 4px 4px 10px;
  margin-bottom: 10px;
}
.wd-input-box {
  flex: 1; background: transparent; border: 0; outline: 0;
  color: var(--text-primary); font-size: 13px;
}
.wd-input-box::placeholder { color: var(--text-muted); }
.wd-add {
  width: 26px; height: 26px; border: 0; border-radius: 6px;
  background: var(--accent); color: #fff; font-size: 16px; line-height: 1;
}

.wd-list { display: flex; flex-direction: column; gap: 6px; }
.wd-item {
  display: flex; align-items: center; gap: 8px;
  padding: 6px 8px;
  border-radius: 6px;
  border-left: 3px solid var(--accent);
  background: var(--accent-bg);
  animation: fadeIn 0.3s ease both;
}
.wd-item.done { opacity: 0.5; }
.wd-item.done .wd-text { text-decoration: line-through; }

.wd-check { position: relative; width: 16px; height: 16px; flex-shrink: 0; }
.wd-check input { opacity: 0; width: 100%; height: 100%; }
.wd-check-mark {
  position: absolute; inset: 0;
  border: 1.5px solid var(--text-muted);
  border-radius: 50%;
}
.wd-check input:checked + .wd-check-mark {
  background: var(--accent); border-color: var(--accent);
}
.wd-check input:checked + .wd-check-mark::after {
  content: '✓'; position: absolute; left: 50%; top: 50%;
  transform: translate(-50%, -50%);
  color: #fff; font-size: 10px; line-height: 1;
}

.wd-body { flex: 1; display: flex; align-items: center; gap: 6px; min-width: 0; }
.wd-seq { color: var(--text-muted); font-size: 10px; flex-shrink: 0; }
.wd-text {
  font-size: 13px; color: var(--text-primary);
  overflow: hidden; white-space: nowrap; text-overflow: ellipsis;
}
.wd-due {
  font-size: 10px; padding: 1px 5px; border-radius: 3px;
  background: var(--bg-card);
}
.wd-due.overdue { color: var(--priority-high); }
.wd-due.normal { color: var(--text-muted); }

.wd-foot { margin-top: 8px; text-align: right; }
.wd-viewall {
  background: transparent; border: 0;
  color: var(--accent); font-size: 12px;
}
</style>
