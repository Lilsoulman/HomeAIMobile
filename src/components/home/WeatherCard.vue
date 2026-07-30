<template>
  <section class="weather card fade-in">
    <div class="weather-loading" v-if="loading">
      <div class="spinner" />
      <span>天气加载中…</span>
    </div>
    <div class="weather-empty" v-else-if="!data">
      <span>📍</span><span>{{ settings.weatherCity || '未定位' }}</span>
    </div>
    <template v-else>
      <div class="weather-header">
        <span class="city">📍 {{ settings.weatherCity || '当前位置' }}</span>
      </div>
      <div class="weather-current">
        <span class="icon">{{ icon }}</span>
        <span class="temp">{{ Math.round(data.current.temperature_2m) }}°</span>
        <span class="desc">{{ desc }}</span>
      </div>
      <div class="weather-meta">
        <span>湿度 {{ data.current.relative_humidity_2m }}%</span>
        <span>风速 {{ data.current.wind_speed_10m }} km/h</span>
      </div>
      <div class="weather-forecast" v-if="forecast.length">
        <div v-for="(d, i) in forecast" :key="i" class="fc-day">
          <span class="fc-name">{{ d.name }}</span>
          <span class="fc-icon">{{ d.icon }}</span>
          <span class="fc-temp">{{ d.lo }}°/{{ d.hi }}°</span>
        </div>
      </div>
    </template>
  </section>
</template>

<script>
import { mapState } from 'vuex'
import { weatherApi } from '@/services/api'
import { getWeatherIcon, getWeatherDesc } from '@/utils/weatherCodes'

export default {
  name: 'WeatherCard',
  data () {
    return { data: null, loading: true, error: '' }
  },
  computed: {
    ...mapState(['settings']),
    icon () { return this.data ? getWeatherIcon(this.data.current.weather_code) : '☀️' },
    desc () { return this.data ? getWeatherDesc(this.data.current.weather_code, this.settings.lang) : '' },
    forecast () {
      if (!this.data || !this.data.daily) return []
      const days = this.settings.lang === 'zh' ? ['周日', '周一', '周二', '周三', '周四', '周五', '周六'] : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      const out = []
      for (let i = 1; i < this.data.daily.time.length && out.length < 3; i++) {
        const d = new Date(this.data.daily.time[i])
        out.push({
          name: days[d.getDay()],
          icon: getWeatherIcon(this.data.daily.weather_code[i]),
          lo: Math.round(this.data.daily.temperature_2m_min[i]),
          hi: Math.round(this.data.daily.temperature_2m_max[i])
        })
      }
      return out
    }
  },
  async mounted () {
    try {
      const res = await weatherApi.get()
      this.data = res.data || res
    } catch (e) {
      this.error = e.message
    } finally {
      this.loading = false
    }
  }
}
</script>

<style scoped>
.weather { padding: 14px 16px; }
.weather-loading,
.weather-empty {
  display: flex; align-items: center; gap: 8px;
  color: var(--text-muted); font-size: 13px;
  min-height: 64px;
}
.weather-header { font-size: 12px; color: var(--text-secondary); margin-bottom: 6px; }
.weather-current {
  display: flex; align-items: baseline; gap: 8px;
  margin-bottom: 6px;
}
.weather-current .icon { font-size: 28px; }
.weather-current .temp { font-size: 32px; font-weight: 600; color: var(--text-primary); }
.weather-current .desc { font-size: 14px; color: var(--text-secondary); }
.weather-meta {
  display: flex; gap: 12px;
  font-size: 12px; color: var(--text-muted);
  margin-bottom: 12px;
}
.weather-forecast {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}
.fc-day {
  display: flex; flex-direction: column; align-items: center;
  padding: 6px 4px;
  background: var(--accent-bg);
  border-radius: 8px;
  font-size: 12px;
}
.fc-icon { font-size: 18px; margin: 2px 0; }
.fc-temp { color: var(--text-secondary); font-size: 11px; }
</style>
