# HomeAIMobile — 后续开发计划

> 首版（M0）只完成首页 Dashboard。本文为 M1~M5 的开发路线图，
> 每完成一个里程碑，把对应章节挪到 CHANGELOG，新增"完成情况"小节。

---

## §1 里程碑总览

| 阶段 | 名称 | 周期 | 关键交付 | 状态 |
|---|---|---|---|---|
| **M0** | 脚手架 + 首页 | 1 周 | Vue2 + ElementUI + Vant 项目；6 个首页组件；3 套主题 | ✅ 已交付 |
| M0.5 | 首页 → 业务页过渡 | 0.5 周 | QuickEntries 接通；TodoWidget 升级；CalendarWidget 升级为迷你月 | ⬜ 待启动 |
| M1 | Todo 完整版 | 2 周 | CRUD/筛选/排序/批量/子任务/重复/提醒/附件/导入导出/AI 导入/日报周报 | ⬜ 待启动 |
| M2 | 日历完整版 | 2.4 周 | 月/周/日/年 4 视图/本地事件/iCal 订阅/RRULE 展开/事件 override | ⬜ 待启动 |
| M3 | AI 周报/日报 | 1.4 周 | Skill 池 UI/OpenAI 兼容 API（前端直调,M5 前）/ 5 个内置 Skill | ⬜ 待启动 |
| M4 | 账号 + 同步 | 1.4 周 | JWT 登录/多端 LWW 同步/PWA/Web Push | ⬜ 待启动 |
| M5 | C# 后端 + 上线 | 2 周 | ASP.NET Core 8/EF Core/SQL Server/AI/iCal/天气代理 | ⬜ 待启动 |

---

## §2 模块依赖

```
┌──────────────┐
│  views/*.vue │  ← UI 层
└──────┬───────┘
       │ mapState / mapActions
┌──────▼───────┐
│  Vuex Store  │  ← 业务状态（settings/todos/calendar/user/skills）
└──────┬───────┘
       │ dispatch
┌──────▼────────┐
│ services/api  │  ← 统一调用层（首版走 mock）
└──────┬────────┘
       │ http
┌──────▼──────┐    M5    ┌──────────────────┐
│ mock (首版)  │ ──────► │  C# ASP.NET Core │ ──► SQL Server
└─────────────┘          └──────────────────┘
```

**关键原则**：
- 业务逻辑全部在 store 层的 actions/getters，组件只做渲染
- 接入 C# 后端时，组件/store 零改动，只换 `services/api`
- M3（AI）必须等 M5 后端准备好（或先用纯前端调用，但 Key 暴露不安全）

---

## §3.0 任务切片总览（执行索引）

> 每个里程碑拆为 N 个"原子切片"，每片 0.5~2 天。
> 切片命名 `{M阶段}.{序号}`，状态：⬜ 待启动 / 🔄 进行中 / ✅ 完成 / ⚠️ 阻塞。

### M0.5（3 天）

- M0.5.1 QuickEntries 卡片"待办/日历/AI 报告"接通对应路由
- M0.5.2 TodoWidget 顶部加"+"快速添加（不弹 modal，inline 输入回车即建）
- M0.5.3 CalendarWidget 替换为迷你月视图组件 `MiniMonth.vue`
- M0.5.4 首页埋点：曝光 / 点击 → `utils/track.js`（console 占位，M5 接后端）

### M1（10 天）

