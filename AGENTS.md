# NexusMind 执行规范

> 根级指令见 `../AGENTS.md`。开发闭环：**读开发计划 → 读后端已发布 API 出入参 → 对接实现 → 回写文档**。后端 API 出入参唯一事实来源 = 运行中 Swagger（`http://localhost:5280/swagger`）+ `../core/HomeMind.Api/Controllers/` 的 DTO；本文件接口表是快速索引，字段以 Swagger 为准。后端未发布该接口时停止并报告缺口，不 mock。

## 文档链（开发前必读）

| 文档 | 路径 | 作用 |
| --- | --- | --- |
| 产品总设计 | `../core/docs/product.md` | 功能卡、产品原则、双端分工 |
| 移动端开发计划 | `docs/development-plan.md` | 执行队列：M0-M4 阶段 + 完成定义 |
| 移动端产品体验 | `docs/mobile-product.md` | 五入口职责、与 Web 分工、安全边界 |
| 跨端 API 契约 | `../core/docs/api-integration.md` | 路由索引、认证刷新、错误码、确认流 |
| UI 风格指南 | `docs/UI_STYLE_GUIDE.md` | 设计令牌、排版、组件状态、语义色 |
| 开发规范 | `docs/DEVELOPMENT_GUIDELINES.md` | Dart/状态/路由/数据/质量规则 |

## 技术与架构

- 技术栈：Flutter Material 3、Dart `^3.12.2`、Provider、GoRouter、Dio；复用既有安全/本地存储，不新增竞争性的状态、路由、网络或持久化框架。
- 目录职责：`core/` 共享基础设施；`features/<feature>/` Repository 契约、DTO 与本地/HTTP 实现；`pages/` UI 与页面状态；`main.dart` 依赖装配；`router.dart` 是唯一路由定义。
- 页面只依赖 Repository 抽象与 DTO；Repository 负责 API/存储；跨页面依赖通过 `MultiProvider` 注入；Widget 不得直接创建客户端、Repository、偏好设置或调用 Dio/`ApiClient`。
- 先定义 Repository 接口，再实现本地或 HTTP 版本；HTTP 必须经 `ApiClient` 和显式 DTO parser，保留后端字段大小写映射。
- `ChangeNotifier` 仅用于需响应式刷新的应用状态；页面局部交互使用 `StatefulWidget`；`watch` 用于响应式读取，`read` 用于命令；每次 `await` 后更新 UI 前检查 `mounted`。
- 首次加载在 `initState` 发起，异步界面必须支持 loading、empty、error、retry；命令执行期间禁止重复提交；Tab 切换用 `go`，可返回详情/创建流用 `push`。

## 安全与交互

- 前端仅访问自有后端 API；不得持有第三方 Key、凭据或 Endpoint，不得直连 AI、Home Assistant、天气、日历或其他供应商；后端负责脱敏、校验、限流、凭据托管与副作用回写。
- 不显示、不记录 Prompt、模型思考过程、原始事件载荷、供应商字段、协议字段、设备实体 ID、密码、Token、凭据或完整 API 响应。
- 写设备、创建自动化及 `RunAction` 必须先展示影响范围、权限和确认要求；确认时使用新幂等键，提交中禁用按钮，重复请求返回既有结果。
- `AgentRun` 仅允许 `draft`、`queued`、`planning`、`running`、`completed`、`failed`、`cancelled`；按 `sequence` 显示可公开事件，终态或页面释放后停止轮询，重新进入可用 Run ID 恢复结果。
- SmartHome 仅消费标准化空间、设备、能力、状态、场景 DTO；Connector 只显示健康、授权、发现、成员权限与 Tool 可用性。

## 接口契约

全部路径以 `/api/v1` 为前缀；异常码：`0` 成功，`400` 参数错误，`401` 未鉴权/Token 过期，`403` 无权，`404` 不存在，`409` 冲突，`422` 业务校验失败，`500` 服务异常。

