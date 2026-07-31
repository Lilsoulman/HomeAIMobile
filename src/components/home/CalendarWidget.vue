<template>
  <section class="cal-widget card fade-in">
    <header class="cw-head">
      <span class="cw-title">{{ year }}年{{ month + 1 }}月</span>
      <button class="cw-viewall" @click="goCal">查看全部 →</button>
    </header>
    <div class="cw-body">
      <div class="cw-left">
        <div class="cw-weekdays">
          <span v-for="(d, i) in weekdays" :key="d" :class="{ we: i === 0 || i === 6 }">{{ d }}</span>
        </div>
        <div class="cw-grid">
          <div
            v-for="(c, i) in grid"
            :key="i"
            class="cw-day"
            :class="{ other: c.other, today: isToday(c.date), we: c.date.getDay() === 0 || c.date.getDay() === 6 }"
            @click="openDay(c)"
          >
            <span class="cw-num">{{ c.date.getDate() }}</span>
            <div class="cw-chips" v-if="dayChips(c.date).length">
              <span
                v-for="(chip, idx) in dayChips(c.date).slice(0, 2)"
                :key="idx"
                class="cw-chip"
                :style="{ background: chip.color }"
              >{{ chip.title }}</span>
              <span v-if="dayChips(c.date).length > 2" class="cw-chip-more">+{{ dayChips(c.date).length - 2 }}</span>
            </div>
          </div>
        </div>
      </div>
      <div class="cw-right">
        <div v-if="upcoming.length" class="cw-upcoming">
          <div v-for="g in upcoming" :key="g.offset" class="cw-group">
            <div class="cw-group-label">{{ labelOf(g) }}</div>
            <div v-for="ev in g.events" :key="ev.id" class="cw-ev">
              <span class="cw-ev-dot" :style="{ background: ev.color }" />
              <span class="cw-ev-time">{{ timeOf(ev) }}</span>
              <span class="cw-ev-text">{{ ev.title }}</span>
            </div>
          </div>
        </div>
        <div v-else class="cw-empty">近 3 天无日程</div>
      </div>
    </div>
    <van-popup v-model="popup.show" position="bottom" round :style="{ maxHeight: '60vh' }">
      <div class="cw-popup">
        <header class="cw-popup-head">
          <span>{{ popup.date }}</span>
          <button class="cw-popup-close" @click="popup.show = false">×</button>
        </header>
        <div class="cw-popup-body">
          <div v-if="popup.events.length === 0" class="cw-empty">无日程</div>
          <div v-for="ev in popup.events" :key="ev.id" class="cw-ev cw-ev-popup">
            <span class="cw-ev-dot" :style="{ background: ev.color }" />
            <span class="cw-ev-time">{{ timeOf(ev) }}</span>
            <span class="cw-ev-text">{{ ev.title }}</span>
          </div>
        </div>
      </div>
    </van-popup>
  </section>
</template>

<script>
import { mapState, mapGetters } from 'vuex'
import { getMonthGrid, isSameDay, dateKey } from '@/utils/date'
import { track } from '@/utils/track'

export default {
  name: 'CalendarWidget',
  data () {
    return {
      now: new Date(),
      popup: { show: false, date: '', events: [] }
    }
  },
  computed: {
    ...mapState(['settings']),
    ...mapGetters('calendar', ['upcoming']),
    year () { return this.now.getFullYear() },
    month () { return this.now.getMonth() },
    weekdays () {
      return this.settings.lang === 'zh'
        ? ['日', '一', '二', '三', '四', '五', '六']
        : ['S', 'M', 'T', 'W', 'T', 'F', 'S']
    },
    grid () { return getMonthGrid(this.year, this.month) },
    upcoming () {
      return this.$store.getters['calendar/upcoming'](3)
    }
  },
  methods: {
    isToday (d) { return isSameDay(d, this.now) },
    labelOf (g) {
      if (g.offset === 0) return '今天'
      if (g.offset === 1) return '明天'
      return `${g.date.getMonth() + 1}/${g.date.getDate()}`
    },
    timeOf (ev) {
      if (ev.allDay) return '全天'
      const d = new Date(ev.date)
      return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
    },
    dayChips (date) {
      const key = dateKey(date)
      return this.$store.getters['calendar/eventsForDate'](key)
    },
    openDay (cell) {
      const key = dateKey(cell.date)
      this.popup.date = key
      this.popup.events = this.dayChips(cell.date)
      this.popup.show = true
    },
    goCal () {
      track('home_calendar_click')
      this.$router.push('/calendar')
    }
  }
}
</script>

<style scoped>
.cal-widget { padding: 12px; }
.cw-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
.cw-title { font-size: 14px; font-weight: 600; }
.cw-viewall { background: transparent; border: 0; color: var(--accent); font-size: 12px; }

.cw-body { display: flex; gap: 10px; }
.cw-left { flex: 1; min-width: 0; }

.cw-weekdays { display: grid; grid-template-columns: repeat(7, 1fr); margin-bottom: 4px; }
.cw-weekdays span {
  text-align: center; font-size: 10px; color: var(--text-muted); padding: 2px 0;
}
.cw-weekdays span.we { color: var(--priority-high); }

.cw-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 2px; }
.cw-day {
  min-height: 36px;
  padding: 2px;
  border-radius: 4px;
  background: var(--bg-card);
  display: flex; flex-direction: column; align-items: center;
  font-size: 10px;
  cursor: pointer;
}
.cw-day.other { opacity: 0.35; }
.cw-day.today { background: var(--accent); color: #fff; }
.cw-day.today .cw-num { color: #fff; }
.cw-day.we:not(.today) .cw-num { color: var(--priority-high); }
.cw-num { font-size: 11px; font-weight: 500; }
.cw-chips { display: flex; flex-direction: column; gap: 1px; width: 100%; margin-top: 1px; }
.cw-chip {
  font-size: 8px; line-height: 1; padding: 1px 2px;
  border-radius: 2px; color: #fff;
  overflow: hidden; white-space: nowrap; text-overflow: ellipsis;
  opacity: 0.85;
}
.cw-chip-more { font-size: 8px; color: var(--text-muted); text-align: center; }

.cw-right { width: 100px; flex-shrink: 0; }
.cw-upcoming { display: flex; flex-direction: column; gap: 6px; }
.cw-group-label { font-size: 10px; color: var(--text-muted); margin-bottom: 2px; }
.cw-ev { display: flex; align-items: center; gap: 4px; font-size: 11px; min-width: 0; }
.cw-ev-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; }
.cw-ev-time { color: var(--text-muted); flex-shrink: 0; }
.cw-ev-text {
  flex: 1; min-width: 0;
  overflow: hidden; white-space: nowrap; text-overflow: ellipsis;
  color: var(--text-primary);
}
.cw-empty { font-size: 11px; color: var(--text-muted); text-align: center; padding: 10px 0; }

.cw-popup { padding: 12px; }
.cw-popup-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; }
.cw-popup-close { background: transparent; border: 0; color: var(--text-muted); font-size: 22px; }
.cw-popup-body { display: flex; flex-direction: column; gap: 6px; }
.cw-ev-popup { font-size: 13px; padding: 4px 0; }
</style>
