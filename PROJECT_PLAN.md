# HomeMindMobile — 后续开发计划

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
| **M6.1** | **专家工作台 · 契约 + UI + Mock** | **1.2 周** | Expert/Group 领域模型；列表/详情/创建/执行/结果 5 个页面；状态机；mock 数据 | ⬜ 待启动 |
| **M6.2** | **专家工作台 · 真 AI 接入 + 配置页 + 打通** | **1 周** | AI 配置页（endpoint/model/temperature）；真调 `/ai/generate`；单 Expert + 串行 Group；结果→待办/日历 | ⬜ 待启动 |
| **M6.3** | **专家工作台 · DAG 并行 + SSE + 信用账本（预留）** | **1.4 周** | DAG 调度器；SSE 实时事件；estimate/charge/refund 账本 | ⬜ 待启动 |

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
- M3.9 **（M6 接管）** M3 范围被 M6 复用为内置 Skill 中的 `daily-report` 与 `weekly-report`；M3 切片整体并入 M6.2

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

### M6.1 — 专家工作台 · 数据契约 + UI + Mock（12 天）

- M6.1.1 `docs/EXPERT_DOMAIN.md` 领域模型详细设计（Expert / Version / Group / GroupVersion / Member / Run / RunStep / RunEvent / RunArtifact / CreditLedger / UserExpertPreference）
- M6.1.2 store 新增 `experts` 模块：catalog / runs / events 子 state
- M6.1.3 注入内置 6 个 Expert（Goal decomposition coach / Daily & weekly planner / Review analyst / Todo organizer / Habit coach / Information organizer）+ 3 个 Expert Group（Weekly planning / Goal decomposition / Personal review）
- M6.1.4 `services/api/experts.js`：list / detail / createRun / getRun / cancel / retry / actions
- M6.1.5 `services/api/expertRuns.js`：runs CRUD + events 查询
- M6.1.6 `services/mock/experts.mock.js`：内置目录 + 假 run（轮询返回 6 步状态）
- M6.1.7 `services/mock/expertRuns.mock.js`：run 状态机 mock
- M6.1.8 路由新增 `/experts`（Tab）→ 三个子路由：catalog / runs / detail
- M6.1.9 `views/Experts.vue`（catalog 列表 + 搜索 + 分类筛选 + 收藏）
- M6.1.10 `views/ExpertDetail.vue`（详情 + 启动）
- M6.1.11 `views/ExpertRun.vue`（实时执行进度 + 取消 + 重试；轮询 2s）
- M6.1.12 `views/ExpertResult.vue`（结果 + 创建待办 + 创建日历）

### M6.2 — 专家工作台 · 真 AI 接入 + 配置页 + 打通（10 天）

- M6.2.1 `services/api/aiConfig.js`：get / update（CRUD 后端 `ai_configs`）
- M6.2.2 `services/api/ai.js`：调用 `/ai/generate` 真后端（走 AI 网关，Key 加密存后端）
- M6.2.3 `services/mock/ai.mock.js`：默认仍 mock（未配 Key 时降级 mock）
- M6.2.4 `views/Settings.vue`（Me 页入口 → AI 配置 / 主题 / 语言 / 退出登录）
- M6.2.5 `components/settings/AiConfigForm.vue`：endpoint / model / temperature / "测试连接"按钮
- M6.2.6 store 新增 `aiConfig` 模块
- M6.2.7 `services/api/expertRuns.js` 真接入：单 Expert 直接调 `ai.generate`
- M6.2.8 `services/api/expertRuns.js` 真接入：Expert Group captain 串行调所有 members（简化版，不实现 DAG 并行）
- M6.2.9 `ExpertResult.vue` 真打通：调 `todoApi.create` / `calendarApi.create` 创建数据
- M6.2.10 数据来源追踪：todo / event 记录 `sourceType` + `sourceRunId`（`sourceType: 'expert'` / `sourceRunId: 123`）

### M6.3 — 专家工作台 · DAG 并行 + SSE + 信用账本（预留 14 天，本轮不交付）

- M6.3.1 DAG 调度器（基于 `run_step_dependencies`）
- M6.3.2 并行执行（受租户并发上限约束）
- M6.3.3 SSE 端点 `/expert-runs/{id}/events`
- M6.3.4 前端 EventSource 客户端
- M6.3.5 `credit_ledger` 写入 + 幂等键
- M6.3.6 estimate / charge / refund 流程

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

### §3.7 M6 — 专家工作台（概要）

