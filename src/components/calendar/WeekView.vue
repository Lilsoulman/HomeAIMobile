<template>
  <div class="week-view">
    <div class="wv-header">
      <div class="wv-time-gutter"></div>
      <div
        v-for="(day, i) in weekDays"
        :key="i"
        :class="['wv-day-header', { today: isToday(day.date), we: isWeekend(day.date) }]"
      >
        <span class="wv-day-name">{{ day.name }}</span>
        <span class="wv-day-num">{{ day.date.getDate() }}</span>
      </div>
    </div>
    <div class="wv-body" ref="body">
      <div class="wv-time-gutter">
        <div
          v-for="h in 24"
          :key="h"
          class="wv-hour-label"
          :style="{ height: hourHeight + 'px' }"
        >{{ h - 1 }}</div>
      </div>
      <div class="wv-days">
        <div
          v-for="(day, di) in weekDays"
          :key="di"
          class="wv-day-column"
          @click="onDayClick(day.date)"
        >
          <div
            v-for="h in 24"
            :key="h"
            class="wv-hour-slot"
            :style="{ height: hourHeight + 'px' }"
          ></div>
          <div
            v-for="ev in day.events"
            :key="ev.id"
            class="wv-event"
            :style="getEventStyle(ev)"
            @click.stop="$emit('event-click', ev)"
          >
            <span class="wv-event-title">{{ ev.title }}</span>
            <span v-if="!ev.allDay" class="wv-event-time">{{ formatTime(ev.date) }}</span>
          </div>
        </div>
      </div>
      <div
        v-if="showNowLine"
        class="wv-now-line"
        :style="{ top: nowLineTop + 'px' }"
      ></div>
    </div>
  </div>
</template>

<script>
import { dateKey } from '@/utils/date'

export default {
  name: 'WeekView',
  props: {
    date: { type: Date, required: true },
    events: { type: Array, default: () => [] }
  },
  data () {
    return {
      hourHeight: 48
    }
  },
  computed: {
    weekDays () {
      const start = this.getWeekStart(this.date)
      const days = []
      const names = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
      for (let i = 0; i < 7; i++) {
        const d = new Date(start)
        d.setDate(d.getDate() + i)
        const key = dateKey(d)
        const evs = this.events.filter(e => dateKey(new Date(e.date)) === key)
        days.push({ date: d, name: names[d.getDay()], events: evs })
      }
      return days
    },
    showNowLine () {
      const today = new Date()
      return this.weekDays.some(d => this.isSameDay(d.date, today))
    },
    nowLineTop () {
      const now = new Date()
      const todayKey = dateKey(now)
      const idx = this.weekDays.findIndex(d => dateKey(d.date) === todayKey)
      if (idx < 0) return 0
      const hours = now.getHours() + now.getMinutes() / 60
      return hours * this.hourHeight
    }
  },
  methods: {
    getWeekStart (date) {
      const d = new Date(date)
      const day = d.getDay()
      d.setDate(d.getDate() - day)
      d.setHours(0, 0, 0, 0)
      return d
    },
    isToday (date) {
      return this.isSameDay(date, new Date())
    },
    isSameDay (a, b) {
      return a.getFullYear() === b.getFullYear() &&
        a.getMonth() === b.getMonth() &&
        a.getDate() === b.getDate()
    },
    isWeekend (date) {
      const day = date.getDay()
      return day === 0 || day === 6
    },
    getEventStyle (ev) {
      if (ev.allDay) {
        return {
          background: ev.color,
          top: '0',
          height: '20px'
        }
      }
      const d = new Date(ev.date)
      const hours = d.getHours() + d.getMinutes() / 60
      const duration = (ev.duration || 60) / 60
      return {
        background: ev.color,
        top: (hours * this.hourHeight) + 'px',
        height: (duration * this.hourHeight) + 'px'
      }
    },
    formatTime (ts) {
      const d = new Date(ts)
      return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
    },
    onDayClick (date) {
      this.$emit('time-click', date)
    }
  }
}
</script>

<style scoped>
.week-view {
  background: var(--bg-card);
  border-radius: 8px;
  overflow: hidden;
}
.wv-header {
  display: flex;
  border-bottom: 1px solid var(--border);
}
.wv-time-gutter {
  width: 40px;
  flex-shrink: 0;
}
.wv-day-header {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px 0;
  font-size: 12px;
}
.wv-day-header.today {
  background: var(--accent);
  color: #fff;
}
.wv-day-header.we:not(.today) .wv-day-name {
  color: var(--priority-high);
}
.wv-day-name {
  font-size: 11px;
  color: var(--text-muted);
}
.wv-day-num {
  font-size: 16px;
  font-weight: 600;
}
.wv-body {
  position: relative;
  display: flex;
  max-height: 600px;
  overflow-y: auto;
}
.wv-time-gutter {
  width: 40px;
  flex-shrink: 0;
}
.wv-hour-label {
  font-size: 10px;
  color: var(--text-muted);
  text-align: right;
  padding-right: 4px;
  border-bottom: 1px solid var(--border);
}
.wv-days {
  flex: 1;
  display: flex;
  position: relative;
}
.wv-day-column {
  flex: 1;
  position: relative;
  border-left: 1px solid var(--border);
}
.wv-hour-slot {
  border-bottom: 1px solid var(--border);
}
.wv-event {
  position: absolute;
  left: 2px;
  right: 2px;
  padding: 2px 4px;
  border-radius: 4px;
  color: #fff;
  font-size: 11px;
  overflow: hidden;
  cursor: pointer;
  z-index: 1;
}
.wv-event-title {
  display: block;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}
.wv-event-time {
  font-size: 10px;
  opacity: 0.8;
}
.wv-now-line {
  position: absolute;
  left: 40px;
  right: 0;
  height: 2px;
  background: red;
  z-index: 2;
}
</style>