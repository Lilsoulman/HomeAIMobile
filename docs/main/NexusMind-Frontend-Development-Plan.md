# NexusMind 前端开发计划

> 来源文档：
> - `D:\HomeMind\core\docs\main\NexusMind-Product-Master-Design.md`（产品总纲）
> - `D:\HomeMind\core\docs\main\NexusMind-Backend-Development.md`（后端设计）
> - `D:\HomeMind\core\docs\frontend-api-integration.md`（前后端逐接口合约）
> - `D:\HomeMind\mobile\docs\main\NexusMind-Frontend-Development.md`（前端产品/UX 规范）
>
> 本文档是 Flutter 端的执行记录。每完成一个迭代都要更新本页；产品范围与接口变化仍归上面三份源文档所有。
>
> 最近更新：2026-08-04
> 下一段计划（仅在文档对齐，未开始执行）：F8 Calendar HTTP 接入 → 详见下文 §F8。

## 1. 基线

- 技术栈：Flutter Material 3、Provider、GoRouter、Dio，沿用现有 `ApiClient`。
- 五个底部 Tab：Home、AI、Plan、Home+、Me。
- 页面只依赖 Repository 抽象与 DTO；本地实现在 `main.dart` 装配，只有当字段级 API 合约发布后才补 HTTP 实现。
- 设备写入、自动化创建等行动必须经用户可见的确认路径；供应商原始字段、凭据、Prompt、模型思考过程一律不上屏。
- 任何用户可见的异步界面都必须具备 loading、empty、error、retry 状态。
- **统一后端代理原则**：所有第三方服务（Home Assistant、天气、日历、各家 AI 模型）以及前端曾经直连的 AI Key 模式，都必须改走自己的后端 API。前端不持有第三方 Key，不直连第三方 Endpoint。后端负责问题脱敏、指令校验、限流与回写。

## 2. 当前能力清单

| 区块 | 状态 | 说明 |
| --- | --- | --- |
| 应用壳与主题 | 已完成 | Material 3 + Nexus 主题 Token。 |
| Home Dashboard | 已完成 | AI 优先 Dashboard，链接指向 Plan 与 AI。 |
| AI 专家目录/工作台 | 已完成 | Mock 工作流保留在 AI Tab。 |
| Todo 与 Calendar | 已完成 | 通过 Plan 子路由访问。 |
| Home+ 域与页面 | 已完成 | 本地标准化空间、设备摘要、场景。 |
| Connector 中心 | 已完成 | 本地连接器契约、Me→Connector 路由。 |
| Expert Run API 接入 | 已完成 | 目录与 Run 走已发布后端 API。 |
| AgentRun 收尾与一致性 | 已完成（F6-pre） | DTO/Action 状态已收敛到产品总纲的七态枚举，已支持 `smart_home_device` 行动与设备/能力/目标值展示，并验证单次提交与幂等键。 |
| SmartHome API 接入 | 已完成（F6） | Home+ 与 Dashboard 的 SmartHome 数据已可按 `USE_LOCAL_DATA` 切换到 HTTP 仓库。 |
| Todo API 接入 | 已完成（F7） | Dashboard 与 Plan 在 HTTP 模式下共享 `HttpTodoRepository`。 |
| 单专家文件上下文 | 计划中（F9） | 专家中心支持上传文件并入参，再发起 Run。 |
| 专家团多选启动 | 计划中（F10） | AI 中心支持多选专家，以专家团方式启动 Run。 |

## 3. 交付计划

