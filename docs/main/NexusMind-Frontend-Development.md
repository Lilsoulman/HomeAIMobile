# NexusMind Flutter 前端开发设计

> **产品依据：** `D:\HomeMind\core\docs\main\NexusMind-Product-Master-Design.md`
> **适用代码：** `D:\HomeMind\mobile\lib`
> **当前基线：** V2.3。本文只承接已确认的页面、交互、接口消费和验收；产品范围以产品总设计为准。

## 1. 技术与职责边界

移动端使用 Flutter Material 3、Dart、Provider、GoRouter 和 Dio。不得引入竞争性的状态管理、路由、网络或持久化框架。

| 位置 | 职责 |
| --- | --- |
| `lib/main.dart` | 应用组合、`MultiProvider`、主题和本地/HTTP Repository 装配 |
| `lib/router.dart` | 唯一的路由定义和五 Tab Shell |
| `lib/core/` | `ApiClient`、环境配置、安全存储和共享 UI |
| `lib/core/ui/nexus_theme.dart` | 主题、语义色、布局、排版、浅深色模式 |
| `lib/features/<feature>/` | Repository 抽象、DTO、本地和 HTTP 实现 |
| `lib/pages/` | 页面和页面局部交互状态 |

页面只依赖 Repository 抽象和 DTO。网络、鉴权和存储细节由 `core` 与 Repository 承担；跨页依赖通过 `main.dart` 的 `MultiProvider` 注入。Widget 不得创建 Dio、`ApiClient`、Repository 或偏好设置，不得解析 JSON、厂商协议或第三方响应。

所有外部服务均经自有 `/api/v1` 后端访问。客户端不得持有或记录第三方 Key、Token、凭据或 Endpoint，也不得直连 AI、Home Assistant、天气、日历或其他供应商。

创作者中心本地 MCP Bridge（`HomeMind.CreatorMcp`）只服务受控本机的 Codex/Agent：它的 stdio transport、本地 SQLite 缓存、同步令牌和 `NEXUSMIND_MCP_ALLOW_SENSITIVE` 开关均不属于移动端。Flutter 不配置、不调用、不展示该 Bridge，也不读取其 SQLite；创作者中心相关的 App 数据如未来需要呈现，仍必须由已发布、自有 `/api/v1` 契约提供，并沿用当前 DTO、权限和脱敏规则。

## 2. 体验与设计系统

NexusMind 是“AI 与你一起管理家庭”的管家工作台，不是设备控制面板或通用聊天窗口。页面始终让用户理解：**发生了什么、依据是什么、影响谁和什么、是否需要确认、结果如何追溯**。页面优先级为“上下文 → 状态 → 一个主行动”。

视觉和组件规则以 [UI 样式规范](../UI_STYLE_GUIDE.md) 与 [nexus_theme.dart](../../lib/core/ui/nexus_theme.dart) 为唯一来源：

- 使用 `Theme.of(context)`、`NexusLayout`、`NexusSurface` 和语义色，不硬编码白、黑、灰或新的视觉 Token；
- 默认页面横向 20px、纵向 24px，主要区块 24px，关联控件 12px；`NexusSurface` 为 20px 圆角，控件为 12px 圆角；
- 排版采用 28/18/15/13 层级，中文优先 PingFang SC 回退；支持浅深色和 320--430px 宽度；
- 一个页面最多一个主行动。风险、异常、加载、空、无权限、断连、成功、失败和可撤销状态都必须同时具有文字、颜色和语义标签，不能只依赖颜色；
- UI 不显示 Prompt、模型思考过程、原始事件载荷、供应商字段、协议字段、设备实体 ID、密码、Token 或完整 API 响应。

## 3. 信息架构与路由

底部导航固定为五项；仅文案和页面语义变更，既有 Todo、Calendar、Connector 和 Run 历史能力必须保留。