> 详细任务切片见 §3.0 M6.1 / M6.2 / M6.3 节。源文档 `docs/expert-workbench-plan.md` 描述完整平台，本里程碑**只落地 Phase 1（数据契约 + UI）+ Phase 2 前半（真 AI 接入 + 打通）**；DAG 并行 + SSE + 信用账本放入 M6.3 预留。

#### §3.7.1 设计目标

- 让用户能发现并启动一个 **Expert**（专注型 AI 代理）或 **Expert Group**（专家组，captain + members 协作）
- 每次执行有完整的"运行（Run）"生命周期：草稿 → 排队 → 计划 → 执行 → 综合 → 完成
- 过程可见、可控：可取消、可重试、不会重复扣费
- 完成后能**直接落为待办或日历事件**，并保留来源（`sourceType: 'expert'` / `sourceRunId`）
- AI Key 永远存后端加密，前端**永不接触**

#### §3.7.2 核心领域对象

| 对象 | 含义 | 类比 |
|---|---|---|
| **Skill** | 可复用的 AI 能力（如 web 搜索、日历、待办）| 工具 |
| **Expert** | 单 AI 代理：有角色、流程、工具策略、输出格式 | 专员 |
| **Expert Group** | 组长 + 成员 + 工作流的多代理协作 | 项目组 |
| **Expert Run** | 一次具体执行（不可变）| 工单 |
| **Run Step** | Run 内的子任务（captain 规划或成员执行）| 子工单 |
| **Run Event** | 用户可见的实时进度事件 | 日志 |
| **Run Artifact** | 输出文件（Markdown / 图片 / 表格）| 附件 |
| **Credit Ledger** | 信用账本（estimate / charge / refund）| 账单 |

#### §3.7.3 内置目录（M6.1 注入）

**Expert（6 个）**：
- Goal decomposition coach（目标分解教练）
- Daily and weekly planner（日报周报规划师）
- Review analyst（复盘分析师）
- Todo organizer（待办整理师）
- Habit coach（习惯教练）
- Information organizer（信息整理师）

**Expert Group（3 个）**：
- Weekly planning group（周规划组）
- Goal decomposition group（目标分解组）
- Personal review group（个人复盘组）

#### §3.7.4 状态机

```
draft → queued → planning → running → synthesizing → completed
                  │            │              │
                  └→ failed    └→ cancelled    └→ needs_input
```

- `draft`：用户在创建页编辑，未提交
- `queued`：已提交，等待调度（M6.1 mock 立即进入下一态；M6.2 走 AI 网关）
- `planning`（仅 Group）：captain 拆解任务，生成 step DAG（M6.2 简化为直接列出 members）
- `running`：Expert / member 正在执行（M6.2 单 Expert 一次 LLM；Group 串行多次）
- `synthesizing`（仅 Group）：captain 汇总成员结果
- `completed`：有最终结果
- `failed` / `cancelled` / `needs_input`：终态

#### §3.7.5 前端页面（M6.1 全部；M6.2 改造为真接入）

| 路由 | 组件 | 作用 |
|---|---|---|
| `/experts` | `Experts.vue` | Expert Center：搜索 + 分类筛选 + Expert/Group 切换 + 卡片列表 + 收藏 |
| `/experts/:id` | `ExpertDetail.vue` | 详情：方法 / 工具 / 示例 / 隐私范围 / 预期输出 / 启动 |
| `/experts/runs/new` | `ExpertCreateRun.vue` | 创建运行：自然语言 + 上下文引用（todo / plan / event） + 信用确认 |
| `/experts/runs/:id` | `ExpertRun.vue` | 执行：状态机时间线 + 取消 + 重试（M6.1 轮询 / M6.3 SSE） |
| `/experts/runs/:id/result` | `ExpertResult.vue` | 结果：执行摘要 + 行动项 + 来源引用 + 创建待办/日历 |

#### §3.7.6 AI 配置页（M6.2 必做）

入口：Me 页 → "设置" → "AI 配置"（`views/Settings.vue` + `components/settings/AiConfigForm.vue`）

字段：
- **API endpoint**：默认 `https://api.openai.com/v1`，用户可改（DeepSeek / 通义千问 / 自建 OpenAI 兼容服务）
- **API Key**：密码框，提交时**只发到后端**，前端不存原文（只存后端返回的 masked 标记）
- **Model**：文本输入，例 `gpt-4o-mini` / `deepseek-chat`
- **Temperature**：`el-slider` 0~2 步长 0.1
- **"测试连接"按钮**：调后端 `POST /ai/test` → 用此配置发起一次最小请求，弹 toast 成功/失败

