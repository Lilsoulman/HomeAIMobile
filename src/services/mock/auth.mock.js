// Auth 模块 mock：login / register / refresh / me + 微信扫码流程
// 数据全内存；accessToken 形如 mock-jwt-<ts>，refreshToken 形如 mock-rt-<ts>
import { ok, fail } from './response'

const users = [
  { id: 1, phone: '13800000000', displayName: '测试用户', avatar: '', wechatOpenId: 'mock-openid-1' }
]
const tokens = new Map() // accessToken -> userId

// 微信扫码场景：sceneId -> { createdAt, status: 'waiting' | 'scanned', code }
const wxScenes = new Map()

function makeToken (userId) {
  const accessToken = 'mock-jwt-' + userId + '-' + Date.now()
  const refreshToken = 'mock-rt-' + userId + '-' + Date.now()
  tokens.set(accessToken, userId)
  return { accessToken, refreshToken }
}

function userByPhone (phone) {
  return users.find(u => u.phone === phone)
}

function userByOpenId (openId) {
  return users.find(u => u.wechatOpenId === openId)
}

function userById (id) {
  return users.find(u => u.id === id)
}

function userFromHeader (config) {
  const auth = config.headers && (config.headers.Authorization || config.headers.authorization)
  if (!auth) return null
  const m = /^Bearer\s+(.+)$/.exec(auth)
  if (!m) return null
  const userId = tokens.get(m[1])
  if (!userId) return null
  return userById(userId)
}

// 清理过期 scene（5 分钟）
function gcWxScenes () {
  const now = Date.now()
  for (const [k, v] of wxScenes) {
    if (now - v.createdAt > 5 * 60 * 1000) wxScenes.delete(k)
  }
}

function randomId (prefix) {
  return prefix + '-' + Math.random().toString(36).slice(2, 10) + '-' + Date.now()
}

export function registerAuth (mock) {
  mock.onPost('/auth/register').reply(config => {
    const body = typeof config.data === 'string' ? JSON.parse(config.data || '{}') : (config.data || {})
    if (!body.phone) return [400, fail(400, 'phone required')]
    let u = userByPhone(body.phone)
    if (!u) {
      u = { id: users.length + 1, phone: body.phone, displayName: body.displayName || ('用户' + body.phone.slice(-4)), avatar: '' }
      users.push(u)
    }
    const t = makeToken(u.id)
    return [200, ok({ ...t, user: u })]
  })

  mock.onPost('/auth/login').reply(config => {
    const body = typeof config.data === 'string' ? JSON.parse(config.data || '{}') : (config.data || {})
    const u = userByPhone(body.phone)
    // mock 阶段不校验密码；找不到用户也允许以 phone 自动注册一个
    const user = u || { id: users.length + 1, phone: body.phone, displayName: '用户' + (body.phone || '').slice(-4), avatar: '' }
    if (!u) users.push(user)
    const t = makeToken(user.id)
    return [200, ok({ ...t, user })]
  })

  mock.onPost('/auth/refresh').reply(config => {
    const body = typeof config.data === 'string' ? JSON.parse(config.data || '{}') : (config.data || {})
    const old = body.refreshToken || ''
    const m = /^mock-rt-(\d+)-/.exec(old)
    if (!m) return [401, fail(401, 'invalid refresh token')]
    const userId = Number(m[1])
    const user = userById(userId)
    if (!user) return [401, fail(401, 'user not found')]
    const t = makeToken(userId)
    return [200, ok({ ...t, user })]
  })

  mock.onGet('/auth/me').reply(config => {
    const u = userFromHeader(config)
    if (!u) return [401, fail(401, 'unauthorized')]
    return [200, ok(u)]
  })

  // ===== 微信扫码流程 =====
  // 1) 前端申请 sceneId
  mock.onGet('/auth/wechat/qrcode').reply(() => {
    gcWxScenes()
    const sceneId = randomId('scene')
    wxScenes.set(sceneId, { createdAt: Date.now(), status: 'waiting', code: null, openId: null })
    return [200, ok({
      sceneId,
      // 真后端应返回微信开放平台二维码图片 URL；mock 用一个可识别字符串
      qrcodeUrl: 'weixin://wxpay/bizpayurl?pr=mock-' + sceneId,
      expiresIn: 300
    })]
  })

  // 2) 前端轮询状态
  // mock 行为：scene 创建 3 秒后自动变 scanned（模拟用户扫码），并附带固定的 openId
  mock.onGet(/\/auth\/wechat\/status\/.+/).reply(config => {
    gcWxScenes()
    const sceneId = config.url.split('/').pop()
    const sc = wxScenes.get(sceneId)
    if (!sc) return [404, fail(404, 'scene expired or not found')]
    // 3 秒后自动 scanned
    if (sc.status === 'waiting' && Date.now() - sc.createdAt > 3000) {
      sc.status = 'scanned'
      sc.code = randomId('mock-wx-code')
      sc.openId = 'mock-openid-1'
    }
    return [200, ok({ sceneId, status: sc.status, code: sc.code })]
  })

  // 3) 前端拿 code 换 JWT
  mock.onPost('/auth/wechat').reply(config => {
    const body = typeof config.data === 'string' ? JSON.parse(config.data || '{}') : (config.data || {})
    if (!body.code) return [400, fail(400, 'code required')]
    // 从 code 推断 openId（mock-wx-code-N-...）→ 但简单起见固定用 openId-1
    const user = userByOpenId('mock-openid-1') || {
      id: users.length + 1,
      phone: null,
      wechatOpenId: 'mock-openid-1',
      displayName: '微信用户',
      avatar: ''
    }
    if (!userByOpenId('mock-openid-1')) users.push(user)
    const t = makeToken(user.id)
    return [200, ok({ ...t, user })]
  })
}
