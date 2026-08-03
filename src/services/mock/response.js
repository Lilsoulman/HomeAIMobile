// 业务 API 统一响应包装：与后端约定 { code, msg, data }
// code === 0 视为成功；其它抛错
export function ok (data, msg = 'ok') {
  return { code: 0, msg, data }
}

export function fail (code, msg, data = null) {
  return { code, msg, data }
}