存到后端 `ai_configs`（DataProtection 加密），前端永远拿不到原文。

#### §3.7.7 真接入流程（M6.2）

1. 用户在 `AiConfigForm.vue` 填好配置 → `aiConfig/update` → 后端存 `ai_configs.api_key_enc`
2. 用户在 `ExpertCreateRun.vue` 提交任务 → `expertRuns/create` → 后端写 `expert_runs` + 调 `/ai/generate`（带用户 Key）→ 写 `ai_call_logs` → 写 `run_events` / `run_steps` → 完成后写 `expert_runs.result_json`
3. 前端轮询 `GET /expert-runs/{id}`：每 2s 拉一次，看 `status` 与最新 `events`
4. `completed` 后跳 `ExpertResult.vue`，点击"创建待办"→ 调 `todoApi.create({ ..., sourceType: 'expert', sourceRunId: id })`

#### §3.7.8 与其它里程碑的关系

- **复用 M1** 的 `todoApi.create`：结果落为待办时调用
- **复用 M2** 的 `calendarApi.create`：结果落为日历事件时调用
- **不依赖 M3**：M3 的 Skill 池被 M6 整体接管（M3 切片在 §3.0 标注并入 M6.2）
- **依赖 M5 业务后端**：M6.2 需要 `/ai/generate` 端点（M5.8 已规划）+ `/ai/config` CRUD
- **前端 AI 网关**：M6.2 复用 M5.8 设计的 `POST /api/v1/ai/generate`，前端永不接触 Key

#### §3.7.9 简化取舍

- **M6.2 Group 简化为串行**：captain 串行调所有 members；不实现 DAG 并行 → 降低 M6.2 工作量
- **M6.1/M6.2 轮询代替 SSE**：每 2s GET `/expert-runs/{id}`；架构上预留 SSE 升级位（M6.3）
- **M6.1 不实现真信用账本**：用 `estimated_credits` 字段 mock 占位；M6.3 接入 `credit_ledger`
- **不实现 M6 取消 + 重试的复杂回滚**：M6.1 仅简单停轮询 + 后端无动作；M6.3 接入队列
- **不开放自定义 Expert**：仅内置 6 + 3（用户决策"先做核心"）

#### §3.7.10 验收标准

- ✅ 用户能浏览 6 个 Expert + 3 个 Group，看到分类、搜索、详情
- ✅ 单 Expert Run 能从 queued 跑到 completed，时间线正确显示 6 步
- ✅ Group Run 串行跑完所有 members
- ✅ "创建待办"把 run 结果落为 todo，`sourceType='expert'` / `sourceRunId=<id>`
- ✅ "创建日历事件"把 run 结果落为 event，同上
- ✅ AI Key 永远只存后端；前端任何位置（localStorage / Vuex / DevTools）都看不到 Key 原文
- ✅ 未登录态点击 Tab 跳 `/login`

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
| `GET` | `/api/v1/ai/config` | 取 AI 配置（Key 掩码返回） |
| `PUT` | `/api/v1/ai/config` | 更新 AI 配置（Key 加密存） |
| `POST` | `/api/v1/ai/test` | 测试连接：用此配置发起一次最小请求 |
| `GET` | `/api/v1/weather?lat=&lon=` | 代理 Open-Meteo |
| `GET` | `/api/v1/attachments/{id}` | 取附件 |
| `POST` | `/api/v1/attachments` | 上传附件（multipart） |
| `DELETE` | `/api/v1/attachments/{id}` | 删除附件 |
| `GET` | `/api/v1/experts` | Expert 目录（搜索 / 分类 / 类型：expert / group） |
| `GET` | `/api/v1/experts/{id}` | Expert / Group 详情 + 当前版本 |
| `POST` | `/api/v1/expert-runs` | 创建运行（用户提交自然语言任务） |
| `GET` | `/api/v1/expert-runs/{id}` | 运行快照 + 最终结果（轮询用） |
| `GET` | `/api/v1/expert-runs/{id}/events` | 进度事件列表（M6.1/M6.2 轮询；M6.3 改 SSE） |
| `POST` | `/api/v1/expert-runs/{id}/cancel` | 取消运行 |
| `POST` | `/api/v1/expert-runs/{id}/retry` | 重试失败的步骤 |
| `POST` | `/api/v1/expert-runs/{id}/actions` | 把结果落为 todo / event（M6.2 打通） |

