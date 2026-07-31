<template>
  <div class="filter-bar">
    <button class="fb-chip" :class="{ active: filters.status !== 'all' }" @click="openPanel('status')">
      {{ statusLabel }} ▾
    </button>
    <button class="fb-chip" :class="{ active: filters.type !== 'all' }" @click="openPanel('type')">
      {{ typeLabel }} ▾
    </button>
    <button class="fb-chip" :class="{ active: filters.time !== 'all' }" @click="openPanel('time')">
      {{ timeLabel }} ▾
    </button>
    <button class="fb-chip" :class="{ active: filters.priority !== 'all' }" @click="openPanel('priority')">
      {{ priorityLabel }} ▾
    </button>
    <button class="fb-chip" :class="{ active: !!filters.keyword }" @click="openPanel('keyword')">
      🔍 {{ filters.keyword ? '已筛选' : '关键字' }}
    </button>
    <button v-if="hasAnyFilter" class="fb-reset" @click="reset">重置</button>

    <van-popup v-model="popup.show" position="bottom" round :style="{ maxHeight: '70vh' }">
      <div class="fb-popup">
        <header class="fb-popup-head">
          <span>{{ popupTitle }}</span>
          <button class="fb-close" @click="popup.show = false">×</button>
        </header>

        <!-- 状态 -->
        <div v-if="popup.kind === 'status'" class="fb-options">
          <button v-for="o in statusOptions" :key="o.value"
            class="fb-opt" :class="{ active: filters.status === o.value }"
            @click="pick('status', o.value)">{{ o.label }}</button>
        </div>

        <!-- 类型 -->
        <div v-else-if="popup.kind === 'type'" class="fb-options">
          <button v-for="o in typeOptions" :key="o.value"
            class="fb-opt" :class="{ active: filters.type === o.value }"
            @click="pick('type', o.value)">{{ o.label }}</button>
        </div>

        <!-- 时间 -->
        <div v-else-if="popup.kind === 'time'" class="fb-options">
          <button v-for="o in timeOptions" :key="o.value"
            class="fb-opt" :class="{ active: filters.time === o.value }"
            @click="pick('time', o.value)">{{ o.label }}</button>
          <div v-if="filters.time === 'custom'" class="fb-custom-range">
            <label>从 <input type="date" v-model="customFrom" /></label>
            <label>到 <input type="date" v-model="customTo" /></label>
            <button class="fb-opt" @click="applyCustomRange">应用</button>
          </div>
        </div>

        <!-- 优先级 -->
        <div v-else-if="popup.kind === 'priority'" class="fb-options">
          <button v-for="o in priorityOptions" :key="o.value"
            class="fb-opt" :class="{ active: filters.priority === o.value }"
            @click="pick('priority', o.value)">{{ o.label }}</button>
        </div>

        <!-- 关键字 -->
        <div v-else-if="popup.kind === 'keyword'" class="fb-keyword">
          <input v-model="keywordDraft" placeholder="搜索标题…" @keyup.enter="applyKeyword" />
          <button class="fb-opt" @click="applyKeyword">应用</button>
        </div>
      </div>
    </van-popup>
  </div>
</template>

<script>
import { mapState } from 'vuex'
import { TIME_RANGES } from '@/store/modules/todos'

const STATUS = [
  { value: 'all', label: '全部' },
  { value: 'pending', label: '待办' },
  { value: 'completed', label: '已完成' }
]
const TYPES = [
  { value: 'all', label: '全部类型' },
  { value: 'work', label: '工作' },
  { value: 'life', label: '生活' },
  { value: 'study', label: '学习' },
  { value: 'other', label: '其他' }
]
const TIMES = [
  { value: TIME_RANGES.ALL, label: '全部时间' },
  { value: TIME_RANGES.TODAY, label: '今天' },
  { value: TIME_RANGES.WEEK, label: '本周' },
  { value: TIME_RANGES.LASTWEEK, label: '上周' },
  { value: TIME_RANGES.MONTH, label: '本月' },
  { value: TIME_RANGES.CUSTOM, label: '自定义…' }
]
const PRIORITIES = [
  { value: 'all', label: '全部优先级' },
  { value: 'high', label: '高' },
  { value: 'mid', label: '中' },
  { value: 'low', label: '低' }
]