- M1.1 store 增 `filters/sort/batch/selected` 子 state（保留 `todos` 不动）
- M1.2 视图拆分：`views/Todo/ListView.vue` / `KanbanView.vue` + 顶部 FilterBar / SortMenu
- M1.3 筛选：状态/类型/时间(今天/本周/上周/本月/自定义)/优先级/颜色/关键字
- M1.4 排序：创建时间/到期时间/优先级，置顶永远置顶
- M1.5 批量：长按进入多选 → 顶部 action bar（完成/删除/取消）
- M1.6 子任务：行内展开/收起、新增/勾选/删除、进度条
- M1.7 重复：none/daily/weekly/biweekly/monthly/yearly + 关闭/开启 + 频率
- M1.8 重复补救 `repairMissingRepeats`：store boot 时执行，补齐今天前所有缺口
- M1.9 提醒：remindAt 触发 `Notification`（60s 内 setTimeout 轮询 + service worker 兜底）
- M1.10 附件：图片粘贴/选择 → IndexedDB `tf_attachments`，列表灯箱预览
- M1.11 导入/导出 JSON：照 `templates/todo-template.json` schema v2.3
- M1.12 AI 导入：弹层输入自然语言 → 调用 aiGenerateText(scope=import) → 合并到 store
- M1.13 周报/日报视图：按 completedAt 筛选 + Skill 选择 + Markdown 导出

### M2（12 天）

- M2.1 视图框架：`views/Calendar.vue` + 4 个子视图组件 + view 切换动画
- M2.2 月视图：6×7 网格 + 事件彩色横条（贪心间隔装箱 ≤ 3 条/格，多余 "+N"）
- M2.3 周视图：24h 时间轴 + 当前时间红线 + 半小时刻度
- M2.4 日视图：左侧迷你月 + 右侧当天时间轴
- M2.5 年视图：12 宫格，每宫显示当月事件热力（事件数/总）
- M2.6 本地事件 CRUD：弹层复用 Todo 编辑器骨架（简化版）
- M2.7 重复：none/daily/weekly/monthly/yearly + 自定义 RRULE 字符串（M2.10 解析）
- M2.8 颜色 + 透明度 slider：Vant Slider
- M2.9 iCal 订阅：URL 列表/启停/手动刷新
- M2.10 iCal 解析：`utils/ics.js`（parseICS + expandRecurrence，支持 RRULE 基础频率）
- M2.11 iCal Override：长按事件 → 重命名/改时间/隐藏（存 store `icalOverrides`）
- M2.12 缓存：`tf_cal_events_cache` 1h 过期；订阅拉新合并；失败回退旧缓存
- M2.13 跨时区显示：所有时间 `new Date(ts).toLocaleString()` 自适应
- M2.14 待办联动：月视图格子右上角显示到期待办数（≤3 颜色块 + "+N"）

### M3（7 天）

- M3.1 store `skills` 模块：CRUD + scopes + activeSkillId
- M3.2 注入 5 个内置 Skill（沿用 TabFlow 默认文案）
- M3.3 设置弹层：API endpoint / API Key / model / temperature（仅存 localStorage）
- M3.4 `services/api/ai.js`：直接 fetch OpenAI 兼容 `/chat/completions`，60s 超时
- M3.5 周报页：Skill 下拉 + 模板占位 `{week}` + Markdown 输出
- M3.6 日报页：同上，scope=day
- M3.7 排除规则：重复 todo 不计 / 单条 reportIgnored 标记（M1.13 复用）
- M3.8 迁移逻辑：检测 `weekReportSkills/dayReportSkills` 旧键 → 合并到新池

### M4（7 天）

- M4.1 登录/注册页：手机号 + 密码表单 + Vant 校验
- M4.2 axios 拦截器：401 → 自动 refresh；refresh 失败 → 跳登录
- M4.3 多端同步协议：增量 `?since=<ts>` 拉取 + `POST /sync/push` 推
- M4.4 LWW：每条记录带 `updatedAt`，服务端选最大
- M4.5 离线优先：本地 store 写入即成功，联网后 diff push
- M4.6 设置云端：theme/lang/aiKey/skills 随账号漫游
- M4.7 PWA：`manifest.webmanifest` + service worker（vite-plugin-pwa 替换为 workbox）
- M4.8 Web Push：后端生成 VAPID，前端订阅 → 提醒触达（M1.9 复用通道）

### M5（10 天）