| 迭代 | 范围 | 验收 | 状态 |
| --- | --- | --- | --- |
| F1 | 用 Home/AI/Plan/Home+/Me 替换底部导航；Todo、Calendar 合并到 Plan；创建 SmartHome 仓库契约、本地实现与 Home+ 空间优先页。 | 五个 Tab 全部可达；Plan 切换任务/日历；Home+ 完整呈现 loading/error/empty/数据态，不暴露供应商字段。 | 已完成 |
| F2 | 新增 Connector 仓库与 Me→Connector 路由。 | 健康、授权、发现、断连、重试状态可区分，凭据不显示。 | 已完成 |
| F3 | 新增 Expert Run DTO/仓库、可理解的时间线与确认流。 | 轮询在终态停；确认按钮单次提交；只渲染可展示事件。 | 已完成 |
| F4 | Dashboard 接入 Home+ 与 Plan 的标准化数据，保留单卡失败重试与新鲜度。 | 每张卡片可独立重试并显示更新时间。 | 已完成 |
| F5 | 补齐根流程的 Widget 与仓库测试。 | `dart format`、`flutter analyze`、相关测试通过。 | 已完成 |
| F6-pre | AgentRun 收尾与一致性：DTO 收敛到 `draft/queued/planning/running/completed/failed/cancelled` 七态；`ExpertRunActionType` 扩展 `smart_home_device`；Run 详情页支持空间/设备/能力/目标值展示；确认按钮单次提交与新 UUID 幂等键；不改 UI 视觉、不接 SmartHome/Connector HTTP 仓。 | `dart format`、`flutter analyze` 零新增诊断；3 个 AgentRun 单测、设备行动 Widget 用例与受影响回归测试全绿；静态 grep 不出现 `prompt / 思考链 / credential / token` 在可见文本路径；`useLocalData=true` 路径可完成模拟设备的 confirm 流程且不重复提交。 | 已完成 2026-08-04 |
| F6 | 把 `SmartHomeRepository` 接到已发布的 `/smart-home/*` 端点，保留既有的安全展示。 | Home+、Dashboard 家庭/场景卡、场景确认流全部走 HTTP 仓库；loading/empty/error/retry 与 F1/F4 一致；不渲染供应商或凭据字段。 | 已完成 2026-08-04 |
| F7 | 把 `TodoRepository` 接到已发布的 Todo 端点；Dashboard 今日计划、Plan 任务视图、Expert Run 确认后回写统一走 HTTP。 | Dashboard、Plan、Run 三处使用同一 HTTP 仓库；单卡失败可重试；幂等键正确；不破坏既有确认流。 | 已完成 2026-08-04 |
| F8 | 把 `CalendarRepository` 接到已发布的 Calendar 端点；当日视图与 Plan 日历段同步。 | 计划日历视图与 Dashboard 今日计划读数一致；loading/empty/error/retry 行为完整。 | 计划中 |
| F9 | 单专家文件上下文：在 AI 专家中心支持上传、命名、删除、复用本地文件；选择单专家并把文件以引用形式入参发起 Run。 | 专家详情显示已绑定文件；Run 输入仅传文件引用 ID，不传文件二进制；上传/选择/移除/发起 Run 闭环；不上传敏感凭据。 | 计划中 |
| F10 | 专家团多选启动：AI 中心支持勾选多个专家以"团队"模式启动 Run，时间线、确认流遵循既有 Run 规范。 | 团队选择态可持久化；Run 详情能区分"单/团"；确认按钮单次提交；时间线只展示可公开事件。 | 计划中 |
| F11 | 后端代理层联通：所有第三方 Connector、AI 调用统一经过后端 API；前端移除直连 AI Key、移除直连第三方 Endpoint。 | 客户端无任何第三方 Key；所有 Connector、AI 请求均经 `ApiClient` 抵达自有后端；后端返回的脱敏后结果与原本 UI 完全一致。 | 计划中 |

## 4. 迭代记录

### F1 - 已完成 2026-08-04

- 用 Home/AI/Plan/Home+/Me 替换底部 Tab，原 Todo/Calendar 以可返回的 Plan 子路由保留。
- 新增 `SmartHomeRepository`、标准化空间/设备摘要/场景 DTO，并在 `main.dart` 注册本地实现。
- Home+ 提供 loading、empty、error、refresh、场景确认、单次提交等状态；不渲染 Connector、协议、凭据、供应商原始字段。
- Dashboard 导航指向新的 Plan 与 AI 位置；专家详情改为可返回路由。
- 计划中的后端路由为 `GET /smart-home/spaces`、`GET /smart-home/devices`、`GET /smart-home/scenes`、`POST /smart-home/scenes/{key}/run`。字段级合约当时尚未发布，HTTP 仓库刻意延后。
- 验证：`dart format`、受影响文件 scoped `flutter analyze` 无新增诊断、`flutter test --no-pub test/local_repositories_test.dart` 5 用例通过。
- 全量 `flutter analyze` 仍存在 23 条历史 info 级别 lint，位于本迭代之外的旧 page 文件；本次未引入新诊断。

