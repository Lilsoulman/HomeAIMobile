<template>
  <div class="todo-item"
    :class="{ done: todo.done, pinned: todo.pinned }"
    :style="{ borderLeftColor: borderColor }"
    @click="$emit('open', todo)"
  >
    <label class="ti-check" @click.stop>
      <input type="checkbox" :checked="todo.done" @change="$emit('toggle', todo.id)" />
      <span class="ti-check-mark" />
    </label>
    <div class="ti-body">
      <div class="ti-row1">
        <span v-if="todo.pinned" class="ti-pin">📌</span>
        <span class="ti-title">{{ todo.title }}</span>
      </div>
      <div class="ti-row2">
        <span v-if="todo.type" class="ti-tag" :class="'tag-' + todo.type">{{ typeLabel }}</span>
        <span v-if="todo.dueDate" class="ti-due" :class="dueClass">{{ dueLabel }}</span>
        <span v-if="hasSubtasks" class="ti-sub">
          {{ doneSubCount }}/{{ todo.subtasks.length }} 子任务
        </span>
      </div>
    </div>
    <span class="ti-prio" :class="'prio-' + (todo.priority || 'low')">{{ prioLabel }}</span>
  </div>
</template>

<script>
const TYPE_LABEL = { work: '工作', life: '生活', study: '学习', other: '其他' }
const PRIORITY_LABEL = { high: '高', mid: '中', low: '低' }

export default {
  name: 'TodoItem',
  props: {
    todo: { type: Object, required: true }
  },
  computed: {
    typeLabel () { return TYPE_LABEL[this.todo.type] || this.todo.type || '' },
    prioLabel () { return PRIORITY_LABEL[this.todo.priority] || '低' },
    borderColor () {
      if (this.todo.color) return this.todo.color
      const map = { high: 'var(--priority-high)', mid: 'var(--priority-mid)', low: 'var(--priority-low)' }
      return map[this.todo.priority] || 'var(--accent)'
    },
    hasSubtasks () { return Array.isArray(this.todo.subtasks) && this.todo.subtasks.length > 0 },
    doneSubCount () {
      if (!this.hasSubtasks) return 0
      return this.todo.subtasks.filter(s => s.done).length
    },
    dueLabel () {
      if (!this.todo.dueDate) return ''
      const d = new Date(this.todo.dueDate)
      const now = new Date()
      const sameDay = d.toDateString() === now.toDateString()
      if (sameDay) return '今天'
      const tomorrow = new Date(now); tomorrow.setDate(tomorrow.getDate() + 1)
      if (d.toDateString() === tomorrow.toDateString()) return '明天'
      return `${d.getMonth() + 1}/${d.getDate()}`
    },
    dueClass () {
      if (!this.todo.dueDate) return ''
      return this.todo.dueDate < Date.now() ? 'overdue' : 'normal'
    }
  }
}
</script>

<style scoped>
.todo-item {
  display: flex; align-items: center; gap: 10px;
  padding: 10px 12px;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-left: 3px solid var(--accent);
  border-radius: 10px;
  transition: transform 0.15s ease;
}
.todo-item:active { transform: scale(0.99); }
.todo-item.done { opacity: 0.55; }
.todo-item.done .ti-title { text-decoration: line-through; }

.ti-check { position: relative; width: 18px; height: 18px; flex-shrink: 0; }
.ti-check input { opacity: 0; width: 100%; height: 100%; }
.ti-check-mark {
  position: absolute; inset: 0;
  border: 1.5px solid var(--text-muted);
  border-radius: 50%;
}
.ti-check input:checked + .ti-check-mark {
  background: var(--accent); border-color: var(--accent);
}
.ti-check input:checked + .ti-check-mark::after {
  content: '✓'; position: absolute; left: 50%; top: 50%;
  transform: translate(-50%, -50%); color: #fff; font-size: 11px;
}

.ti-body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }
.ti-row1 { display: flex; align-items: center; gap: 6px; }
.ti-pin { font-size: 11px; flex-shrink: 0; }
.ti-title {
  font-size: 14px; color: var(--text-primary);
  overflow: hidden; white-space: nowrap; text-overflow: ellipsis;
}
.ti-row2 { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.ti-tag {
  font-size: 10px; padding: 1px 5px; border-radius: 3px;
  background: var(--bg-secondary); color: var(--text-secondary);
}
.ti-tag.tag-work { background: rgba(99,102,241,0.15); color: var(--accent); }
.ti-tag.tag-life { background: rgba(16,185,129,0.15); color: var(--priority-low); }
.ti-tag.tag-study { background: rgba(245,158,11,0.15); color: var(--priority-mid); }
.ti-due { font-size: 10px; padding: 1px 5px; border-radius: 3px; background: var(--bg-secondary); }
.ti-due.overdue { color: var(--priority-high); }
.ti-due.normal { color: var(--text-muted); }
.ti-sub { font-size: 10px; color: var(--text-muted); }

.ti-prio {
  flex-shrink: 0; width: 22px; height: 22px;
  display: flex; align-items: center; justify-content: center;
  font-size: 10px; font-weight: 600; border-radius: 50%;
  color: #fff;
}
.ti-prio.prio-high { background: var(--priority-high); }
.ti-prio.prio-mid { background: var(--priority-mid); }
.ti-prio.prio-low { background: var(--priority-low); }
</style>
