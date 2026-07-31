<template>
  <div class="kanban">
    <div v-for="col in columns" :key="col.key" class="kb-col">
      <header class="kb-col-head">
        <span class="kb-col-dot" :style="{ background: col.color }" />
        <span class="kb-col-title">{{ col.title }}</span>
        <span class="kb-col-count">{{ groups[col.key].length }}</span>
      </header>
      <div class="kb-col-body">
        <TodoItem v-for="t in groups[col.key]" :key="t.id" :todo="t"
          @toggle="$emit('toggle', t.id)"
          @open="$emit('open', t)" />
        <div v-if="groups[col.key].length === 0" class="kb-empty">{{ col.emptyText }}</div>
      </div>
    </div>
  </div>
</template>

<script>
import TodoItem from './TodoItem.vue'

const COLUMNS = [
  { key: 'pending', title: '待办', color: 'var(--accent)', emptyText: '无待办' },
  { key: 'inProgress', title: '进行中', color: 'var(--priority-mid)', emptyText: '无进行中' },
  { key: 'completed', title: '已完成', color: 'var(--priority-low)', emptyText: '无已完成' }
]

export default {
  name: 'TodoKanbanView',
  components: { TodoItem },
  props: {
    groups: { type: Object, required: true } // { pending: [], inProgress: [], completed: [] }
  },
  data () { return { columns: COLUMNS } }
}
</script>

<style scoped>
.kanban {
  display: flex; gap: 8px; padding: 10px 8px;
  overflow-x: auto; min-height: 200px;
}
.kb-col {
  flex: 1; min-width: 0;
  display: flex; flex-direction: column; gap: 6px;
  background: var(--bg-secondary);
  border-radius: 10px;
  border: 1px solid var(--border);
}
.kb-col-head {
  display: flex; align-items: center; gap: 6px;
  padding: 8px 10px; border-bottom: 1px solid var(--border);
  font-size: 12px; font-weight: 600;
}
.kb-col-dot { width: 8px; height: 8px; border-radius: 50%; }
.kb-col-title { flex: 1; color: var(--text-primary); }
.kb-col-count {
  font-size: 10px; padding: 1px 6px; border-radius: 8px;
  background: var(--bg-card); color: var(--text-muted);
}
.kb-col-body { display: flex; flex-direction: column; gap: 6px; padding: 6px 6px 10px; }
.kb-empty {
  font-size: 11px; color: var(--text-muted); text-align: center;
  padding: 12px 4px;
}
</style>
