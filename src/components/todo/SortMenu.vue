<template>
  <div class="sort-menu">
    <button class="sm-btn" @click="popup = true">
      {{ currentLabel }} {{ dirArrow }}
    </button>
    <van-popup v-model="popup" position="bottom" round :style="{ maxHeight: '60vh' }">
      <div class="sm-popup">
        <header class="sm-head">
          <span>排序方式</span>
          <button class="sm-close" @click="popup = false">×</button>
        </header>
        <button v-for="o in options" :key="o.value"
          class="sm-opt" :class="{ active: sort.by === o.value }"
          @click="pick(o.value)">
          <span>{{ o.label }}</span>
          <span v-if="sort.by === o.value" class="sm-dir" @click.stop="toggleDir">
            {{ sort.dir === 'asc' ? '↑' : '↓' }}
          </span>
        </button>
      </div>
    </van-popup>
  </div>
</template>

<script>
import { mapState } from 'vuex'
import { SORT_BY } from '@/store/modules/todos'

const OPTIONS = [
  { value: SORT_BY.DUE, label: '到期时间' },
  { value: SORT_BY.CREATED, label: '创建时间' },
  { value: SORT_BY.PRIORITY, label: '优先级' }
]

export default {
  name: 'SortMenu',
  data () { return { popup: false, options: OPTIONS } },
  computed: {
    ...mapState('todos', ['sort']),
    currentLabel () { return (OPTIONS.find(o => o.value === this.sort.by) || {}).label || '排序' },
    dirArrow () { return this.sort.dir === 'asc' ? '↑' : '↓' }
  },
  methods: {
    pick (by) { this.$store.dispatch('todos/setSort', { by, dir: this.sort.dir }) },
    toggleDir () {
      this.$store.dispatch('todos/setSort', { by: this.sort.by, dir: this.sort.dir === 'asc' ? 'desc' : 'asc' })
    }
  }
}
</script>

<style scoped>
.sort-menu { display: inline-block; }
.sm-btn {
  font-size: 12px; padding: 5px 10px; border-radius: 14px;
  background: var(--bg-card); color: var(--text-secondary);
  border: 1px solid var(--border);
}
.sm-popup { padding: 16px; }
.sm-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; font-size: 14px; font-weight: 600; }
.sm-close { background: transparent; border: 0; color: var(--text-muted); font-size: 22px; }
.sm-opt {
  display: flex; align-items: center; justify-content: space-between;
  width: 100%; font-size: 14px; padding: 12px 14px; border-radius: 8px;
  background: var(--bg-card); color: var(--text-primary);
  border: 1px solid var(--border); margin-bottom: 6px;
}
.sm-opt.active { color: #fff; background: var(--accent); border-color: var(--accent); }
.sm-dir { font-size: 16px; padding: 2px 6px; background: rgba(255,255,255,0.2); border-radius: 4px; }
</style>
