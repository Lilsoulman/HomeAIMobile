// Todos API：list / get / create / update / remove + subtasks
// 走 services/http，字段命名与旧 services/mock/todos.js 保持一致
import http from '../http'

export const todoApi = {
  list: (params) => http.get('/todos', { params }),
  get: (id) => http.get('/todos/' + id),
  create: (body) => http.post('/todos', body),
  update: (id, body) => http.put('/todos/' + id, body),
  remove: (id) => http.delete('/todos/' + id),
  addSubtask: (id, body) => http.post('/todos/' + id + '/subtasks', body),
  // 便捷方法：toggle done
  toggleDone: (id, done) => http.put('/todos/' + id, { done })
}
