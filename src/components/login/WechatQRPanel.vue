<template>
  <div class="wx-panel">
    <div class="qr-box">
      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <div class="loading-text">生成二维码中…</div>
      </div>
      <template v-else>
        <!-- mock 阶段用一个占位框 + 旋转动画代替真二维码图片；
             真后端用 <img :src="qrcodeUrl" /> 即可 -->
        <div class="qr-placeholder">
          <div class="qr-icon">📱</div>
          <div class="qr-hint">请用微信扫描</div>
          <div class="qr-sceneid">{{ shortSceneId }}</div>
        </div>
      </template>
    </div>

    <div class="status">
      <template v-if="status === 'waiting'">
        <span class="dot"></span> 等待扫码…
      </template>
      <template v-else-if="status === 'scanned'">
        <span class="dot green"></span> 扫码成功，正在登录…
      </template>
      <template v-else-if="status === 'expired'">
        <span class="dot red"></span> 已过期
      </template>
      <template v-else>
        <span class="dot"></span> 初始化
      </template>
    </div>

    <div class="footer">
      <el-button v-if="status === 'expired'" type="text" @click="refresh">刷新二维码</el-button>
      <el-button v-else type="text" @click="$emit('cancel')">取消</el-button>
    </div>
  </div>
</template>

<script>
import { requestWechatQrcode, pollWechatStatus } from '@/utils/wechat'

export default {
  name: 'WechatQRPanel',
  data () {
    return {
      loading: true,
      sceneId: '',
      qrcodeUrl: '',
      status: 'init',
      stopPolling: null
    }
  },
  computed: {
    shortSceneId () {
      if (!this.sceneId) return ''
      return this.sceneId.slice(0, 16) + '…'
    }
  },
  async mounted () {
    await this.refresh()
  },
  beforeDestroy () {
    if (this.stopPolling) this.stopPolling = null
  },
  methods: {
    async refresh () {
      this.loading = true
      this.status = 'init'
      try {
        const r = await requestWechatQrcode()
        this.sceneId = r.sceneId
        this.qrcodeUrl = r.qrcodeUrl
        this.loading = false
        this.startPoll()
      } catch (e) {
        this.loading = false
        this.$message.error(e.message || '二维码申请失败')
      }
    },
    startPoll () {
      this.status = 'waiting'
      pollWechatStatus(this.sceneId, {
        interval: 1500,
        onTick: (r) => { if (r) this.status = r.status }
      }).then(async (r) => {
        this.status = 'scanned'
        try {
          await this.$store.dispatch('user/loginWithWechat', { code: r.code })
          this.$message.success('微信登录成功')
          this.$emit('success')
        } catch (e) {
          this.$message.error(e.message || '登录失败')
          this.status = 'waiting'
        }
      }).catch((e) => {
        this.status = 'expired'
        this.$message.warning(e.message || '扫码超时')
      })
    }
  }
}
</script>

<style scoped>
.wx-panel {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px 0;
}
.qr-box {
  width: 200px; height: 200px;
  background: var(--bg-secondary, #fff);
  border: 1px solid var(--border, #e5e7eb);
  border-radius: 8px;
  display: flex; align-items: center; justify-content: center;
  position: relative;
}
.loading { text-align: center; }
.spinner {
  width: 24px; height: 24px;
  border: 2px solid var(--accent, #6366f1);
  border-top-color: transparent;
  border-radius: 50%;
  margin: 0 auto 8px;
  animation: spin 0.8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
.loading-text { font-size: 12px; color: var(--text-muted); }
.qr-placeholder {
  text-align: center;
  padding: 20px;
}
.qr-icon { font-size: 48px; margin-bottom: 8px; }
.qr-hint { font-size: 12px; color: var(--text-secondary); margin-bottom: 6px; }
.qr-sceneid {
  font-size: 10px; color: var(--text-muted);
  font-family: monospace;
  background: var(--accent-bg, rgba(99,102,241,0.1));
  padding: 2px 6px; border-radius: 4px;
  display: inline-block;
}
.status {
  margin-top: 16px;
  font-size: 13px;
  color: var(--text-secondary);
  display: flex; align-items: center; gap: 6px;
}
.dot {
  width: 6px; height: 6px; border-radius: 50%;
  background: var(--text-muted);
  animation: pulse 1.4s ease-in-out infinite;
}
.dot.green { background: #10b981; }
.dot.red { background: #ef4444; }
@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
.footer { margin-top: 8px; }
</style>
