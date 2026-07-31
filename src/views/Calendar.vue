<template>
  <div class="calendar-page">
    <header class="cal-header">
      <button class="cal-nav-btn" @click="prev">‹</button>
      <h2 class="cal-title">{{ title }}</h2>
      <button class="cal-nav-btn" @click="next">›</button>
      <button class="cal-today-btn" @click="goToday">今天</button>
    </header>

    <div class="cal-view-tabs">
      <button
        v-for="v in views"
        :key="v.key"
        :class="['cal-tab', { active: currentView === v.key }]"
        @click="currentView = v.key"
      >{{ v.label }}</button>
    </div>

    <div class="cal-content">
      <MonthView
        v-if="currentView === 'month'"
        :year="currentYear"
        :month="currentMonth"
        :events="events"
        @day-click="onDayClick"
        @event-click="onEventClick"
      />
      <WeekView
        v-if="currentView === 'week'"
        :date="currentDate"
        :events="events"
        @event-click="onEventClick"
        @time-click="onTimeClick"
      />
      <DayView
        v-if="currentView === 'day'"
        :date="currentDate"
        :events="events"
        @event-click="onEventClick"
        @time-click="onTimeClick"
      />
      <YearView
        v-if="currentView === 'year'"
        :year="currentYear"
        :events="events"
        @month-click="onMonthClick"
        @event-click="onEventClick"
      />
    </div>

    <button class="cal-add-btn" @click="openCreate">+</button>

    <van-popup v-model="editor.show" position="bottom" round :style="{ maxHeight: '80vh' }">
      <EventEditor
        :event="editor.event"
        @save="onSave"
        @delete="onDelete"
        @close="editor.show = false"
      />
    </van-popup>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex'
import { dateKey } from '@/utils/date'
import MonthView from '@/components/calendar/MonthView.vue'
import WeekView from '@/components/calendar/WeekView.vue'
import DayView from '@/components/calendar/DayView.vue'
import YearView from '@/components/calendar/YearView.vue'
import EventEditor from '@/components/calendar/EventEditor.vue'

export default {
  name: 'CalendarPage',
  components: { MonthView, WeekView, DayView, YearView, EventEditor },
  data () {
    return {
      currentView: 'month',
      currentDate: new Date(),
      views: [
        { key: 'month', label: '月' },
        { key: 'week', label: '周' },
        { key: 'day', label: '日' },
        { key: 'year', label: '年' }
      ],
      editor: { show: false, event: null }
    }
  },
  computed: {
    ...mapState('calendar', ['events']),
    currentYear () { return this.currentDate.getFullYear() },
    currentMonth () { return this.currentDate.getMonth() },
    title () {
      const y = this.currentYear
      const m = this.currentDate.getMonth() + 1
      const d = this.currentDate.getDate()
      switch (this.currentView) {
        case 'month': return `${y}年${m}月`
        case 'week': {
          const start = this.getWeekStart(this.currentDate)
          const end = new Date(start)
          end.setDate(end.getDate() + 6)
          return `${start.getMonth() + 1}/${start.getDate()} - ${end.getMonth() + 1}/${end.getDate()}`
        }
        case 'day': return `${y}年${m}月${d}日`
        case 'year': return `${y}年`
        default: return ''
      }
    }
  },
  created () {
    this.load()
  },
  methods: {
    ...mapActions('calendar', ['load', 'createEvent', 'updateEvent', 'deleteEvent']),
    prev () {
      const d = new Date(this.currentDate)
      switch (this.currentView) {
        case 'month': d.setMonth(d.getMonth() - 1); break
        case 'week': d.setDate(d.getDate() - 7); break
        case 'day': d.setDate(d.getDate() - 1); break
        case 'year': d.setFullYear(d.getFullYear() - 1); break
      }
      this.currentDate = d
    },
    next () {
      const d = new Date(this.currentDate)
      switch (this.currentView) {
        case 'month': d.setMonth(d.getMonth() + 1); break
        case 'week': d.setDate(d.getDate() + 7); break
        case 'day': d.setDate(d.getDate() + 1); break
        case 'year': d.setFullYear(d.getFullYear() + 1); break
      }
      this.currentDate = d
    },
    goToday () {
      this.currentDate = new Date()
    },
    getWeekStart (date) {
      const d = new Date(date)
      const day = d.getDay()
      d.setDate(d.getDate() - day)
      d.setHours(0, 0, 0, 0)
      return d
    },
    onDayClick (date) {
      this.currentDate = new Date(date)
      this.currentView = 'day'
    },
    onMonthClick (month) {
      this.currentDate = new Date(this.currentYear, month, 1)
      this.currentView = 'month'
    },
    onEventClick (event) {
      this.editor.event = { ...event }
      this.editor.show = true
    },
    onTimeClick (date) {
      this.editor.event = {
        id: null,
        title: '',
        date: date.getTime(),
        duration: 60,
        allDay: false,
        color: '#6366f1',
        type: 'work',
        location: '',
        description: '',
        source: 'local'
      }
      this.editor.show = true
    },
    openCreate () {
      this.editor.event = {
        id: null,
        title: '',
        date: new Date().getTime(),
        duration: 60,
        allDay: false,
        color: '#6366f1',
        type: 'work',
        location: '',
        description: '',
        source: 'local'
      }
      this.editor.show = true
    },
    async onSave (event) {
      if (event.id) {
        await this.updateEvent(event)
      } else {
        await this.createEvent(event)
      }
      this.editor.show = false
    },
    async onDelete (id) {
      await this.deleteEvent(id)
      this.editor.show = false
    }
  }
}
</script>

<style scoped>
.calendar-page {
  min-height: 100vh;
  background: var(--bg-primary);
  padding-bottom: 60px;
}
.cal-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  background: var(--bg-card);
  border-bottom: 1px solid var(--border);
}
.cal-nav-btn {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text-primary);
  font-size: 18px;
}
.cal-title {
  flex: 1;
  font-size: 18px;
  font-weight: 600;
  color: var(--text-primary);
  margin: 0;
}
.cal-today-btn {
  padding: 6px 12px;
  background: var(--accent);
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 13px;
}
.cal-view-tabs {
  display: flex;
  gap: 4px;
  padding: 8px 16px;
  background: var(--bg-card);
  border-bottom: 1px solid var(--border);
}
.cal-tab {
  flex: 1;
  padding: 8px;
  background: transparent;
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text-secondary);
  font-size: 13px;
}
.cal-tab.active {
  background: var(--accent);
  color: #fff;
  border-color: var(--accent);
}
.cal-content {
  padding: 8px;
}
.cal-add-btn {
  position: fixed;
  bottom: 80px;
  right: 20px;
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: var(--accent);
  color: #fff;
  border: none;
  font-size: 28px;
  box-shadow: 0 4px 12px var(--accent-glow);
  z-index: 10;
}
</style>