- M5.1 ASP.NET Core 8 Web API 项目骨架 + 解决方案结构
- M5.2 EF Core + SQL Server 上下文 + 首次 Migration + 种子数据
- M5.3 JWT 中间件 + Refresh Token 旋转 + BCrypt 密码
- M5.4 OpenAPI / Swagger UI（Swashbuckle）+ JWT Bearer 配
- M5.5 CORS：dev 全开；prod 走 `appsettings.Production.json` 白名单
- M5.6 iCal 代理端点 `GET /api/v1/calendar/ical/fetch` + 内存缓存 1h
- M5.7 Open-Meteo 代理 `GET /api/v1/weather`（同缓存策略）
- M5.8 AI 代理 `POST /api/v1/ai/generate`：用 `DataProtection` 加密存 Key
- M5.9 附件本地存储：落 `wwwroot/uploads/{userId}/{guid}.{ext}`，10MB 限
- M5.10 Docker：多阶段构建 + healthcheck + docker-compose（SQL Server + API）
- M5.11 部署文档：IIS 反代步骤 + systemd unit 样例

---

## §3 详细功能列表

### §3.1 M0.5 — 首页过渡（概要）

> 详细任务切片见 §3.0 M0.5 节。

- QuickEntries 卡片接通路由
- TodoWidget 升级为可快速添加
- CalendarWidget 升级为迷你月
- 首页埋点占位

### §3.2 M1 — Todo 完整版（概要）

> 详细任务切片见 §3.0 M1 节。

- [ ] 列表 / 看板（kanban）两种视图切换
- [ ] 筛选：状态（全部/待办/完成）/ 类型 / 时间（今天/本周/上周/本月/自定义）/ 优先级 / 颜色 / 关键字
- [ ] 排序：创建时间 / 到期时间 / 优先级，置顶始终在前
- [ ] 批量操作：勾选多选 → 批量完成 / 批量删除（同步清理 IndexedDB 附件）
- [ ] 子任务展开收起
- [ ] 重复任务：完成时自动创建下一周期实例
- [ ] 重复任务补救（`repairMissingRepeats`）：启动时检查已完成的重复任务，自动补到今天
- [ ] 提醒：remindAt 到点触发系统通知 / Web Push
- [ ] 附件：图片灯箱 / 文件下载；存 IndexedDB
- [ ] 导入 / 导出 JSON（参考 `templates/todo-template.json` schema）
- [ ] AI 导入：粘贴自然语言 → 自动抽成 todos + customTypes
- [ ] 周报 / 日报视图：按 `completedAt` 筛选 + AI 生成 + 导出 Markdown

### §3.3 M2 — 日历完整版（概要）

> 详细任务切片见 §3.0 M2 节。

- [ ] 月 / 周 / 日 / 年 4 视图（共享 zoom/translate 动画）
- [ ] 月视图：6×7 网格 + 事件彩色横条（贪心间隔装箱算法）
- [ ] 周视图：24h 时间轴 + 当前时间红线
- [ ] 日视图：左侧迷你月历 + 右侧当天时间轴
- [ ] 本地事件 CRUD（颜色 + 透明度 slider + 重复 none/daily/weekly/monthly/yearly/custom）
- [ ] iCal 订阅：URL 列表 / 启停 / 刷新；`parseICS` + `RRULE` 展开
- [ ] iCal 事件 Override：就地改名/改时间/隐藏，不污染源
- [ ] 缓存：`tf_cal_events_cache` 1 小时自动过期
- [ ] 跨时区显示：`toLocaleString` 自动适配
- [ ] 待办联动：日历格显示到期待办颜色块

### §3.4 M3 — AI 周报/日报（概要）

> 详细任务切片见 §3.0 M3 节。

