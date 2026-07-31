<template>
  <div class="todo-view">
    <header class="tv-head">
      <div class="tv-tabs">
        <button :class="{ active: view === 'kanban' }" @click="setView('kanban')">看板</button>
        <button :class="{ active: view === 'list' }" @click="setView('list')">列表</button>
      </div>
      <div class="tv-tools">
        <SortMenu />
        <button class="tv-new" @click="onNew">新建</button>
      </div>
    </header>

    <FilterBar />

    <div class="tv-body">
      <TodoKanbanView
        v-if="view === 'kanban'"
        :groups="kanbanGroups"
        @toggle="onToggle"
      />
      <TodoListView
        v-else
        :todos="visible"
        empty-text="当前筛选下无待办"
        @toggle="onToggle"
      />
    </div>

    <QuickAddBar />
  </div>
</template>

<script>
import { mapState, mapGetters, mapActions } from 'vuex'
import FilterBar from '@/components/todo/FilterBar.vue'
import SortMenu from '@/components/todo/SortMenu.vue'
import TodoKanbanView from '@/components/todo/TodoKanbanView.vue'
import TodoListView from '@/components/todo/TodoListView.vue'
import QuickAddBar from '@/components/todo/QuickAddBar.vue'
import { track } from '@/utils/track'

export default {
  name: 'Todo',
  components: { FilterBar, SortMenu, TodoKanbanView, TodoListView, QuickAddBar },
  computed: {
    ...mapState('todos', ['view']),
    ...mapGetters('todos', ['visible', 'kanbanGroups'])
  },
  methods: {
    ...mapActions('todos', ['load', 'toggle', 'add', 'setView']),
    setView (v) {
      track('todo_view_switch', { to: v })
      this.setView(v)
    },
    onToggle (id) { this.toggle(id) },
    onNew () {
      const t = window.prompt('新建待办标题：')
      if (!t || !t.trim()) return
      this.add({ title: t.trim(), priority: 'low', type: 'other' })
      track('todo_new_inline', { source: 'todo_page_new_btn' })
    }
  },
  mounted () {
    this.load().catch(() => {})
  }
}
</script>

<style scoped>
.todo-view { display: flex; flex-direction: column; height: 100%; }
.tv-head {
  display: flex; align-items: center; justify-content: space-between;
  padding: 8px 12px;
  background: var(--bg-secondary);
  border-bottom: 1px solid var(--border);
}
.tv-tabs { display: flex; gap: 4px; }
.tv-tabs button {
  font-size: 13px; padding: 5px 12px; border-radius: 14px;
  background: var(--bg-card); color: var(--text-secondary);
  border: 1px solid var(--border);
}
.tv-tabs button.active { color: #fff; background: var(--accent); border-color: var(--accent); }
.tv-tools { display: flex; align-items: center; gap: 6px; }
.tv-new {
  font-size: 12px; padding: 5px 12px; border-radius: 14px;
  background: var(--accent); color: #fff; border: 0;
}
.tv-body { flex: 1; overflow-y: auto; }
</style>
