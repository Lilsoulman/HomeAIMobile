// 埋点占位：M5 接后端
// 当前：console.log 一行；M5 替换为 sendBeacon / fetch 上报
export function track (event, payload = {}) {
  if (typeof window !== 'undefined' && window.console) {
    // eslint-disable-next-line no-console
    console.log(`[track] ${event}`, payload)
  }
}