export default {
  name: 'FilterBar',
  data () {
    return {
      popup: { show: false, kind: null },
      keywordDraft: '',
      customFrom: '',
      customTo: '',
      statusOptions: STATUS,
      typeOptions: TYPES,
      timeOptions: TIMES,
      priorityOptions: PRIORITIES
    }
  },
  computed: {
    ...mapState('todos', ['filters']),
    hasAnyFilter () {
      const f = this.filters
      return f.status !== 'all' || f.type !== 'all' || f.time !== 'all' ||
        f.priority !== 'all' || !!f.keyword
    },
    statusLabel () { return (STATUS.find(o => o.value === this.filters.status) || {}).label || '状态' },
    typeLabel () { return (TYPES.find(o => o.value === this.filters.type) || {}).label || '类型' },
    timeLabel () { return (TIMES.find(o => o.value === this.filters.time) || {}).label || '时间' },
    priorityLabel () { return (PRIORITIES.find(o => o.value === this.filters.priority) || {}).label || '优先级' },
    popupTitle () {
      return { status: '筛选状态', type: '筛选类型', time: '筛选时间', priority: '筛选优先级', keyword: '关键字搜索' }[this.popup.kind] || ''
    }
  },
  methods: {
    openPanel (kind) {
      this.popup.kind = kind
      this.keywordDraft = this.filters.keyword || ''
      this.popup.show = true
    },
    pick (key, value) {
      this.$store.dispatch('todos/setFilter', { key, value })
      if (key !== 'time') this.popup.show = false
    },
    applyKeyword () {
      this.$store.dispatch('todos/setFilter', { key: 'keyword', value: this.keywordDraft.trim() })
      this.popup.show = false
    },
    applyCustomRange () {
      if (!this.customFrom || !this.customTo) return
      const from = new Date(this.customFrom).setHours(0, 0, 0, 0)
      const to = new Date(this.customTo).setHours(23, 59, 59, 999)
      this.$store.dispatch('todos/setFilter', { key: 'customRange', value: { from, to } })
      this.popup.show = false
    },
    reset () { this.$store.dispatch('todos/resetFilters') }
  }
}
</script>

<style scoped>
.filter-bar {
  display: flex; gap: 6px; flex-wrap: wrap;
  padding: 8px 12px;
  background: var(--bg-secondary);
  border-bottom: 1px solid var(--border);
}
.fb-chip {
  font-size: 12px; padding: 5px 10px; border-radius: 14px;
  background: var(--bg-card); color: var(--text-secondary);
  border: 1px solid var(--border);
}
.fb-chip.active { color: #fff; background: var(--accent); border-color: var(--accent); }
.fb-reset { font-size: 12px; padding: 5px 10px; border-radius: 14px; background: transparent; color: var(--priority-high); border: 0; margin-left: auto; }

.fb-popup { padding: 16px; }
.fb-popup-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; font-size: 14px; font-weight: 600; }
.fb-close { background: transparent; border: 0; color: var(--text-muted); font-size: 22px; }

.fb-options { display: flex; flex-direction: column; gap: 8px; }
.fb-opt {
  font-size: 14px; padding: 10px 14px; border-radius: 8px;
  background: var(--bg-card); color: var(--text-primary);
  border: 1px solid var(--border); text-align: left;
}
.fb-opt.active { color: #fff; background: var(--accent); border-color: var(--accent); }

.fb-custom-range { display: flex; flex-direction: column; gap: 8px; margin-top: 8px; padding: 8px; background: var(--bg-card); border-radius: 8px; }
.fb-custom-range label { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--text-secondary); }
.fb-custom-range input[type=date] { flex: 1; background: var(--bg-secondary); border: 1px solid var(--border); border-radius: 4px; padding: 4px; color: var(--text-primary); }

.fb-keyword { display: flex; gap: 8px; }
.fb-keyword input { flex: 1; background: var(--bg-card); border: 1px solid var(--border); border-radius: 8px; padding: 8px 12px; font-size: 14px; color: var(--text-primary); }
</style>