| Tab | 页面定位 | 首要内容 |
| --- | --- | --- |
| 管家 | 家庭协同工作台 | 待确认事项、管家动态、家庭概览、快捷入口 |
| 能力 | 可解释的管家能力中心 | 已托管能力、可托管目录、托管开关、风险说明 |
| 待办 | 待办与日程 | 待确认、任务、日历，按风险分组 |
| 家庭 | 空间与设备健康 | 空间摘要、离线/低电量/弱信号异常、动态入口 |
| 设置 | 家庭设置 | 成员、家庭知识、管家偏好、连接管理 |

所有路由仅在 `lib/router.dart` 声明。切换 Tab 使用 `go`；详情、新建、编辑、确认、拒绝和撤销流程使用 `push`。目标页面包括：

- `dashboard_page.dart`：管家工作台；
- `expert_workbench_page.dart`：能力中心，既有 Run 历史作为动态详情来源；V2.3 起专家目录按 `planning`/`review`/`life` 分类组织，`life` 分类含个人生活专家详情；
- `plan_page.dart`：待确认、任务、日历；
- `home_plus_page.dart`：家庭空间与设备健康；
- `settings_page.dart`：家庭成员、知识、偏好和 Connector；
- `confirmation_center_page.dart`、`family_members_page.dart`、`family_knowledge_page.dart`、`steward_timeline_page.dart`：可返回的二级页面；
- `favorites_page.dart`（个人偏好收藏管理）、`life_recommend_page.dart`（探店翻牌）、`life_trip_page.dart`（行程规划与日历同步确认）：V2.3 个人生活专家二级页面。

## 4. 页面与交互要求

### 管家工作台

`dashboard_page.dart` 固定按照 `Header → 待确认事项 → 管家动态 → 家庭概览 → 快捷入口` 组织。待确认事项始终优先，其他区域失败不得遮蔽仍可操作的确认卡。Header 可展示问候、日期、天气和通知入口；通知不是设备事件日志。

`DashboardRepository` 消费 `DashboardDto` 的 `pendingConfirmations`、`stewardActivities`、`homeSummary` 和 `quickActions`。支持独立 loading、empty、error、retry 和新鲜度状态；首次加载在 `initState` 发起。

### 能力与运行记录

`expert_workbench_page.dart` 是能力中心，不是通用聊天窗口。它展示能力可读取或执行的范围、托管状态、风险说明和权限摘要；用户可进入运行记录了解已发生的管家动态。既有专家、文件上下文和单次 Run 能力作为详情流程保留，不能成为首页主心智。

运行详情仅展示可公开的阶段、影响范围、权限和结果。`AgentRun` UI 只使用 `draft`、`queued`、`planning`、`running`、`completed`、`failed`、`cancelled`；`RunEvent` 按 `sequence` 显示。终态或页面释放时停止轮询，重新进入按 Run ID 恢复结果。不得显示内部推理、Prompt 或原始日志。

### 确认中心与待办

`plan_page.dart` 顶部为“待确认 / 任务 / 日历”。`confirmation_center_page.dart` 按风险和状态组织待确认事项，卡片展示标题、描述、影响范围、建议操作、状态、创建/过期时间和风险等级。

| 风险 | 界面表达 | 操作约束 |
| --- | --- | --- |
| L1 | 已自动处理或低风险确认 | 只有未过期的 L1 `pending` 项可批量确认 |
| L2 | 建议确认 | 必须逐项确认或拒绝 |
| L3 | 需要你决定 | 必须逐项决定，不得自动或批量执行 |

风险最终值取 Tool 静态基线、家庭成员偏好和运行时上下文三者中的最高等级。确认、拒绝、批量确认和撤销均须展示影响范围、权限和确认要求；每次提交生成新的幂等键，提交中禁用按钮，重复请求显示既有结果。L1 批量确认只能向同一家庭提交，并由服务端原子校验全部项目；前端不得尝试批量 L2/L3。

### 家庭

`home_plus_page.dart` 按空间显示自然语言摘要、场景和设备健康。空间卡可标示离线、低电量、弱信号和健康退化；进入空间后再显示设备与自动化详情，并提供该空间的管家动态入口。页面只消费标准化空间、设备、能力、状态和场景 DTO，不展示实体 ID、协议或供应商字段。