- [ ] Skill 池 UI：CRUD 技能；scopes: week / day / import
- [ ] 内置 5 个 Skill（沿用 TabFlow）：简洁总结 / 汇报体 / 日报-简报 / 日报-详细 / 待办提取
- [ ] 设置弹层：API endpoint / API Key / 模型名 / temperature
- [ ] 周报/日报页：调用 `aiGenerateText`（页面端直接 fetch OpenAI 兼容 `/chat/completions`，60s 超时）
- [ ] 模板语法：`{week}` / `{day}` 占位符
- [ ] 排除规则：重复待办不计 / 单条手动忽略
- [ ] 导出 Markdown
- [ ] 迁移逻辑：检测到老 `weekReportSkills / dayReportSkills` 自动合并到新池

### §3.5 M4 — 账号 + 同步（概要）

> 详细任务切片见 §3.0 M4 节。

- [ ] 登录 / 注册页（手机号 + 密码 或 邮箱）
- [ ] JWT token + refresh token，axios 拦截器自动续期
- [ ] 多端同步：todo / calendar / skills / settings 增量同步
- [ ] 离线优先：本地 store 是 source of truth，联网时后台 diff + push
- [ ] 设置云端：主题 / 语言 / AI Key / Skill 池随账号漫游
- [ ] PWA：service worker + manifest，支持添加到主屏
- [ ] Web Push 通知（提醒事件触达）

### §3.6 M5 — C# 后端（概要）

> 详细任务切片见 §3.0 M5 节。

- [ ] ASP.NET Core 8 Web API 项目骨架
- [ ] EF Core + SQL Server，迁移 + 种子数据
- [ ] JWT 认证中间件
- [ ] OpenAPI / Swagger 文档
- [ ] CORS 全开（首版）；生产环境收紧白名单
- [ ] iCal 代理端点（解决跨域）
- [ ] Open-Meteo 代理端点（同上）
- [ ] AI 代理端点：用户 API Key 加密存后端，前端永远拿不到
- [ ] 部署：Docker 镜像 + 简易 systemd / IIS 反代

---

## §4 C# 后端接口设计

> M5 启动前可能微调，先给契约骨架。

### 4.1 统一响应

```json
{ "code": 0, "msg": "ok", "data": { } }
```

`code=0` 成功，其它失败（401 鉴权失败、403 无权、404 不存在、500 异常）。

### 4.2 端点列表

| Method | Path | 说明 |
|---|---|---|
| `POST` | `/api/v1/auth/register` | 注册 |
| `POST` | `/api/v1/auth/login` | 登录返回 access + refresh token |
| `POST` | `/api/v1/auth/refresh` | 刷新 access token |
| `GET` | `/api/v1/auth/me` | 当前用户信息 |
| `GET` | `/api/v1/todos` | 列表（支持 `?status=&type=&from=&to=`） |
| `POST` | `/api/v1/todos` | 新建 |
| `PUT` | `/api/v1/todos/{id}` | 更新 |
| `DELETE` | `/api/v1/todos/{id}` | 删除 |
| `POST` | `/api/v1/todos/{id}/subtasks` | 增子任务 |
| `GET` | `/api/v1/calendar/events?from=&to=` | 事件列表 |
| `POST` | `/api/v1/calendar/events` | 新建 |
| `PUT` | `/api/v1/calendar/events/{id}` | 更新 |
| `DELETE` | `/api/v1/calendar/events/{id}` | 删除 |
| `GET` | `/api/v1/calendar/subscriptions` | iCal 订阅列表 |
| `POST` | `/api/v1/calendar/subscriptions` | 新订阅 |
| `DELETE` | `/api/v1/calendar/subscriptions/{id}` | 取消订阅 |
| `POST` | `/api/v1/calendar/ical/fetch` | body: `{url}` → 后端 fetch + 缓存 |
| `GET` | `/api/v1/skills` | Skill 池 |
| `POST` | `/api/v1/skills` | 新建 |
| `PUT` | `/api/v1/skills/{id}` | 更新 |
| `DELETE` | `/api/v1/skills/{id}` | 删除 |
| `POST` | `/api/v1/ai/generate` | body: `{scope, prompt, input}` → 后端用用户 Key 调 OpenAI |
| `GET` | `/api/v1/weather?lat=&lon=` | 代理 Open-Meteo |
| `GET` | `/api/v1/attachments/{id}` | 取附件 |
| `POST` | `/api/v1/attachments` | 上传附件（multipart） |
| `DELETE` | `/api/v1/attachments/{id}` | 删除附件 |