| 接口路径 | 入参 | 出参 | 异常码 |
| --- | --- | --- | --- |
| `POST /auth/register` | `RegisterRequest` | `LoginResultDto` | 通用 |
| `POST /auth/login` | `LoginRequest` | `LoginResultDto` | 通用 |
| `POST /auth/refresh` | `RefreshRequest` | `LoginResultDto` | 通用 |
| `GET /auth/me` | 无 | `UserDto` | 通用 |
| `GET /todos` | `since,status,type` | `List<TodoDto>` | 通用 |
| `POST /todos` | `TodoCreateDto` | `TodoDto` | 通用 |
| `PUT /todos/{id}` | `TodoUpdateDto` | `TodoDto` | 通用 |
| `DELETE /todos/{id}` | 无 | `{id}` | 通用 |
| `POST /todos/{id}/subtasks` | `{text}` | `SubtaskDto` | 通用 |
| `PUT /todos/{id}/subtasks/{subId}` | `{text?,done?}` | `SubtaskDto` | 通用 |
| `DELETE /todos/{id}/subtasks/{subId}` | 无 | `{id}` | 通用 |
| `GET /calendar/events` | `from,to` | `List<CalendarEventDto>` | 通用 |
| `POST /calendar/events` | `CalendarEventCreateDto` | `CalendarEventDto` | 通用 |
| `PUT /calendar/events/{id}` | `CalendarEventUpdateDto` | `CalendarEventDto` | 通用 |
| `DELETE /calendar/events/{id}` | 无 | `{id}` | 通用 |
| `GET /calendar/subscriptions` | 无 | `List<IcalSubscriptionDto>` | 通用 |
| `POST /calendar/subscriptions` | `{url,name?}` | `IcalSubscriptionDto` | 通用 |
| `PUT /calendar/subscriptions/{id}` | `{enabled?,name?}` | `IcalSubscriptionDto` | 通用 |
| `DELETE /calendar/subscriptions/{id}` | 无 | `{id}` | 通用 |
| `POST /calendar/ical/fetch` | `{url}` | `{events:List<IcalEventDto>}` | 通用 |
| `GET /skills` | 无 | `List<AiSkillDto>` | 通用 |
| `POST /skills` | `AiSkillCreateDto` | `AiSkillDto` | 通用 |
| `PUT /skills/{id}` | `AiSkillUpdateDto` | `AiSkillDto` | 通用 |
| `DELETE /skills/{id}` | 无 | `{id}` | 通用 |
| `POST /ai/generate` | `{scope,prompt,input,model?,temperature?}` | `{content,usage}` | 通用 |
| `GET /ai/config` | 无 | `AiConfigDto` | 通用 |
| `PUT /ai/config` | `AiConfigUpdateDto` | `AiConfigDto` | 通用 |
| `POST /ai/test` | `AiConfigUpdateDto` | `{available,model}` | 通用 |
| `GET /experts` | `query,category` | `List<ExpertDto>` | 通用 |
| `GET /experts/{id}` | 无 | `ExpertDetailDto` | 通用 |
| `GET /expert-runs` | `cursor?,limit?` | `RunPageDto` | 通用 |
| `POST /expert-runs` | `CreateExpertRunRequest` | `ExpertRunDto` | 通用 |
| `GET /expert-runs/{id}` | 无 | `ExpertRunDto` | 通用 |
| `GET /expert-runs/{id}/events` | `afterSequence?` | `List<RunEventDto>` | 通用 |
| `POST /expert-runs/{id}/cancel` | 无 | `ExpertRunDto` | 通用 |
| `POST /expert-runs/{id}/retry` | `{idempotencyKey}` | `ExpertRunDto` | 通用 |
| `POST /expert-runs/{id}/actions` | `ConfirmRunActionRequest` | `RunActionResultDto` | 通用 |
| `GET /weather` | `lat,lon` | `WeatherDto` | 通用 |
| `GET /homes/{homeId}/finance/transactions` | `from?,to?,category?` | `List<FinanceTransactionView>` | 通用 |
| `GET /homes/{homeId}/finance/summary` | `from?,to?` | `FinanceSummaryView` | 通用 |
| `POST /homes/{homeId}/finance/transactions/import` | `FinanceImportRequest` | `{imported,skipped}` | 通用 |
| `GET /homes/{homeId}/billing/accounts` | 无 | `List<BillingAccountView>` | 通用 |
| `POST /homes/{homeId}/billing/accounts` | `BillingAccountCreateRequest` | `BillingAccountView` | 通用 |
| `POST /homes/{homeId}/billing/accounts/{accountId}/payments` | `BillingPaymentRecordRequest` | `BillingPaymentRecordView` | 通用 |
| `GET /homes/{homeId}/billing/reminders` | `asOf?` | `List<BillingReminderView>` | 通用 |
| `GET /homes/{homeId}/schedule/events` | `from?,to?` | `List<FamilyScheduleEventView>` | 通用 |
| `GET /homes/{homeId}/schedule/conflicts` | `from?,to?` | `List<FamilyScheduleConflictView>` | 通用 |
| `GET /homes/{homeId}/schedule/availability` | `from?,to?,durationMinutes?` | `List<FamilyScheduleAvailabilityView>` | 通用 |
| `GET/POST /homes/{homeId}/schedule/document-deadlines` | `FamilyDocumentDeadlineCreateRequest`（POST） | `List<FamilyDocumentDeadlineView>`（GET）/`FamilyDocumentDeadlineView`（POST） | 通用 |
| `GET /homes/{homeId}/schedule/reminders` | `asOf?` | `List<FamilyScheduleReminderView>` | 通用 |
| `GET /homes/{homeId}/schedule/tomorrow-preview` | `asOf?` | `FamilyTomorrowPreviewView` | 通用 |
| `GET /attachments/{id}` | 无 | 二进制流 | 通用 |
| `POST /attachments` | `multipart/form-data` | `AttachmentDto` | 通用 |
| `DELETE /attachments/{id}` | 无 | `{id}` | 通用 |
| `POST /sync/pull` | `{entity,cursor?,limit?}` | `{items,nextCursor,serverTime}` | 通用 |
| `POST /sync/push` | `{entity,items,idempotencyKey}` | `{accepted,conflicts,serverTime}` | 通用 |
| `POST /push/subscribe` | `{endpoint,p256dh,auth}` | `{id}` | 通用 |
| `DELETE /push/subscribe/{id}` | 无 | `{id}` | 通用 |