设备健康的可见模型为 `zigbeeRole`、`batteryLevel`、`signalLQI`、`healthStatus`；采样时间必须明确，过期状态不得描述为实时。写设备、运行场景和创建自动化都必须走受控 Action 与确认路径。

### 设置与家庭知识

`settings_page.dart` 提供成员、家庭知识、管家偏好和 Connector 管理入口。成员页面覆盖列表、新建、编辑和生命周期状态；终态成员的更正只能由具备权限的用户进入受控流程。知识库支持查看、搜索、分类、新建、编辑和删除，破坏性操作必须二次确认。

家庭知识默认由 `active` 成员写入；`security` 分类仅允许家庭管理员写入。AI 提取的知识必须标识系统来源和待确认置信度，前端展示冲突和解决结果而不静默覆盖。所有写入、无权限、空、错误和重试状态均需可见。

### 个人生活专家（V2.3）

`life` 分类（个人生活专家）不新增底部导航 Tab，五 Tab 信息架构保持不变。能力中心该分类下展示专家详情（翻牌与行程两个子能力，均可解释、可追溯）：

- **探店翻牌**（`life_recommend_page.dart`）：输入时间（可选时段）、位置（可选）、口味（可选）后发起 `intent=recommend` 运行；结果以建议卡展示 Top1-2 店铺（名称、理由、命中标签）。翻牌为只读 L1，不产生确认动作；无匹配时展示"来自私藏店铺库"的兜底建议。
- **行程规划**（`life_trip_page.dart`）：输入目的地（必填）与天数（1-7）后发起 `intent=plan` 运行；结果按天展示每日安排（上午/下午/晚上、天气、引用收藏与理由），并呈现 1 个 `calendar_create_event` 动作（L1）。确认前必须展示影响范围（N 天 → N 个日历事件）与确认要求；确认提交使用新的幂等键，提交中禁用按钮，重复请求展示既有结果；确认后跳转/提示日历已同步。
- **收藏管理**（`favorites_page.dart`）：`restaurant`/`travel`/`material` 分类的列表、新建、编辑、软删除与对话导入。`private` 收藏仅归属成员本人可见，不得展示给家庭其他成员；破坏性删除必须二次确认。写操作权限不足时展示无权限状态。

所有页面只消费 `FavoriteDto`、`LifeExpertRun` 建议/动作 DTO，不渲染提示、思考链、凭据或供应商字段。

### Connector 与通知

Connector 位于“设置 → 连接管理”。只展示健康、授权、发现、成员权限和 Tool 可用性，不展示凭据。`status` 与 `authStatus` 分别表达健康和授权生命周期，不能混用。

V2.4 将 Connector 分为 `household` 与 `personal`：家庭级实例由 owner/admin 在 Web 开发端配置，移动端仅显示已授权状态；个人级实例仅显示给绑定成员，并允许该成员发起授权、查看脱敏状态和撤销。个人 OAuth 的 callback、Token 和刷新不进入 Flutter。接口发布前，不实现猜测性的个人连接 HTTP Repository；现有 `tenant_members` 固定角色为 owner/admin/member/viewer，移动端按服务端权限显示页面和操作，不维护角色或路由。

通知只用于需要知情、确认或处置的事项。客户端按服务端聚合结果展示并支持静默/退订偏好：L3 独立、立即送达；L2 独立送达但可受成员静默偏好延迟；L1、场景和周期摘要可聚合。通知打开后必须落到已授权家庭中的对应确认项或动态，不能暴露跨家庭信息。

## 5. 数据、状态与接口协作

```text
Page / Widget
  → Provider / 页面局部状态
  → Repository interface
  → HTTP / Local Repository
  → ApiClient
  → /api/v1
  → DTO
  → loading / empty / error / success UI
```

先定义 Repository 接口，再实现本地或 HTTP 版本。字段级 API 契约发布前，只能补 DTO、接口、本地实现和受控 UI 状态，不得猜测 HTTP 字段；发布后 HTTP 必须经 `ApiClient` 和显式 DTO parser，并保留服务端大小写映射。

