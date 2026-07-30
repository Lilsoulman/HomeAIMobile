<template>
  <div class="me-view">
    <div class="user-card card">
      <div class="avatar">{{ avatarText }}</div>
      <div class="info">
        <div class="name">{{ userInfo.name }}</div>
        <div class="sub">未登录 · 首版仅展示</div>
      </div>
    </div>

    <div class="settings card">
      <div class="set-head">外观</div>
      <div class="theme-row">
        <button
          v-for="t in themes"
          :key="t.key"
          class="theme-btn"
          :class="{ active: theme === t.key }"
          :style="{ '--swatch': t.color }"
          @click="setTheme(t.key)"
        >{{ t.label }}</button>
      </div>

      <div class="set-head">语言</div>
      <div class="theme-row">
        <button
          v-for="l in langs"
          :key="l.key"
          class="theme-btn"
          :class="{ active: lang === l.key }"
          @click="setLang(l.key)"
        >{{ l.label }}</button>
      </div>
    </div>

    <Placeholder icon="👤" title="账号" sub="完整版：JWT 登录/注册、设置云同步" />
  </div>
</template>

<script>
import { mapState } from 'vuex'
import Placeholder from './Placeholder.vue'

export default {
  components: { Placeholder },
  data () {
    return {
      themes: [
        { key: 'violet', label: '紫', color: '#6366f1' },
        { key: 'ocean', label: '蓝', color: '#38bdf8' },
        { key: 'light', label: '亮', color: '#a855f7' }
      ],
      langs: [
        { key: 'zh', label: '中文' },
        { key: 'en', label: 'EN' }
      ]
    }
  },
  computed: {
    ...mapState({ theme: s => s.settings.theme, lang: s => s.settings.lang, userInfo: s => s.user.userInfo }),
    avatarText () { return (this.userInfo.name || '用').slice(0, 1) }
  },
  methods: {
    setTheme (t) { this.$store.commit('settings/SET_THEME', t) },
    setLang (l) { this.$store.commit('settings/SET_LANG', l) }
  }
}
</script>

<style scoped>
.me-view { padding: 12px 14px; display: flex; flex-direction: column; gap: 12px; }
.user-card { display: flex; align-items: center; gap: 12px; padding: 16px; }
.avatar {
  width: 48px; height: 48px; border-radius: 50%;
  background: var(--accent); color: #fff;
  display: flex; align-items: center; justify-content: center;
  font-size: 18px; font-weight: 600;
}
.info .name { font-size: 16px; font-weight: 600; }
.info .sub { font-size: 11px; color: var(--text-muted); }

.settings { padding: 12px 16px; }
.set-head { font-size: 12px; color: var(--text-muted); margin: 8px 0 6px; }
.set-head:first-child { margin-top: 0; }
.theme-row { display: flex; gap: 8px; }
.theme-btn {
  flex: 1; padding: 8px 0;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 8px;
  color: var(--text-secondary);
  font-size: 13px;
  position: relative;
}
.theme-btn.active {
  color: #fff;
  background: var(--swatch, var(--accent));
  border-color: var(--swatch, var(--accent));
}
</style>