### 4.3 EF Core 实体命名

| 表 | 实体类 | 命名空间 |
|---|---|---|
| `users` | `User` | `HomeAI.Api.Entities` |
| `todos` | `Todo` + `Subtask` (Owned) | `HomeAI.Api.Entities` |
| `attachments` | `Attachment` | `HomeAI.Api.Entities` |
| `calendar_events` | `CalendarEvent` | `HomeAI.Api.Entities` |
| `calendar_subscriptions` | `CalendarSubscription` | `HomeAI.Api.Entities` |
| `ai_skills` | `AiSkill` | `HomeAI.Api.Entities` |
| `user_settings` | `UserSetting`（复合主键） | `HomeAI.Api.Entities` |
| `ai_configs` | `AiConfig` | `HomeAI.Api.Entities` |

`HomeAIDbContext : DbContext`，注册 `IEntityTypeConfiguration<T>`，每实体一个 `IEntityTypeConfiguration` 类。

### 4.4 JWT 设计

- 算法：HS256（首版）；密钥 ≥ 32 字节，从 `appsettings.json:Jwt:Key` 读
- Access Token：15 分钟，claim 含 `sub(userId)` / `phone` / `iat` / `exp`
- Refresh Token：7 天，随机 32 字节 → base64url；存 `refresh_tokens` 表（含 `userId` / `tokenHash` / `expiresAt` / `revokedAt`）
- 旋转策略：每次 refresh → 旧 token revoked + 新 token 下发
- 中间件：自定义 `JwtMiddleware` → 解析 header → 注入 `HttpContext.Items["User"]`

### 4.5 CORS 策略

```csharp
// Program.cs
builder.Services.AddCors(opt => {
  opt.AddPolicy("Dev", p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
  opt.AddPolicy("Prod", p => p.WithOrigins(cfg.AllowedOrigins).AllowAnyHeader().WithMethods("GET","POST","PUT","DELETE","PATCH"));
});
// app.UseCors(env.IsDevelopment() ? "Dev" : "Prod");
```

### 4.6 附件存储

