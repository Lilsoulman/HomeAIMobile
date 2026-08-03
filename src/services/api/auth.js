// 鉴权 API：register / login / refresh / me / wechat
// 统一走 services/http（已带 JWT 注入 + 响应解包）
import http from '../http'

export const authApi = {
  register: (payload) => http.post('/auth/register', payload),
  login: (payload) => http.post('/auth/login', payload),
  refresh: (refreshToken) => http.post('/auth/refresh', { refreshToken }),
  me: () => http.get('/auth/me'),

  // 微信一键登录（OAuth 2.0 扫码流程）
  // 流程：前端 GET /auth/wechat/qrcode 拿 sceneId → 用二维码展示给用户
  //       → 轮询 GET /auth/wechat/status/{sceneId} 拿到 scanned + code
  //       → POST /auth/wechat { code } 拿 JWT
  wechatQrcode: () => http.get('/auth/wechat/qrcode'),
  wechatStatus: (sceneId) => http.get('/auth/wechat/status/' + sceneId),
  wechatLogin: (code) => http.post('/auth/wechat', { code })
}
