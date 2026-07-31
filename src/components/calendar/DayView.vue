<template>
  <div class="day-view">
    <div class="dv-header">
      <div class="dv-time-gutter"></div>
      <div :class="['dv-day-header', { today: isToday(date) }]">
        <span class="dv-day-name">{{ dayName }}</span>
        <span class="dv-day-num">{{ date.getDate() }}</span>
      </div>
    </div>
    <div class="dv-body" ref="body">
      <div class="dv-time-gutter">
        <div
          v-for="h in 24"
          :key="h"
          class="dv-hour-label"
          :style="{ height: hourHeight + 'px' }"
        >{{ h - 1 }}</div>
      </div>
      <div class="dv-day-column" @click="onDayClick">
        <div
          v-for="h in 24"
          :key="h"
          class="dv-hour-slot"
          :style="{ height: hourHeight + 'px' }"
        ></div>
        <div
          v-for="ev in dayEvents"
          :key="ev.id"
          class="dv-event"
          :style="getEventStyle(ev)"
          @click.stop="$emit('event-click', ev)"
        >
          <span class="dv-event-title">{{ ev.title }}</span>
          <span v-if="!ev.allDay" class="dv-event-time">{{ formatTime(ev.date) }} - {{ endTime(ev) }}</span>
        </div>
      </div>
      <div
        v-if="isToday(date)"
        class="dv-now-line"
        :style="{ top: nowLineTop + 'px' }"
      ></div>
    </div>
  </div>
</template>

<script>
import { dateKey } from '@/utils/date'

export default {
  name: 'DayView',
  props: {
    date: { type: Date, required: true },
    events: { type: Array, default: () => [] }
  },
  data () {
    return {
      hourHeight: 56
    }
  },
  computed: {
    dayName () {
      const names = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
      return names[this.date.getDay()]
    },
    dayEvents () {
      const key = dateKey(this.date)
      return this.events.filter(e => dateKey(new Date(e.date)) === key)
    },
    nowLineTop () {
      const now = new Date()
      const hours = now.getHours() + now.getMinutes() / 60
      return hours * this.hourHeight
    }
  },
  methods: {
    isToday (date) {
      const today = new Date()
      return date.getFullYear() === today.getFullYear() &&
        date.getMonth() === today.getMonth() &&
        date.getDate() === today.getDate()
    },
    getEventStyle (ev) {
      if (ev.allDay) {
        return {
          background: ev.color,
          top: '0',
          height: '24px'
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
    endTime (ev) {
      if (ev.allDay) return '全天'
      const d = new Date(ev.date + (ev.duration || 60) * 60000)
      return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
    },
    onDayClick (e) {
      const rect = e.currentTarget.getBoundingClientRect()
      const y = e.clientY - rect.top
      const hours = y / this.hourHeight
      const h = Math.floor(hours)
      const m = Math.round((hours - h) * 60)
      const date = new Date(this.date)
      date.setHours(h, m, 0, 0)
      this.$emit('time-click', date)
    }
  }
}
</script>

<style scoped>
.day-view {
  background: var(--bg-card);
  border-radius: 8px;
  overflow: hidden;
}
.dv-header {
  display: flex;
  border-bottom: 1px solid var(--border);
}
.dv-time-gutter {
  width: 40px;
  flex-shrink: 0;
}
.dv-day-header {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 12px 0;
}
.dv-day-header.today {
  background: var(--accent);
  color: #fff;
}
.dv-day-name {
  font-size: 12px;
  color: var(--text-muted);
}
.dv-day-header.today .dv-day-name {
  color: #fff;
}
.dv-day-num {
  font-size: 24px;
  font-weight: 600;
}
.dv-body {
  position: relative;
  display: flex;
  max-height: 600px;
  overflow-y: auto;
}
.dv-time-gutter {
  width: 40px;
  flex-shrink: 0;
}
.dv-hour-label {
  font-size: 11px;
  color: var(--text-muted);
  text-align: right;
  padding-right: 4px;
  border-bottom: 1px solid var(--border);
}
.dv-day-column {
  flex: 1;
  position: relative;
  border-left: 1px solid var(--border);
}
.dv-hour-slot {
  border-bottom: 1px solid var(--border);
}
.dv-event {
  position: absolute;
  left: 4px;
  right: 4px;
  padding: 4px 6px;
  border-radius: 4px;
  color: #fff;
  font-size: 12px;
  overflow: hidden;
  cursor: pointer;
  z-index: 1;
}
.dv-event-title {
  display: block;
  font-weight: 500;
}
.dv-event-time {
  font-size: 11px;
  opacity: 0.8;
}
.dv-now-line {
  position: absolute;
  left: 40px;
  right: 0;
  height: 2px;
  background: red;
  z-index: 2;
}
</style>