### 规划接口

| 接口路径 | 入参 | 出参 | 异常码 |
| --- | --- | --- | --- |
| `GET /smart-home/spaces` | 无 | `List<SmartHomeSpaceDto>` | 通用 |
| `GET /smart-home/devices` | `spaceId` | `List<SmartHomeDeviceDto>` | 通用 |
| `GET /smart-home/scenes` | 无 | `List<SmartSceneDto>` | 通用 |
| `POST /smart-home/scenes/{key}/run` | `idempotencyKey` | 场景执行结果 | 通用 |
| `POST /expert-files` | multipart 或预签名上传请求 | `{fileId}` | 通用 |
| `GET /expert-files` | 无 | `List<ExpertFileDto>` | 通用 |
| `DELETE /expert-files/{id}` | 无 | `{id}` | 通用 |
| `POST /ai/chat` | 脱敏聊天请求 | 聊天结果 | 通用 |
| `POST /ai/stream` | 脱敏流式请求 | 流式聊天结果 | 通用 |

`CreateExpertRunRequest` 包含 `sourceType(expert|group)`、`sourceId`、`inputJson`、`idempotencyKey`；`inputJson.fileRefs` 只传 `{id,role}`，不传文件二进制。`ConfirmRunActionRequest` 包含 `actionType`、`requestJson`、`idempotencyKey`；同一用户的同一幂等键必须返回同一结果。

