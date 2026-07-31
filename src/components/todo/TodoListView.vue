<template>
  <div class="todo-list">
    <div v-if="todos.length === 0" class="empty-hint">
      <span class="empty-icon">📭</span>
      <span class="empty-text">{{ emptyText }}</span>
    </div>
    <TodoItem v-for="t in todos" :key="t.id" :todo="t"
      @toggle="$emit('toggle', t.id)"
      @open="$emit('open', t)" />
  </div>
</template>

<script>
import TodoItem from './TodoItem.vue'

export default {
  name: 'TodoListView',
  components: { TodoItem },
  props: {
    todos: { type: Array, default: () => [] },
    emptyText: { type: String, default: '暂无待办' }
  }
}
</script>

<style scoped>
.todo-list { display: flex; flex-direction: column; gap: 6px; padding: 10px 12px; }
.empty-hint {
  display: flex; flex-direction: column; align-items: center; gap: 8px;
  padding: 40px 20px; color: var(--text-muted); font-size: 13px;
}
.empty-icon { font-size: 40px; }
</style>