### F2 - 已完成 2026-08-04

- 新增 `ConnectorRepository`、标准化 Provider 与连接 DTO；本地实现支持 online、authorizing、discovering、disconnected、retry-required。
- 新增 `/me/connectors` 可返回路由与 Me 入口；Connector 中心提供 loading/empty/error/refresh/authorization/discovery/retry/disconnect-confirmation 状态，禁止重复提交。
- 页面只展示连接器名、连接健康、权限摘要；不索取、不展示、不记录凭据。
- HTTP 实现延后：当时 `docs/api-integration.md` 尚未发布 Connector 端点路径与字段级响应合约。
- 验证：`dart format`、`flutter test --no-pub test/local_repositories_test.dart test/connector_center_page_test.dart` 共 7 用例通过；全量 `flutter analyze` 仍是同样 23 条历史 lint。

### F3 - 已完成 2026-08-04

- 用已发布的 `/experts` 目录与 `/expert-runs` 接口替换原先未合约化的 Expert Workspace 路由。新仓库只映射目录元数据、可展示 Run 摘要、标准化状态、有序事件，不渲染输入负载、模型输出、Prompt、原始事件负载。
- 新增 `ExpertRunRepository` 的本地与 HTTP 实现，并在 `main.dart` 注入。Run 页只在非终态轮询，遇到终态或 dispose 立即停止，按合约提供 cancel/retry。
- 新增对 plan/todo/calendar 行动的显式确认对话框；提交期间命令禁用；每次确认使用全新幂等键。
- 验证：`dart format`、scoped `flutter analyze` 无新增诊断、聚焦的仓库/Widget 测试通过。

### F4 - 已完成 2026-08-04

- Dashboard 家庭状态与场景入口接入标准化 `SmartHomeRepository`；计划摘要接入既有 Todo/Calendar 仓库。Dashboard 中静态设备与场景示例已清除。
- Home、Plan、Expert Dashboard 三块独立加载：单卡失败不影响其他卡，可本地重试，并按需呈现 loading/empty。Home 与 Plan 卡片显示数据源更新时间。
- Dashboard 场景入口跳转 Home+ 走既有的可见确认流；Dashboard 不直接写设备、不绕过确认。
- 验证：`dart format`、scoped `flutter analyze lib/pages/dashboard_page.dart test/dashboard_page_test.dart` 无新增诊断、`flutter test --no-pub test/dashboard_page_test.dart` 1 个覆盖"部分失败 + 独立重试"的 Widget 用例通过。

### F5 - 已完成 2026-08-04

- 补齐 Plan 任务/日历摘要切换与 Home+ 场景确认流的 Widget 测试，后者验证"必须经过可见确认才能执行场景"。
- 根流程覆盖现包含认证跳转、Dashboard 部分失败/独立重试、AI 行动确认、Plan、Home+、Connector 中心；既有本地与专家仓库测试覆盖对应状态转移。

### F6-pre - 已完成 2026-08-04（AgentRun 收尾与一致性）

**范围。** 在不引入新功能、不动 UI 视觉、不接 SmartHome/Connector HTTP 仓的前提下，把 AgentRun 流程与产品总纲 + 后端 §8 合约对齐到一致形态：

1. `ExpertRunStatus` 收敛为产品总纲七态枚举（`draft | queued | planning | running | completed | failed | cancelled`）；移除 `synthesizing` 别名与 `needsInput` 一等公民状态，统一为兼容视图。
2. `ExpertRunActionType` 扩展 `smartHomeDevices`（`apiValue = 'smart_home_device'`），与后端 `AgentRunAction.actionType` 四种枚举对齐。
3. `ExpertRunDto` 预留 `mode: single|team` 与 `inputJson` 回显字段；`ExpertRunActionDto` 扩展 `deviceId / deviceName / capability / targetValue / spaceName / actionTitle / actionDescription`，兼容 PascalCase / camelCase 两种 key。
4. `expert_workbench_page.dart` Run 详情页：新增"家庭设备行动"分支，展示"空间 / 设备 / 能力 / 目标值"四行；既有 `plan / todos / calendarEvents` 分支保留视觉一致；按钮文案按 `ExpertRunActionType.label` 渲染。
5. 确认按钮：提交期间禁用，每次进入确认对话框生成新 UUID v4 幂等键；离开页面后按 runId 仍可恢复结果；`snackBar` 不显示后端 `Code`。