- 路径：`wwwroot/uploads/{userId}/{guid}.{ext}`（首次访问时建目录）
- 限制：10MB / 文件；MIME 白名单（image/*, application/pdf, text/*, application/zip）
- 上传：`IFormFile`，流式写入磁盘
- 读取：`GET /api/v1/attachments/{id}` → `PhysicalFile` 返回
- 清理：删除 todo 时级联删除附件文件（`background job` 异步）

### 4.7 AI 代理

- 端点：`POST /api/v1/ai/generate`，body `{ scope, prompt, input, model?, temperature? }`
- 流程：
  1. 鉴权 → 取 userId
  2. 读 `ai_configs` 解密（`DataProtectionProvider.CreateProtector("AiConfig").Unprotect(...)`）
  3. 用 `HttpClient` 转发到用户配置的 `endpoint/chat/completions`
  4. 透传 model / temperature / messages
  5. 60s 超时 + 重试 1 次
  6. 返回 `{ content, usage }`
- 限流：每用户 60 次/分钟（`AspNetCoreRateLimit`）
- 审计：每次调用记录 `ai_call_logs`（userId / scope / tokens / latency / status）

---

## §5 数据模型（DDL 草稿）

> 与 TabFlow `chrome.storage.local` 字段 1:1 映射，仅将 `seq` 等 id 改为自增主键。

```sql
-- 用户
CREATE TABLE users (
  id            BIGINT PRIMARY KEY IDENTITY,
  phone         VARCHAR(20) UNIQUE,
  email         VARCHAR(120) UNIQUE,
  password_hash NVARCHAR(255) NOT NULL,
  display_name  NVARCHAR(64),
  avatar        NVARCHAR(255),
  created_at    DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),
  updated_at    DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
);

-- 待办
CREATE TABLE todos (
  id            BIGINT PRIMARY KEY IDENTITY,
  user_id       BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  seq           INT NOT NULL,
  title         NVARCHAR(255) NOT NULL,
  description   NVARCHAR(MAX),
  type          NVARCHAR(32),
  priority      NVARCHAR(8),
  color         NVARCHAR(16),
  status        NVARCHAR(16) NOT NULL DEFAULT 'pending',
  due_date      DATETIMEOFFSET,
  remind_at     DATETIMEOFFSET,
  repeat_rule   NVARCHAR(32),
  parent_id     BIGINT REFERENCES todos(id) ON DELETE CASCADE,
  pinned        BIT NOT NULL DEFAULT 0,
  tags          NVARCHAR(MAX),  -- JSON array
  completed_at  DATETIMEOFFSET,
  created_at    DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),
  updated_at    DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
CREATE INDEX idx_todos_user_due ON todos(user_id, due_date);

-- 子任务（与 todo 1:N，可单表简化）
CREATE TABLE subtasks (
  id          BIGINT PRIMARY KEY IDENTITY,
  todo_id     BIGINT NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
  text        NVARCHAR(255) NOT NULL,
  done        BIT NOT NULL DEFAULT 0
);

-- 附件
CREATE TABLE attachments (
  id          BIGINT PRIMARY KEY IDENTITY,
  user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  todo_id     BIGINT REFERENCES todos(id) ON DELETE CASCADE,
  name        NVARCHAR(255) NOT NULL,
  mime        NVARCHAR(64),
  size_bytes  BIGINT,
  data        VARBINARY(MAX) NOT NULL,
  created_at  DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
);

-- 本地日历事件
CREATE TABLE calendar_events (
  id          BIGINT PRIMARY KEY IDENTITY,
  user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       NVARCHAR(255) NOT NULL,
  description NVARCHAR(MAX),
  start_at    DATETIMEOFFSET NOT NULL,
  end_at      DATETIMEOFFSET,
  all_day     BIT NOT NULL DEFAULT 0,
  color       NVARCHAR(16),
  repeat_rule NVARCHAR(32),
  location    NVARCHAR(255)
);
CREATE INDEX idx_events_user_start ON calendar_events(user_id, start_at);

-- iCal 订阅
CREATE TABLE calendar_subscriptions (
  id          BIGINT PRIMARY KEY IDENTITY,
  user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  url         NVARCHAR(MAX) NOT NULL,
  name        NVARCHAR(128),
  enabled     BIT NOT NULL DEFAULT 1,
  last_fetch  DATETIMEOFFSET
);

-- AI Skills
CREATE TABLE ai_skills (
  id          BIGINT PRIMARY KEY IDENTITY,
  user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name        NVARCHAR(128) NOT NULL,
  prompt      NVARCHAR(MAX) NOT NULL,
  scopes      NVARCHAR(MAX)  -- JSON array
);

-- 用户设置（key-value）
CREATE TABLE user_settings (
  user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  key         NVARCHAR(64) NOT NULL,
  value       NVARCHAR(MAX),
  PRIMARY KEY (user_id, key)
);

-- AI 配置（Key 加密存）
CREATE TABLE ai_configs (
  user_id     BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  endpoint    NVARCHAR(255),
  api_key_enc NVARCHAR(MAX),
  model       NVARCHAR(64),
  temperature DECIMAL(3,2)
);
```

---

## §6 风险与约束

1. **iCal 跨域** → 必须后端代理，浏览器直接 fetch `.ics` 大概率被 CORS 拦。
2. **提醒推送** → 首版用 setTimeout 模拟；M4 接入 Web Push；iOS Safari 不支持 Web Push，需 PWA + Notification API 兜底。
3. **AI Key 安全** → 必须存后端并加密；前端永远不接触真实 Key（首版 M0 仅占位）。
4. **离线同步冲突** → M4 实现 LWW（Last-Write-Wins）策略；如需 OT/CRDT 后续迭代。
5. **大附件** → M1 限制单文件 ≤ 10MB；M5 后端用流式上传。
6. **iOS 100vh 问题** → 已用 `padding-bottom: env(safe-area-inset-bottom)` 兜底；后续可视情况引入 `100dvh` polyfill。
7. **PWA 与 iOS** → iOS 不支持 `beforeinstallprompt`；提供"添加到主屏"引导说明即可。

---

## §7 变更日志

| 日期 | 里程碑 | 变更 |
|---|---|---|
| 2026-07-30 | M0 | 首版脚手架 + 首页 Dashboard + 3 套主题交付 |

---

## §8 已知缺陷与遗留（M0 收尾）

> M0 首版仅完成首页 Dashboard，遗留以下缺口，将在后续里程碑补齐。

### 8.1 功能缺口

- 4 个 Tab 页（/todo /calendar /me）仍是 Placeholder，无实际业务
- 无登录、无云端同步、无 AI 能力
- 无 PWA 离线支持
- 无推送通知

### 8.2 技术债务

- `services/api/index.js` 中 `authApi` 直接走 `http`（真实地址），未走 `mockAdapter`；M5 前需补 mock
- `store/persistence.js` 序列化整个 state；M4 后需改为按模块懒加载
- `package.json` 缺 ESLint 严格配置；首版仅 `--no-fix`
- 无单元测试、无 E2E

### 8.3 已落地文件清单（M0）

- 源码：`src/` 共 39 个文件（main.js / App.vue / 3 utils / 2 services / 5 mock / 1 router / 1 store / 1 persistence / 4 modules / 3 common / 2 layout / 6 home / 5 views / 3 assets）
- 配置：`package.json` / `vue.config.js` / `babel.config.js` / `.browserslistrc` / `.gitignore`
- 文档：`README.md` / `PROJECT.md` / `docs/design.md` / `PROJECT_PLAN.md`

---

## §9 后续规划（占位）

> 详细方案待您后续指令展开，此处预留章节：

- §9.1 测试策略（单元 / E2E / 覆盖率门槛）
- §9.2 非功能性指标（性能预算 / 可观测 / 浏览器兼容矩阵）
- §9.3 Release Checklist（每里程碑验收模板）
- §9.4 风险与回滚（iCal 订阅失败 / Key 轮换 / 数据迁移失败兜底）

---

## §10 决策记录

| 日期 | 决策 | 上下文 | 影响 |
|---|---|---|---|
| 2026-07-30 | M0.5 过渡里程碑插入 | 首页 QuickEntries 不能悬空；M1 启动前需消化 | 工期总长 +0.5 周 |
| 2026-07-30 | M1 工期 1.5 周 → 2 周 | TabFlow todo.js 3519 行移植 + AI 导入 | M2 顺延 |
| 2026-07-30 | M2 工期 1.5 周 → 2.4 周 | iCal 解析 + 4 视图 | M3 顺延 |
| 2026-07-30 | 附件存本地磁盘 | SQL VARBINARY(MAX) 备份 / 迁移成本高 | M5 部署需挂载卷 |
| 2026-07-30 | 认证 = 手机号 + 密码 | 国内移动端主流；OAuth 留二期 | M4 表单 / 中间件均围绕此 |
| 2026-07-30 | LWW 同步 | OT / CRDT 工期成本高 | M4 引入文档需说明 |

---

## §11 变更日志

| 日期 | 里程碑 | 变更 |
|---|---|---|
| 2026-07-30 | M0 | 首版脚手架 + 首页 Dashboard + 3 套主题交付 |
| 2026-07-30 | M0.5~M5 | 计划文档完善：插入 M0.5 过渡；M1/M2 工期重排；新增任务切片总览 §3.0；补全 C# 后端 §4.3~4.7；新增 §8 已知缺陷、§9 占位、§10 决策记录、§11 变更日志 |
