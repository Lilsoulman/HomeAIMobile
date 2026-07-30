<template>
  <section class="greet card fade-in">
    <div class="greet-hello">{{ greet }}，{{ name }}</div>
    <div class="greet-date">{{ dateText }}</div>
  </section>
</template>

<script>
import { mapState } from 'vuex'
import { getGreeting, formatDate } from '@/utils/date'

export default {
  name: 'GreetingCard',
  computed: {
    ...mapState({ lang: state => state.settings.lang, user: state => state.user.userInfo }),
    greet () { return getGreeting(this.lang) },
    dateText () { return formatDate(this.lang) },
    name () { return (this.user && this.user.name) || '用户' }
  }
}
</script>

<style scoped>
.greet { padding: 16px 18px; }
.greet-hello {
  font-size: 22px;
  font-weight: 600;
  color: var(--text-primary);
  letter-spacing: 0.5px;
}
.greet-date {
  margin-top: 4px;
  font-size: 13px;
  color: var(--text-secondary);
}
</style>