**唯一依据。** `D:\HomeMind\core\docs\frontend-api-integration.md` 第 8 节（AI Experts and AgentRun module）与 `core/docs/api-implementation.md` 中 Agent Runtime 段。`Expert Files` / `expertIds` 团队模式合约尚未发布，本段只在 DTO 预留字段，不启用 UI 入口。

**改动文件（外科手术式）。**

- `lib/features/expert/dto.dart`：七态枚举与 `smartHomeDevices` 扩展；DTO 字段补全；顶部加注"七状态与四种 actionType"契约说明。
- `lib/features/expert/http_expert_run_repository.dart` 与 `lib/features/expert/local_expert_run_repository.dart`：`confirmAction` 入参扩展 `deviceId / deviceName / capability / targetValue / actionTitle / actionDescription`，按 `actionType` 决定是否写入 `requestJson`；`start` 入参保持不变（团队模式由调用方拼 `expertIds` 进 `inputJson`）。
- `lib/pages/expert_workbench_page.dart`：Run 详情页 Action 列表增加设备行动分支；确认按钮单次提交、UUID v4 幂等键、提交期间禁用。
- `test/expert/agent_run_seven_states_test.dart`、`test/expert/agent_run_action_types_test.dart`、`test/expert/agent_run_dto_pascal_case_test.dart`：新增三个聚焦单测。
- `test/expert_workbench_page_test.dart`：补一条"家庭设备行动在 ActionConfirm 显示四行、按钮禁用、二次进入幂等键不同"的用例。

**保留的行为。** UI 视觉与导航不变；F1–F5 完成的页面/测试全部保留；`useLocalData` 切换不调整；`ApiClient` / `EnvConfig` / `TokenStorage` 不动；不接 SmartHome/Connector HTTP 仓；不拆除任何客户端直连依赖（属 F11）。

**验证。** `dart format` 覆盖所有改动文件；`flutter analyze` 作用于改动文件 + 受影响测试零新增诊断；`flutter test --no-pub` 跑新增三个 AgentRun 单测 + 既有 `local_repositories_test.dart / expert_workbench_page_test.dart / connector_center_page_test.dart / dashboard_page_test.dart / home_plus_page_test.dart / plan_page_test.dart / mock_expert_repository_test.dart`；`lib/features/expert/dto.dart` 不再含 `synthesizing` 字面量；`lib/pages/expert_workbench_page.dart` 可见文本路径不出现 `prompt / 思考链 / 思考过程 / credential / token`（grep 自检）。

**完成记录。** 已通过 `dart format`，受影响文件的 `flutter analyze` 无诊断；上述测试集合共 27 个用例通过，设备行动单独 Widget 测试确认四行详情、提交期间禁用、完成后不再出现设备行动入口，并验证连续确认使用不同 UUID 幂等键；本地仓库测试覆盖设备行动确认后按相同幂等键复用结果。

**阻塞项（不属本段）。** Expert Files 合约（`/expert-files`）与多专家团队启动（`expertIds` + `mode: single|team`）合约尚未发布；本段只做 DTO 字段预留，不启用 UI 入口。Connector 端点 `/api/v1/connectors` 后端 Vault 未启用，创建会返回 503；本段不接入 Connector HTTP 仓。

### F6 - 已完成 2026-08-04

**完成范围。** 新增 `HttpSmartHomeRepository`，并在 `useLocalData == false` 时替换内存版 `LocalSmartHomeRepository`。`SmartHomeRepository` 契约、DTO 使用方和页面 UI 保持不变，因此 Home+、Dashboard 家庭/场景卡与既有确认流自动走 HTTP 实现。

**唯一依据。** 四个端点的字段级请求/响应合约来自 `D:\HomeMind\core\docs\frontend-api-integration.md`（§SmartHome）：

