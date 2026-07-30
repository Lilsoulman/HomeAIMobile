<template>
  <div class="home-view">
    <GreetingCard />
    <WeatherCard />
    <TodayStatsCard />
    <TodoWidget />
    <CalendarWidget />
    <QuickEntries />
  </div>
</template>

<script>
import GreetingCard from '@/components/home/GreetingCard.vue'
import WeatherCard from '@/components/home/WeatherCard.vue'
import TodayStatsCard from '@/components/home/TodayStatsCard.vue'
import TodoWidget from '@/components/home/TodoWidget.vue'
import CalendarWidget from '@/components/home/CalendarWidget.vue'
import QuickEntries from '@/components/home/QuickEntries.vue'

export default {
  name: 'Home',
  components: { GreetingCard, WeatherCard, TodayStatsCard, TodoWidget, CalendarWidget, QuickEntries },
  mounted () {
    this.$store.dispatch('todos/load').catch(() => {})
    this.$store.dispatch('calendar/load').catch(() => {})
  }
}
</script>

<style scoped>
.home-view {
  padding: 12px 14px 24px;
  display: flex; flex-direction: column; gap: 12px;
}
</style>
