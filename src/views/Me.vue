<template>
  <div class="me-view">
    <!-- 已登录：显示用户卡片 + 退出按钮 -->
    <template v-if="isLoggedIn">
      <div class="user-card card">
        <div class="avatar">{{ avatarText }}</div>
        <div class="info">
          <div class="name">{{ userInfo.name || userInfo.displayName || '用户' }}</div>
          <div class="sub">{{ userInfo.phone ? (userInfo.phone.slice(0, 3) + '****' + userInfo.phone.slice(-4)) : (userInfo.wechatOpenId ? '微信用户' : '已登录') }}</div>
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

      <div class="actions card">
        <el-button type="danger" plain style="width: 100%" @click="onLogout">退出登录</el-button>
      </div>
    </template>

    <!-- 未登录：显示大按钮 -->
    <template v-else>
      <div class="welcome card">
        <div class="big-avatar">👤</div>
        <div class="welcome-title">未登录</div>
        <div class="welcome-sub">登录后体验更多功能</div>
        <el-button type="primary" size="medium" style="width: 100%; margin-top: 16px" @click="goLogin">立即登录</el-button>
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
    </template>
  </div>
</template>

<script>
import { mapState, mapGetters } from 'vuex'

export default {
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
    ...mapGetters('user', ['isLoggedIn']),
    avatarText () {
      const n = this.userInfo.name || this.userInfo.displayName || '用'
      return n.slice(0, 1)
    }
  },
  methods: {
    setTheme (t) { this.$store.commit('settings/SET_THEME', t) },
    setLang (l) { this.$store.commit('settings/SET_LANG', l) },
    goLogin () {
      this.$router.push({ path: '/login', query: { from: this.$route.fullPath } })
    },
    async onLogout () {
      try {
        await this.$confirm('确认退出登录？', '提示', { type: 'warning' })
      } catch (e) { return }
      await this.$store.dispatch('user/logout')
      // 同步清空整个 user state（persistence 走全局订阅）
      this.$message.success('已退出登录')
    }
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

.welcome { padding: 32px 20px; text-align: center; }
.big-avatar { font-size: 48px; margin-bottom: 8px; }
.welcome-title { font-size: 16px; font-weight: 600; margin-bottom: 4px; }
.welcome-sub { font-size: 12px; color: var(--text-muted); }

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

.actions { padding: 12px 16px; }
</style>