- `GET /smart-home/spaces`
- `GET /smart-home/devices?spaceId=...`
- `GET /smart-home/scenes`
- `POST /smart-home/scenes/{key}/run`

合约在 F6 周期内视为不可变；若后端文档仍有占位或开放问题，F6 在客户端阻塞，直到后端文档落定。

**改动文件（外科手术式）。**

- 新增 `lib/features/smart_home/http_smart_home_repository.dart`，全部请求经 `ApiClient.request`。`GET` 端点映射到标准化 DTO；场景请求带新 UUID 幂等键，成功后刷新场景卡，而不消费后端 Run 内部内容。
- 给 `lib/features/smart_home/dto.dart` 的 `SmartHomeSpaceDto / SmartHomeDeviceDto / SmartSceneDto` 补 `fromJson` 工厂。数值 ID 在 DTO 边界转换为现有字符串 ID；缺失的 `SortOrder` 保持稳定默认值；不新增可展示字段。
- `lib/main.dart` 沿用 Todo / Calendar / Expert 的装配方式：`useLocalData == false` 时选 `HttpSmartHomeRepository(api)`，否则保留 `LocalSmartHomeRepository()`；不改动其他仓库。
- 新增 `test/smart_home/http_smart_home_repository_test.dart`，覆盖四端点映射、`spaceId` 查询参数、场景幂等键和缺字段容错。

**保留的行为。** Home+ 仍只渲染空间名/摘要、设备名/标准化状态、场景名/描述/`lastRunAt`；Dashboard 家庭状态卡与场景入口仍读 `SmartHomeRepository`；场景确认流仍是触发场景的唯一入口。提交后文案明确为“等待确认”，不将后端创建的待确认 Run 误报为已执行；无新状态、无新字段、无新 UI。

**验证。**

- `dart format` 已覆盖所有改动文件。
- `flutter analyze lib/features/smart_home/dto.dart lib/features/smart_home/http_smart_home_repository.dart test/smart_home/http_smart_home_repository_test.dart` 无诊断。包含 `main.dart` 的检查仅报告已有 `_BottomBar` 未使用警告，非本阶段引入。
- `flutter test --no-pub test/smart_home/http_smart_home_repository_test.dart test/local_repositories_test.dart test/home_plus_page_test.dart test/dashboard_page_test.dart` 共 10 个用例通过。
- 尚未连接真实后端做 `USE_LOCAL_DATA=false` 冒烟；HTTP 端点映射已由 `ApiClient` 包络测试覆盖。

**显式不在范围内。** Connector API 接入属于 F11；本阶段不动 Auth、EnvConfig、Expert/Plan/Calendar 仓库；不新增任何确认界面；复用既有 `SmartHomeRepository.runScene`。

### F7 - 已完成 2026-08-04

**完成范围。** 在 `useLocalData == false` 时，Dashboard 与 Plan 通过根注入的 `HttpTodoRepository` 读取和写入 Todo；`TodoRepository` 契约与页面调用点不变。专家 Run 的 Todo 行动继续走已发布的 AgentRun 确认 API，由后端以既有幂等键完成写入，客户端不重复创建 Todo。

**唯一依据。** 端点路径与字段级合约见 `D:\HomeMind\core\docs\frontend-api-integration.md`（§Todo）。仅当后端文档已发布该章节时进入执行；否则阻塞。

**改动文件（外科手术式）。**

- 校验既有 `lib/features/todo/http_todo_repository.dart` 的 `/todos` 与子任务端点映射，并补齐 `update` 对 `type / sortOrder / parentId` 的已发布字段支持。
- `lib/features/todo/dto.dart` 的 `SubtaskDto.fromJson` 同时兼容后端的数值和布尔 `done` 表示；不引入新字段。
- `lib/main.dart` 已保持 `useLocalData == false` 时提供 `HttpTodoRepository(api)`；其他仓库不动。
- 新增 `test/todo/http_todo_repository_test.dart`，覆盖查询过滤、创建、更新、子任务、删除和 API 失败透传；保留现有 Dashboard、Plan 与专家确认测试。

