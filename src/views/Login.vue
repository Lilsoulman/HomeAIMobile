<template>
  <div class="login-view">
    <div class="hero">
      <div class="logo">🏠</div>
      <div class="title">NexusMind</div>
      <div class="sub">让待办、日历与 AI 成为一体</div>
    </div>

    <el-tabs v-model="tab" stretch class="tabs">
      <el-tab-pane label="微信一键登录" name="wechat">
        <div class="wechat-pane">
          <WechatQRPanel @success="onSuccess" @cancel="tab = 'phone'" />
        </div>
      </el-tab-pane>
      <el-tab-pane label="手机号登录" name="phone">
        <PhonePasswordForm @success="onSuccess" />
        <div class="switch-tip">
          还没有账号？<el-button type="text" @click="tab = 'register'">立即注册</el-button>
        </div>
      </el-tab-pane>
      <el-tab-pane label="注册" name="register">
        <RegisterForm @success="onSuccess" />
        <div class="switch-tip">
          已有账号？<el-button type="text" @click="tab = 'phone'">去登录</el-button>
        </div>
      </el-tab-pane>
    </el-tabs>

    <div class="footer">
      <el-checkbox v-model="agreed">我已阅读并同意 <el-button type="text">服务协议</el-button> 与 <el-button type="text">隐私政策</el-button></el-checkbox>
    </div>
  </div>
</template>

<script>
import WechatQRPanel from '@/components/login/WechatQRPanel.vue'
import PhonePasswordForm from '@/components/login/PhonePasswordForm.vue'
import RegisterForm from '@/components/login/RegisterForm.vue'

export default {
  name: 'Login',
  components: { WechatQRPanel, PhonePasswordForm, RegisterForm },
  data () {
    return {
      tab: 'wechat',
      agreed: false
    }
  },
  methods: {
    onSuccess () {
      // 已登录，跳回上一页或首页
      const from = (this.$route.query.from && String(this.$route.query.from)) || '/me'
      this.$router.replace(from)
    }
  }
}
</script>

<style scoped>
.login-view {
  min-height: 100vh;
  padding: 48px 24px 32px;
  display: flex;
  flex-direction: column;
  gap: 24px;
  background: var(--bg-primary, #0f172a);
  color: var(--text-primary, #e0e7ff);
  padding-bottom: calc(32px + env(safe-area-inset-bottom));
}
.hero { text-align: center; padding: 16px 0 8px; }
.logo { font-size: 48px; margin-bottom: 8px; }
.title { font-size: 24px; font-weight: 700; margin-bottom: 4px; }
.sub { font-size: 13px; color: var(--text-muted, rgba(255,255,255,0.3)); }
.tabs { background: var(--bg-card, rgba(255,255,255,0.035)); border-radius: 12px; padding: 12px 16px; }
.wechat-pane { padding: 16px 0; }
.switch-tip { text-align: center; font-size: 12px; color: var(--text-muted); margin-top: 8px; }
.footer { margin-top: auto; text-align: center; font-size: 11px; color: var(--text-muted); }
</style>