| 领域 | DTO 与 Repository 职责 |
| --- | --- |
| Family | `FamilyMemberDto`、`FamilyKnowledgeDto`、`DecisionHistoryDto`；成员、知识和决策的查询/写入/删除 |
| Confirmation | `ConfirmationItemDto`；查询、确认、拒绝和受限的 L1 批量确认 |
| Steward | `StewardActivityDto`；面向用户的感知、规划、执行、汇报动态及详情 |
| Dashboard | `DashboardDto`；聚合待确认、动态、家庭概览和快捷入口 |
| Expert / AgentRun | 专家目录、托管状态、运行、事件、Action、取消与重试 |
| Smart Home | 标准化空间、设备、能力、状态、场景和设备健康 |
| Connector | Provider、连接健康、授权、发现、成员权限和 Tool 可用性 |
| Favorites（V2.3） | `FavoriteDto`；`life.favorite.read/write` 下收藏的列表/详情/创建/更新/软删除/导入 |
| LifeExpert（V2.3） | `LifeExpertRunDto`（`Recommendations`/`Actions`）；`POST /api/v1/experts/personal-life-expert/runs` 的翻牌与行程运行、行程动作确认 |

`RunEvent` 是技术审计记录，`StewardActivity` 是面向用户的可聚合产品动态；前端不可将前者的内部载荷替代后者显示。页面局部交互使用 `StatefulWidget`，需要跨组件响应式刷新的状态使用 `ChangeNotifier`；`watch` 用于读取，`read` 用于命令。每次 `await` 后更新 UI 前检查 `mounted`，所有异步界面均支持 loading、empty、error、retry。

本地 MCP 缓存不是 `Local Repository` 的实现选项：它可能包含仅供受控 Agent 查询的创作者元数据，且同步时机由 Agent 显式决定。移动端不得将其数据、同步状态或敏感字段映射为 UI、日志或持久化状态。

## 6. 风险、安全与可访问性

- 高影响动作必须在执行前展示影响范围、权限和确认要求；确认后展示执行中、成功、失败和可安全重试状态。
- 前端不生成或传递家庭归属；服务端通过 JWT 家庭作用域隔离。页面从无权限/跨家庭响应中恢复到安全可读状态，不缓存或显示无权数据。
- `ConfirmationCard`、`RiskBadge`、`StewardTimelineTile` 与 `NexusSurface.warning/danger` 共同表达风险；L1/L2/L3 对应的文本、图标、颜色和语义标签必须一致。
- 用户可见事件只使用脱敏、可理解的摘要；日志与 Snackbar 也不得泄露服务端错误码之外的敏感原始内容。

## 7. 验收与质量门禁

每个新增 Repository 必须有 DTO 映射和错误测试；关键页面与流程必须有 Widget 测试。最低门禁为：

```text
dart format lib/ test/
flutter analyze lib/
flutter test --no-pub
```

V2.3 还必须验证：L1 批量确认限制、L2/L3 逐项确认、幂等与页面重入恢复、家庭知识权限与冲突呈现、设备异常语义、通知深链权限边界、Dashboard 局部失败不遮蔽待确认事项、个人生活专家（life 分类详情/翻牌建议卡/行程日历同步确认/收藏可见性与权限），以及静态扫描确认 Flutter 不包含 MCP stdio/SQLite 客户端、MCP 同步令牌或敏感开关。产品、信息架构、数据边界或跨端流程变更必须先更新产品总设计；UI Token 变化同步 UI 样式规范和主题实现，工程架构变化同步开发规范。

## 8. 文档联动

本文是产品总设计到前端实现的拆分层。开发计划只维护当前已完成和下一步，不能反向定义产品范围，也不得累计历史变更。当前 V2.3 同步覆盖：统一五 Tab 命名、三级风险确认、家庭知识写入权限、管家动态与技术审计的边界、通知优先级与聚合规则、Phase 1 的质量门槛、个人生活专家（探店翻牌、行程规划与日历同步、个人偏好收藏的可见性与权限）。