**保留的行为。** Dashboard 今日计划与 Plan 任务视图使用同一根注入的 HTTP 仓库，单卡失败仍可重试；专家 Run 写入路径使用既有确认 API 和幂等键；不破坏既有确认流。

**验证。** `dart format` 覆盖改动文件；`flutter analyze lib/features/todo/dto.dart lib/features/todo/http_todo_repository.dart test/todo/http_todo_repository_test.dart` 无诊断；`flutter test --no-pub test/todo/http_todo_repository_test.dart test/local_repositories_test.dart test/dashboard_page_test.dart test/plan_page_test.dart test/expert_workbench_page_test.dart` 共 12 个用例通过。真实后端的 `USE_LOCAL_DATA=false` 冒烟尚未执行。

### F8 - 计划中

**范围。** 用 `HttpCalendarRepository` 替换 Dashboard 与 Plan 中的本地 Calendar 数据；保留 `CalendarRepository` 契约、DTO、调用点不变。

**唯一依据。** 端点路径与字段级合约见 `frontend-api-integration.md`（§Calendar）。未发布则阻塞。

**改动文件（外科手术式）。**

- 新增 `lib/features/calendar/http_calendar_repository.dart`，对齐 `http_todo_repository.dart`。
- 扩展 `lib/features/calendar/dto.dart` 现有 DTO 的 `fromJson`；不引入新字段。
- `lib/main.dart` 把 `useLocalData == false` 时的 `CalendarRepository` 切换为 HTTP 实现；其他仓库不动。
- 在 `test/calendar/` 新增 HTTP 仓库测试；保留 `local_repositories_test.dart` 与现有 Dashboard/Plan 测试。

**保留的行为。** Plan 日历视图与 Dashboard 今日计划读数一致；loading/empty/error/retry 完整。

**验证。** `dart format`、scoped `flutter analyze`、受影响测试全绿；冒烟确认两处数据一致。

### F9 - 计划中

**范围。** 在 AI 专家中心支持"单专家 + 文件上下文"：上传、命名、复用、移除本地文件；选择单专家时把文件以引用形式入参发起 Run。文件内容由后端读取与持久化，前端只传引用 ID。

**前置条件。** 后端需在 `frontend-api-integration.md` 暴露：
- `POST /expert-files`（multipart 或预签名 URL，详见后端文档），返回稳定 `fileId`；
- `GET /expert-files`、`DELETE /expert-files/{id}`；
- 既有 `POST /expert-runs` 在 `inputJson` 中支持 `fileRefs: [{id, role}]` 字段。

合约未发布则阻塞。

**改动文件（外科手术式）。**

- 新增 `lib/features/expert/expert_file_repository.dart` 与 `lib/features/expert/http_expert_file_repository.dart`，对齐现有仓库模式。
- 在 `lib/features/expert/dto.dart` 增 `ExpertFileDto`（仅含展示字段：`id / name / sizeText / role / updatedAt`），不携带二进制或路径。
- 在 `lib/pages/expert_workbench_page.dart`（或 AI 入口的对应子页面）新增"我的文件"区块：上传/列表/重命名/删除/绑定到当前专家；切换专家时保留已上传文件但允许重新选择绑定。
- 调整 Run 发起逻辑：把 `fileRefs` 写入 `inputJson`，文件二进制一律经后端。
- 新增 `test/expert/expert_file_repository_test.dart` 与对应 Widget 测试。

**保留的行为。** 既有 Run 时间线、确认、幂等键保持不变；不上传二进制；不展示原始文件内容；删除文件需要二次确认。

**验证。** `dart format`、scoped `flutter analyze`、新测试与既有 Run/确认测试全绿；冒烟：上传文件→选专家→发起 Run→Run 详情显示"已绑定 N 个文件"。

### F10 - 计划中

**范围。** 在 AI 中心支持勾选多个专家以"专家团"方式启动一次 Run；Run 详情、时间线、确认流遵循既有 Run 规范，仅在元数据上区分"单/团"。

**前置条件。** 后端需在 `frontend-api-integration.md` 暴露：既有 `POST /expert-runs` 接受 `expertIds: [...]`（团队模式）扩展；`GET /experts/{id}` 或 `GET /expert-runs/{id}` 返回 `mode: single | team` 与参与专家摘要。合约未发布则阻塞。

