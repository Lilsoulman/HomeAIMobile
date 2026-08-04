# NexusMind 执行规范

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
| F8 Calendar HTTP 接入 | 待办 |
| F9 单专家文件上下文 | 待办 |
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