## 计划

| 任务名 | 状态(待办/进行中/完成) |
| --- | --- |
| F1 五 Tab、Plan 与 SmartHome 本地实现 | 完成 |
| F2 Connector 中心 | 完成 |
| F3 Expert Run DTO、时间线与确认流 | 完成 |
| F4 Dashboard 标准化数据接入 | 完成 |
| F5 根流程 Widget/Repository 测试 | 完成 |
| F6-pre AgentRun 七态与设备行动一致性 | 完成 |
| F6 SmartHome HTTP 接入 | 完成 |
| F7 Todo HTTP 接入 | 完成 |
| F8 Calendar HTTP 接入 | 完成 |
| F9 单专家文件上下文 | 进行中（功能已实现，Widget 测试验证待修复） |
| F10 专家团多选启动 | 待办 |
| F11 后端代理层联通 | 待办 |

## UI

| UI库 | 主色 | 圆角 | 间距 | 字体 |
| --- | --- | --- | --- | --- |
| Flutter Material 3 + `NexusTheme`/`NexusSurface` | `#4DA3FF`；完成/健康 `#3DD6A0` | Surface `20px`；控件 `16px` | 页面 `20px` 横/`24px` 纵；主区块 `24px`；关联控件 `12px`；底部 `100px` | `28/18/15/13px`；中文优先 PingFang SC |

- 使用 `Theme.of(context)`、`NexusLayout` 与共享 `ColorScheme`，同时支持浅深色和 320–430px 宽度；功能页不得硬编码白、黑、灰或新增视觉 Token。
- 每页最多一个主行动；`NexusSurface` 为默认信息块；异步请求不得在 `build` 中发起。

## 开发规范

命名:变量camelCase,组件PascalCase,文件kebab-case|禁any|ESLint

- 交付前执行 `dart format`、`flutter analyze` 和相关 `flutter test`；新增 Repository 必须有映射/错误测试，关键页面或流程必须有 Widget 测试。
- 产品范围、信息架构、数据边界或跨端流程变更：先更新产品总纲，再同步受影响文档；UI Token/组件变更同步 `docs/UI_STYLE_GUIDE.md` 与 `lib/core/ui/nexus_theme.dart`；工程架构变更同步 `docs/DEVELOPMENT_GUIDELINES.md`。

## 下一步计划协议

**用户说「按照下一步计划进行开发」（或「继续开发」）时，自动执行：**

1. 读取 `docs/development-plan.md` 的「下一步」区，选依赖已满足的首个 `待做` 任务。
2. 若该任务在文档中**尚未展开详细任务表**：先在 `docs/development-plan.md` 按「P3-F 家庭财务执行计划」表格格式生成任务表（ID/状态/依赖/编码任务/改动位置/完成标准与验证），写进文档后再开发。**禁止跳过计划直接写代码。**
3. 读 `../core/docs/product.md` 功能卡 + `docs/mobile-product.md` 五入口职责；核对现有代码与测试，只做最小改动。
4. 核对后端 API：`../core/HomeMind.Api/Controllers/` + Swagger 确认路由/入参（camelCase）/出参（PascalCase）/权限/错误码；**后端未发布该接口 → 停止并报告缺口，不 mock。**
5. 先定义 Repository 接口 + DTO 显式 parser → 实现页面（loading/empty/error/retry 四态）→ 补 Repository/Widget 测试。
6. 编码前任务状态改 `进行中`；验证后改 `完成`；未通过保留 `进行中` 并报告阻塞。
7. 验证：`dart format lib test` → `flutter analyze` → 相关 `flutter test`。
8. **回写文档**（与代码同一变更）：`docs/development-plan.md` 状态、本文件接口表、`docs/mobile-product.md` 受影响入口；UI 变更同步 `docs/UI_STYLE_GUIDE.md`。
9. 若依赖的客户端目录或运行环境不在当前工作区，停止并说明缺少的仓库/环境；不得虚构实现。