**改动文件（外科手术式）。**

- 调整 `lib/features/expert/dto.dart`：扩展 `ExpertRunDto` 与 `ExpertRunSourceType`，按后端字段增加 `mode` 枚举映射。
- 调整 `lib/features/expert/http_expert_run_repository.dart` 的 `start` 入参：按 `mode` 拼装 `expertIds` 或 `expertId`。
- 在 `lib/pages/expert_workbench_page.dart` 顶部新增"单 / 团"切换：单模式走 F9 的单专家+文件，团模式提供多选列表与"以团队方式启动"按钮。
- Run 详情页对团队模式渲染"参与专家"小卡，不展示内部协调细节；确认按钮单次提交。
- 新增 `test/expert/expert_team_run_test.dart` 与 Widget 测试。

**保留的行为。** 既有 Run 轮询、终止、确认、错误展示不变；`mode` 仅是元数据，UI 不得借机渲染模型思考链或团队内部 Prompt。

**验证。** `dart format`、scoped `flutter analyze`、新测试与既有 Run 测试全绿；冒烟：勾选 2+ 专家→团队 Run→Run 详情显示参与专家列表与单/团徽标。

### F11 - 计划中

**范围。** 把前端"直连第三方"的入口全部收回，统一经过自有后端 API。包括：

- AI 调用：原先前端直连 AI 提供方 + 持有 API Key 的模式，全部改走 `POST /ai/chat`、`POST /ai/stream` 等后端代理端点；前端不再持有 AI Key、不再向第三方域名发起请求。
- 第三方 Connector：Home Assistant、天气、日历等所有外部服务接入，全部经后端封装，前端不持有第三方凭据、不直接打第三方 Endpoint。
- 后端职责：负责问题脱敏、指令校验、限流、凭据托管，并把"对设备/第三方的副作用"标准化为可展示的状态。

**前置条件。** `frontend-api-integration.md` 暴露全部"代理端点"的字段级合约；既有第三方直连代码在客户端下架。

**改动文件（外科手术式）。**

- 新增 `lib/features/ai/http_ai_repository.dart`（如尚未存在），覆盖聊天、流式输出、建议召回；删除任何 `dart_openai` / `openai` / `langchain` 直连。
- 新增 `lib/features/connector/http_connector_repository.dart`；移除任何 `homeassistant` / `mqtt` / `weather_provider` 直连。
- `lib/core/env/env_config.dart` 仅保留自家后端 `baseUrl`；移除任何第三方 endpoint 字段。
- `lib/core/storage/token_storage.dart` 不再承载第三方凭据；第三方凭据仅由后端持有。
- `pubspec.yaml` 移除客户端侧第三方 SDK 依赖（仅当该 SDK 在客户端无其他用途时）。
- `test/` 配套新增/调整：AI 与 Connector HTTP 仓库测试，并对"客户端无第三方 endpoint"做静态断言（`grep` 关键依赖名）。

**保留的行为。** UI 不变：AI 聊天与建议、Connector 中心的健康/授权/发现/断连/重试全部与 F3/F2 行为对齐；Dio 失败、超时、401/refresh 路径不变。

**验证。**

- `dart format`、`flutter analyze` 零新增诊断。
- 全量 `flutter test --no-pub` 通过。
- 静态扫描：`pubspec.yaml` 不再含第三方 AI/Connector 直连 SDK；客户端代码 grep 不到第三方域名与 Key。
- 冒烟：前端不直连任何第三方；所有 AI/Connector 流量经自家后端；后端返回的脱敏结果与原 UI 一致。

## 5. 同步与门禁

- 任何产品范围、IA、数据边界、跨端流程的修改，先改产品总纲，再同步本文与受影响的源文档。
- UI token/组件规则变化需同步 `docs/UI_STYLE_GUIDE.md` 与 `lib/core/ui/nexus_theme.dart`。
- 工程架构变化需同步 `docs/DEVELOPMENT_GUIDELINES.md`。
- 每个迭代交付前必须通过：`dart format`、受影响文件 `flutter analyze`、相关 `flutter test`。
- 新增 Repository 需有映射/错误测试；关键页面/流程需有 Widget 测试。
