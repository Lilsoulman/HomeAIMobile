<template>
  <div class="month-view">
    <div class="mv-weekdays">
      <span v-for="(d, i) in weekdays" :key="i" :class="{ we: i === 0 || i === 6 }">{{ d }}</span>
    </div>
    <div class="mv-grid">
      <div
        v-for="(cell, i) in grid"
        :key="i"
        :class="['mv-cell', { other: cell.other, today: isToday(cell.date), we: isWeekend(cell.date) }]"
        @click="$emit('day-click', cell.date)"
      >
        <span class="mv-day">{{ cell.date.getDate() }}</span>
        <div class="mv-events">
          <div
            v-for="(ev, idx) in getEvents(cell.date).slice(0, 3)"
            :key="ev.id"
            :class="['mv-event', { 'mv-event-all': ev.allDay }]"
            :style="{ background: ev.color }"
            @click.stop="$emit('event-click', ev)"
          >
            <span class="mv-event-title">{{ ev.title }}</span>
            <span v-if="!ev.allDay" class="mv-event-time">{{ formatTime(ev.date) }}</span>
          </div>
          <div v-if="getEvents(cell.date).length > 3" class="mv-more">
            +{{ getEvents(cell.date).length - 3 }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { getMonthGrid, isSameDay, dateKey } from '@/utils/date'

export default {
  name: 'MonthView',
  props: {
    year: { type: Number, required: true },
    month: { type: Number, required: true },
    events: { type: Array, default: () => [] }
  },
  computed: {
    weekdays () {
      return ['日', '一', '二', '三', '四', '五', '六']
    },
    grid () {
      return getMonthGrid(this.year, this.month)
    }
  },
  methods: {
    isToday (date) {
      return isSameDay(date, new Date())
    },
    isWeekend (date) {
      const day = date.getDay()
      return day === 0 || day === 6
    },
    getEvents (date) {
      const key = dateKey(date)
      return this.events.filter(e => dateKey(new Date(e.date)) === key)
    },
    formatTime (ts) {
      const d = new Date(ts)
      return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
    }
  }
}
</script>

<style scoped>
.month-view {
  background: var(--bg-card);
  border-radius: 8px;
  padding: 8px;
}
.mv-weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  margin-bottom: 4px;
}
.mv-weekdays span {
  text-align: center;
  font-size: 12px;
  color: var(--text-muted);
  padding: 4px 0;
}
.mv-weekdays span.we {
  color: var(--priority-high);
}
.mv-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
}
.mv-cell {
  min-height: 80px;
  padding: 4px;
  border-radius: 4px;
  background: var(--bg-secondary);
  cursor: pointer;
}
.mv-cell.other {
  opacity: 0.4;
}
.mv-cell.today {
  background: var(--accent);
  color: #fff;
}
.mv-cell.today .mv-day {
  color: #fff;
}
.mv-cell.we:not(.today) .mv-day {
  color: var(--priority-high);
}
.mv-day {
  font-size: 12px;
  font-weight: 500;
  display: block;
  margin-bottom: 2px;
}
.mv-events {
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.mv-event {
  padding: 2px 4px;
  border-radius: 2px;
  color: #fff;
  font-size: 10px;
  line-height: 1.2;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  cursor: pointer;
}
.mv-event-all {
  padding: 2px 4px;
}
.mv-event-title {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
}
.mv-event-time {
  font-size: 9px;
  opacity: 0.8;
  margin-left: 4px;
}
.mv-more {
  font-size: 10px;
  color: var(--text-muted);
  text-align: center;
}
</style>