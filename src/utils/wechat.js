// 微信 OAuth 2.0 扫码登录工具
// 真后端：前端只需拿到 sceneId → 展示后端返回的二维码图片 → 轮询 /auth/wechat/status/{sceneId} 拿 code
// 真后端不再调前端，前端不再直接拼 https://open.weixin.qq.com/connect/qrconnect URL
// （避免暴露 AppId 和回调域）

import { authApi } from '@/services/api'

// 申请二维码 sceneId
export async function requestWechatQrcode () {
  const res = await authApi.wechatQrcode()
  if (!res) throw new Error('申请微信二维码失败')
  return res // { sceneId, qrcodeUrl, expiresIn }
}

// 轮询扫码状态
// 返回 Promise<{ status: 'waiting' | 'scanned' | 'expired', code? }>
// onTick 每次轮询回调（用于 UI 显示倒计时）
export function pollWechatStatus (sceneId, { onTick, interval = 1500, timeout = 5 * 60 * 1000 } = {}) {
  return new Promise((resolve, reject) => {
    const start = Date.now()
    const tick = async () => {
      if (Date.now() - start > timeout) {
        return reject(new Error('二维码已过期，请刷新重试'))
      }
      try {
        const r = await authApi.wechatStatus(sceneId)
        if (onTick) onTick(r)
        if (r && r.status === 'scanned' && r.code) {
          return resolve(r)
        }
        if (r && r.status === 'expired') {
          return reject(new Error('二维码已过期'))
        }
        setTimeout(tick, interval)
      } catch (e) {
        reject(e)
      }
    }
    tick()
  })
}
