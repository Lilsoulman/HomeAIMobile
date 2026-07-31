<template>
  <div class="year-view">
    <div class="yv-grid">
      <div
        v-for="(month, mi) in months"
        :key="mi"
        class="yv-month"
        @click="$emit('month-click', mi)"
      >
        <div class="yv-month-header">{{ monthNames[mi] }}</div>
        <div class="yv-weekdays">
          <span v-for="d in ['日', '一', '二', '三', '四', '五', '六']" :key="d">{{ d }}</span>
        </div>
        <div class="yv-grid">
          <div
            v-for="(cell, ci) in month.grid"
            :key="ci"
            :class="['yv-cell', { other: cell.other, today: isToday(cell.date) }]"
          >
            <span class="yv-day">{{ cell.date.getDate() }}</span>
            <div class="yv-dots" v-if="getEventCount(cell.date) > 0">
              <span
                v-for="(dot, di) in getDots(cell.date)"
                :key="di"
                class="yv-dot"
                :style="{ background: dot }"
              ></span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { getMonthGrid, isSameDay, dateKey } from '@/utils/date'

export default {
  name: 'YearView',
  props: {
    year: { type: Number, required: true },
    events: { type: Array, default: () => [] }
  },
  computed: {
    monthNames () {
      return ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月']
    },
    months () {
      return Array.from({ length: 12 }, (_, i) => ({
        grid: getMonthGrid(this.year, i)
      }))
    }
  },
  methods: {
    isToday (date) {
      return isSameDay(date, new Date())
    },
    getEventCount (date) {
      const key = dateKey(date)
      return this.events.filter(e => dateKey(new Date(e.date)) === key).length
    },
    getDots (date) {
      const key = dateKey(date)
      const evs = this.events.filter(e => dateKey(new Date(e.date)) === key)
      return evs.slice(0, 3).map(e => e.color)
    }
  }
}
</script>

<style scoped>
.year-view {
  background: var(--bg-card);
  border-radius: 8px;
  padding: 8px;
}
.yv-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}
.yv-month {
  padding: 4px;
}
.yv-month-header {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 4px;
  text-align: center;
}
.yv-weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  margin-bottom: 2px;
}
.yv-weekdays span {
  text-align: center;
  font-size: 9px;
  color: var(--text-muted);
}
.yv-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
}
.yv-cell {
  min-height: 24px;
  padding: 1px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  border-radius: 2px;
}
.yv-cell.other {
  opacity: 0.3;
}
.yv-cell.today {
  background: var(--accent);
  color: #fff;
}
.yv-day {
  font-size: 10px;
  font-weight: 500;
}
.yv-dots {
  display: flex;
  gap: 1px;
  margin-top: 1px;
}
.yv-dot {
  width: 4px;
  height: 4px;
  border-radius: 50%;
}
</style>