### 4.3 EF Core 实体命名

| 表 | 实体类 | 命名空间 |
|---|---|---|
| `users` | `User` | `HomeMind.Api.Entities` |
| `todos` | `Todo` + `Subtask` (Owned) | `HomeMind.Api.Entities` |
| `attachments` | `Attachment` | `HomeMind.Api.Entities` |
| `calendar_events` | `CalendarEvent` | `HomeMind.Api.Entities` |
| `calendar_subscriptions` | `CalendarSubscription` | `HomeMind.Api.Entities` |
| `ai_skills` | `AiSkill` | `HomeMind.Api.Entities` |
| `user_settings` | `UserSetting`（复合主键） | `HomeMind.Api.Entities` |
| `ai_configs` | `AiConfig` | `HomeMind.Api.Entities` |

`HomeMindDbContext : DbContext`，注册 `IEntityTypeConfiguration<T>`，每实体一个 `IEntityTypeConfiguration` 类。

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

-- ============================================================
-- M6 专家工作台（11 张表，MySQL 8.0 风格，与上文 M0~M5 表对齐）
-- 字段参考 docs/expert-workbench-plan.md
-- ============================================================

-- Expert 身份
CREATE TABLE IF NOT EXISTS `experts` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`     BIGINT       NULL COMMENT 'builtin 时为 NULL；custom 时为所有者 user_id',
  `code`        VARCHAR(64)  NOT NULL COMMENT 'goal_decomposition / todo_organizer 等',
  `name`        VARCHAR(128) NOT NULL,
  `category`    VARCHAR(32)  NOT NULL COMMENT 'productivity / planning / review / info',
  `type`        VARCHAR(16)  NOT NULL DEFAULT 'builtin' COMMENT 'builtin | custom',
  `status`      VARCHAR(16)  NOT NULL DEFAULT 'active',
  `description` TEXT         NULL,
  `created_at`  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_experts_code` (`code`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Expert 不可变版本
CREATE TABLE IF NOT EXISTS `expert_versions` (
  `id`                     BIGINT       NOT NULL AUTO_INCREMENT,
  `expert_id`              BIGINT       NOT NULL,
  `version`                INT          NOT NULL,
  `persona`                TEXT         NOT NULL COMMENT '角色描述',
  `methodology`            TEXT         NOT NULL COMMENT '工作方法',
  `prompt_template`        TEXT         NOT NULL,
  `tool_policy_json`       JSON         NULL,
  `knowledge_profile_json` JSON         NULL,
  `estimated_credits`      INT          NOT NULL DEFAULT 10,
  `created_at`             DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ev_expert_version` (`expert_id`, `version`),
  CONSTRAINT `fk_ev_expert` FOREIGN KEY (`expert_id`) REFERENCES `experts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Expert Group 身份
CREATE TABLE IF NOT EXISTS `expert_groups` (
  `id`                BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`           BIGINT       NULL,
  `code`              VARCHAR(64)  NOT NULL,
  `name`              VARCHAR(128) NOT NULL,
  `category`          VARCHAR(32)  NOT NULL,
  `captain_expert_id` BIGINT       NOT NULL,
  `status`            VARCHAR(16)  NOT NULL DEFAULT 'active',
  `description`       TEXT         NULL,
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_eg_code` (`code`, `user_id`),
  CONSTRAINT `fk_eg_captain` FOREIGN KEY (`captain_expert_id`) REFERENCES `experts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Expert Group 不可变版本
CREATE TABLE IF NOT EXISTS `expert_group_versions` (
  `id`                        BIGINT       NOT NULL AUTO_INCREMENT,
  `group_id`                  BIGINT       NOT NULL,
  `version`                   INT          NOT NULL,
  `orchestration_policy_json` JSON         NULL,
  `output_schema_json`        JSON         NULL,
  `estimated_credits`         INT          NOT NULL DEFAULT 30,
  `created_at`                DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_egv_group_version` (`group_id`, `version`),
  CONSTRAINT `fk_egv_group` FOREIGN KEY (`group_id`) REFERENCES `expert_groups` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Group 成员（N:N）
CREATE TABLE IF NOT EXISTS `expert_group_members` (
  `group_version_id`  BIGINT       NOT NULL,
  `expert_version_id` BIGINT       NOT NULL,
  `role`              VARCHAR(32)  NOT NULL COMMENT 'captain | member',
  `order_no`          INT          NOT NULL DEFAULT 0,
  `is_required`       TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`group_version_id`, `expert_version_id`),
  CONSTRAINT `fk_egm_gv` FOREIGN KEY (`group_version_id`)  REFERENCES `expert_group_versions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_egm_ev` FOREIGN KEY (`expert_version_id`) REFERENCES `expert_versions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 用户偏好（收藏 / 最近使用）
CREATE TABLE IF NOT EXISTS `user_expert_preferences` (
  `user_id`        BIGINT       NOT NULL,
  `expert_id`      BIGINT       NOT NULL,
  `is_favorite`    TINYINT(1)   NOT NULL DEFAULT 0,
  `last_used_at`   DATETIME(3)  NULL,
  PRIMARY KEY (`user_id`, `expert_id`),
  CONSTRAINT `fk_uep_user`   FOREIGN KEY (`user_id`)   REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_uep_expert` FOREIGN KEY (`expert_id`) REFERENCES `experts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 运行（不可变快照）
CREATE TABLE IF NOT EXISTS `expert_runs` (
  `id`                BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`           BIGINT       NOT NULL,
  `source_type`       VARCHAR(16)  NOT NULL COMMENT 'expert | group',
  `source_version_id` BIGINT       NOT NULL,
  `input_json`        JSON         NOT NULL,
  `status`            VARCHAR(16)  NOT NULL DEFAULT 'draft'
                      COMMENT 'draft|queued|planning|running|synthesizing|completed|failed|cancelled|needs_input',
  `plan_summary`      TEXT         NULL,
  `result_json`       JSON         NULL,
  `estimated_credits` INT          NOT NULL DEFAULT 0,
  `actual_credits`    INT          NOT NULL DEFAULT 0,
  `started_at`        DATETIME(3)  NULL,
  `finished_at`       DATETIME(3)  NULL,
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_runs_user_status`  (`user_id`, `status`),
  KEY `idx_runs_user_created` (`user_id`, `created_at`),
  CONSTRAINT `fk_runs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 运行步骤
CREATE TABLE IF NOT EXISTS `run_steps` (
  `id`                BIGINT       NOT NULL AUTO_INCREMENT,
  `run_id`            BIGINT       NOT NULL,
  `parent_step_id`    BIGINT       NULL,
  `expert_version_id` BIGINT       NOT NULL,
  `step_type`         VARCHAR(16)  NOT NULL COMMENT 'plan | execute | synthesize',
  `title`             VARCHAR(255) NOT NULL,
  `status`            VARCHAR(16)  NOT NULL DEFAULT 'waiting' COMMENT 'waiting|running|done|failed|cancelled',
  `input_json`        JSON         NULL,
  `output_json`       JSON         NULL,
  `started_at`        DATETIME(3)  NULL,
  `finished_at`       DATETIME(3)  NULL,
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_steps_run` (`run_id`, `created_at`),
  CONSTRAINT `fk_steps_run` FOREIGN KEY (`run_id`)            REFERENCES `expert_runs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_steps_parent` FOREIGN KEY (`parent_step_id`) REFERENCES `run_steps` (`id`),
  CONSTRAINT `fk_steps_ev`   FOREIGN KEY (`expert_version_id`) REFERENCES `expert_versions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 步骤 DAG 依赖
CREATE TABLE IF NOT EXISTS `run_step_dependencies` (
  `step_id`            BIGINT NOT NULL,
  `depends_on_step_id` BIGINT NOT NULL,
  PRIMARY KEY (`step_id`, `depends_on_step_id`),
  CONSTRAINT `fk_rsd_step` FOREIGN KEY (`step_id`)            REFERENCES `run_steps` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rsd_dep`  FOREIGN KEY (`depends_on_step_id`) REFERENCES `run_steps` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 实时事件（M6.1/M6.2 轮询；M6.3 改 SSE）
CREATE TABLE IF NOT EXISTS `run_events` (
  `id`                   BIGINT       NOT NULL AUTO_INCREMENT,
  `run_id`               BIGINT       NOT NULL,
  `step_id`              BIGINT       NULL,
  `sequence`             INT          NOT NULL COMMENT '同 run 内递增序号',
  `event_type`           VARCHAR(32)  NOT NULL COMMENT 'status_change | message | error | artifact',
  `display_payload_json` JSON         NULL,
  `created_at`           DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_events_run_seq` (`run_id`, `sequence`),
  CONSTRAINT `fk_events_run`  FOREIGN KEY (`run_id`)  REFERENCES `expert_runs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_events_step` FOREIGN KEY (`step_id`) REFERENCES `run_steps` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 产物元信息（文件由对象存储托管，DB 仅存 key）
CREATE TABLE IF NOT EXISTS `run_artifacts` (
  `id`            BIGINT       NOT NULL AUTO_INCREMENT,
  `run_id`        BIGINT       NOT NULL,
  `step_id`       BIGINT       NULL,
  `object_key`    VARCHAR(512) NOT NULL,
  `sha256`        CHAR(64)     NOT NULL,
  `mime_type`     VARCHAR(64)  NULL,
  `size_bytes`    BIGINT       NOT NULL DEFAULT 0,
  `metadata_json` JSON         NULL,
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_artifact_run`  FOREIGN KEY (`run_id`)  REFERENCES `expert_runs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_artifact_step` FOREIGN KEY (`step_id`) REFERENCES `run_steps` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 信用账本（M6.3 实装；M6.1/M6.2 仅占位）
CREATE TABLE IF NOT EXISTS `credit_ledger` (
  `id`              BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`         BIGINT       NOT NULL,
  `run_id`          BIGINT       NULL,
  `entry_type`      VARCHAR(16)  NOT NULL COMMENT 'estimate | charge | refund',
  `amount`          INT          NOT NULL COMMENT '正数 = 扣费',
  `idempotency_key` VARCHAR(64)  NOT NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_credit_idemp` (`idempotency_key`),
  KEY `idx_credit_user_time` (`user_id`, `created_at`),
  CONSTRAINT `fk_credit_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_credit_run`  FOREIGN KEY (`run_id`)  REFERENCES `expert_runs` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
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
8. **M6 Group 简化为串行** → M6.2 不实现 DAG 并行调度，复杂 Group（>3 members）响应可能 30s+；M6.3 升级为真正的并行。
9. **M6 轮询代替 SSE** → M6.1 / M6.2 用每 2s GET `/expert-runs/{id}`；前端开销小，后端无状态；M6.3 升级 SSE。
10. **M6 用户级目录 vs 全局内置** → 内置 6 + 3 用 `user_id=NULL` 表示全局可见；自定义（暂未开放）走 `user_id=<self>`；查询用 `user_id IS NULL OR user_id = ?`。

---

## §7 变更日志

| 日期 | 里程碑 | 变更 |
|---|---|---|
| 2026-07-30 | M0 | 首版脚手架 + 首页 Dashboard + 3 套主题交付 |
| 2026-08-03 | M6.1~M6.3 | 专家工作台立项：参考 `docs/expert-workbench-plan.md`，分 3 阶段（M6.1 数据契约+UI+Mock / M6.2 真 AI 接入+配置页+打通 / M6.3 DAG+SSE+信用账本预留）。技术栈沿用 MySQL + SqlSugar + AI 网关，AI Key 加密存后端。新增"专家"Tab；DDL 11 张表增入 §5；端点 8 个增入 §4.2 |
| 2026-08-03 | M3 → M6 合并 | M3（AI 周报/日报）切片整体并入 M6.2，作为内置 Skill 中的 `daily-report` / `weekly-report` |

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
| 2026-08-03 | M6 新增"专家"Tab | 与 `docs/expert-workbench-plan.md`"不新增 Tab"建议相反 | 用户明确要求；底部 Tab 改 5 个（首页/待办/日历/专家/我的） |
| 2026-08-03 | M6 沿用 MySQL + SqlSugar | 不切 SQL Server + EF Core | 与 BACKEND_DESIGN 决策一致；DDL 已统一为 MySQL 8.0 风格 |
| 2026-08-03 | M6.2 Group 简化为串行 | 不实现 DAG 并行 | 工作量控制，避免本轮过度工程；M6.3 升级 |
| 2026-08-03 | M6.1/M6.2 轮询代替 SSE | 2s GET 一次 | 简化实现；架构预留 SSE 升级位 |
| 2026-08-03 | M3 整体并入 M6.2 | M3 范围（Skill 池 / 日报周报）与 M6 内置 Skill 重复 | 文档统一收敛；M3 不再单独排期 |

---

## §11 变更日志

| 日期 | 里程碑 | 变更 |
|---|---|---|
| 2026-07-30 | M0 | 首版脚手架 + 首页 Dashboard + 3 套主题交付 |
| 2026-07-30 | M0.5~M5 | 计划文档完善：插入 M0.5 过渡；M1/M2 工期重排；新增任务切片总览 §3.0；补全 C# 后端 §4.3~4.7；新增 §8 已知缺陷、§9 占位、§10 决策记录、§11 变更日志 |