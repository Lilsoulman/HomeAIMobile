# NexusMind Flutter 前端开发设计

> **对应产品总纲：** `D:\HomeMind\core\docs\main\NexusMind-Product-Master-Design.md`  
> **前端代码：** `D:\HomeMind\mobile\lib`  
> **生效顺序：** 本文定义 NexusMind 的页面与产品实施；[开发规范](../DEVELOPMENT_GUIDELINES.md) 定义工程规则；[UI 样式规范](../UI_STYLE_GUIDE.md) 定义视觉规则。发生冲突时，先更新总纲和相关规范，再实施代码。

## 1. 技术基线与代码位置

移动端使用 Flutter Material 3、Dart、Provider、GoRouter 和 Dio。不得新引入竞争性的状态管理、路由、网络或持久化框架。

| 位置 | 用途 |
| --- | --- |
| `lib/main.dart` | 应用组合、`MultiProvider`、主题与根组件 |
| `lib/router.dart` | 唯一路由定义与五 Tab Shell |
| `lib/core/` | API 客户端、配置、存储、共享 UI 等基础设施 |
| `lib/core/ui/nexus_theme.dart` | 主题、语义色、20px 内容容器、排版、按钮、输入框、浅深色模式 |
| `lib/features/<feature>/` | Repository 抽象、DTO、HTTP/本地实现 |
| `lib/pages/` | 页面和页面级交互状态 |
| `lib/pages/dashboard_page.dart` | AI 优先的 Dashboard 实现入口 |

页面只依赖 Repository 接口和 DTO；网络、鉴权、存储细节由 Repository 与 `core` 承担。新增跨页依赖在 `main.dart` 的 `MultiProvider` 注入；页面不能自行创建客户端、Repository 或偏好设置。

## 2. 设计定位与系统规范

NexusMind 不是设备控制面板，而是“懂家的 AI 管家”。UI 始终表达：**AI 理解生活目标 → 给出依据与建议 → 用户确认 → 系统执行并反馈结果**。

视觉关键词是 Calm、Intelligent、Human、Trust、Premium。默认深色 Nexus Dark Glass，但必须支持浅色模式和 320~430px 宽度。准确 token、响应式与组件规则以 [UI 样式规范](../UI_STYLE_GUIDE.md) 为准；代码唯一来源为 [nexus_theme.dart](../../lib/core/ui/nexus_theme.dart)。

实施要点：

- 页面背景、卡片、文字、AI 行动、健康状态均使用 `Theme.of(context)` 与 `NexusPalette` 的语义色；
- 默认可滚动页面使用 20px 横向、24px 纵向内容边距；主要区块间距 24px，相关控件间距 12px；
- 采用 28/18/15/13 的四级文字层次，中文优先 PingFang SC 系统回退；
- `NexusSurface` 是标准卡片（20px 圆角）；按钮、Chip、输入框为 12px 圆角；
- 一个页面最多一个视觉主行动；AI 主行动使用 AI Accent，确认完成使用健康色；
- 所有功能都要有 loading、empty、error、无权限、断连与成功/失败状态；不得硬编码白、黑或任意灰色。

## 3. 信息架构与路由

底部导航固定五项，不再以 Todo、Calendar 作为一级 Tab：

```text
Home（首页）  → 今日状态与 AI 主行动
AI（专家）    → 专家选择、分析与运行结果
Plan（计划）  → Todo + Calendar + AI 行动
Home+（家庭） → 家庭空间、设备摘要与场景
Me（我的）    → 账号、家庭成员、连接与设置
```

所有路由只在 `lib/router.dart` 声明：切换 Tab 使用 `go`，可返回的详情、创建和确认流程使用 `push`。原 Todo/Calendar 能力保留在 Plan 页面或其可返回的子路由中，不能因导航重构丢失。

## 4. 页面实现规范

### Home Dashboard

实现文件为 [dashboard_page.dart](../../lib/pages/dashboard_page.dart)。页面结构固定为：

```text
SafeArea
  ├─ Header：问候、日期、家庭一句话状态、通知
  ├─ AI 主行动：今日建议（执行 / 忽略 / 进入 Expert）
  ├─ Family Status：安全、客厅温度、卧室湿度、老人房状态
  ├─ Today Plan：Todo 与日程摘要
  ├─ Smart Scene：回家、离家、睡眠、观影横向滚动卡片
  └─ AI Suggestion：必要时展示更多可行动建议
```

AI 建议使用 `NexusAICard` 语义，不显示聊天记录。卡片必须写清检测依据、建议、影响范围和操作；可以有约 2 秒的轻微呼吸效果，但不可用装饰性渐变替代信息层级。快捷场景采用水平 `ListView`，卡片约 120 × 100，窄屏不挤压。

### AI Expert 与 AgentRun

专家页是“专家中心”，不是通用聊天。展示推荐专家、能力、输入、需要权限、预计耗时以及最近 AgentRun 记录。首个核心专家为家庭管家；周计划、长辈助手和睡眠专家可按能力目录呈现。Expert 只定义角色、Prompt、允许 Skill 和权限，不直接执行外部动作。

运行页采用可理解的时间线：分析上下文、生成方案、等待确认和返回结果。**不得展示模型内部思考过程、Prompt 或原始日志。** `AgentRun` 仅使用 `draft`、`queued`、`planning`、`running`、`completed`、`failed`、`cancelled` 七种状态；`RunEvent` 按 sequence 提供时间线，`RunAction` 表达“等待确认 / 执行中 / 成功 / 失败”。提交确认后要阻止重复点击，并在离开页面后仍能从运行记录恢复结果。

### Plan

Plan 合并 Todo 与 Calendar，顶部使用“任务 | 日历”分段控件。当天视图以完成进度、上午/下午/晚上安排和 AI 生成行动组织。设备写入、自动化创建等行动必须显示影响空间/设备、是否需要确认、结果和可安全重试入口。

### Home+

Home+ 以空间优先：客厅、卧室、老人房、厨房。空间卡只显示重要的自然语言状态，例如温度、灯光、空调、睡眠模式或安全状态。进入空间后才显示设备与自动化；不得在默认 UI 露出 Connector、协议、设备实体 ID 或供应商字段。页面只消费标准化 `SmartDevice`、`DeviceCapability`、`DeviceState` 与 `Scene`，因此同一 UI 能支持 Home Assistant、Zigbee/MQTT 和未来的米家/涂鸦 Adapter。

### Me 与连接中心

Connector 页面置于“我的 → 连接”或家庭设置。显示 Home Assistant、天气、日历等连接的在线、授权中、断连、失败和发现状态；凭据永远不可显示或记录在日志中。

## 5. Flutter 状态、数据与交互流程

```text
Page / Widget
  → Provider / 页面局部状态
  → Repository interface
  → HTTP / Local Repository
  → ApiClient
  → .NET /api/v1
  → DTO → UI state（loading / empty / error / success）
```

新的功能必须先定义 Repository 接口，再提供 HTTP 或本地实现。HTTP 响应经明确 parser 映射 DTO，保持服务端字段大小写；不把 JSON、设备供应商模型或 API 调用直接放入 Widget。异步初始加载在 `initState` 中启动，每次 `await` 后更新 UI 前检查 `mounted`，命令执行期间禁止重复提交。

V1 建议按领域提供：`SmartHomeRepository`（空间、设备摘要、能力、状态、场景）、`ConnectorRepository`（Provider 目录、连接健康、授权、测试、发现与 Tool 可用性）、`ExpertRepository`（目录、策略摘要与详情）、`AgentRunRepository`（创建、详情、事件、行动、取消、重试和轮询）、`SkillRepository`（展示 Skill 策略）以及复用现有 Todo/Calendar Repository。领域 DTO 至少覆盖 `Expert`、`AgentRun`、`RunEvent`、`RunAction`、`Connector`、`SmartDevice`、`DeviceCapability` 与 `Scene`；页面不得解析供应商原始字段，也不能直接调用 API。

## 6. 前后端接口协作

后端详细设计在 `D:\HomeMind\core\docs\main\NexusMind-Backend-Development.md`，逐接口契约在 `D:\HomeMind\core\docs\frontend-api-integration.md`。前端不得根据 UI 自行猜测协议字段；后端不得把原始设备数据或模型日志交给页面解释。

| 用户流程 | Flutter 行为 | 后端契约 |
| --- | --- | --- |
| 打开 Dashboard | 并行加载，局部失败卡片可重试 | 返回今日建议、计划、家庭摘要、场景及更新时间 |
| 开始家庭管家分析 | 创建 Run，显示 queued/running 时间线 | 返回 Run ID、状态及可展示阶段 |
| 查看 Run | 短轮询直至完成或用户离开 | 返回 `status`、有序 `events`、`actions`、`updatedAt`、安全错误信息 |
| 确认行动 | 禁止重复点击，展示执行中与结果 | 校验权限/版本/幂等键，重复请求返回既有结果 |
| 浏览 Home+ | 空间优先显示，并表达数据新鲜度 | 标准化空间、设备摘要、场景，无供应商字段 |
| 管理 Connector | 展示健康/授权/发现状态与恢复入口 | 凭据脱敏，状态可直接映射 UI |

V1 使用短轮询刷新 `AgentRun`。推送能力可后续加入，但页面必须在重新进入时通过 Run 查询恢复状态。

## 7. 实施顺序与验收

| 顺序 | 交付 | 验收 |
| --- | --- | --- |
| 1 | 五 Tab Shell 与路由 | 所有一级入口可达，Todo/Calendar 不丢失 |
| 2 | Dashboard AI 优先结构 | Header、AI 主行动、计划、家庭状态、场景完整且有全状态 UI |
| 3 | Expert 中心与 Run 时间线 | 用户能理解依据、权限、影响和确认，不泄露思考链 |
| 4 | Plan | Todo、日历和 AI 行动可查看、确认和回溯 |
| 5 | Home+ | 按空间展示摘要、场景和设备第二层详情 |
| 6 | Connector 中心 | 正确呈现在线、授权、发现、断连和恢复状态 |

### 产品路线图对齐

第 1 月先完成 AI 优先 Dashboard、AgentRun 闭环、Todo/Calendar 复用和 SmartHome Mock；第 2–3 月以 Home Assistant 作为首个 SmartHome Connector Adapter，交付家庭空间、设备摘要与回家/离家/睡眠场景；第 4–6 月完善个人与家庭的连接服务体验；第 7–9 月支持 Family Context 驱动的建议和已授权自动化；第 10–12 月为订阅与 NexusMind Hub 试点增加角色化、租户化配置页面。所有阶段均维持“建议依据 → 影响范围 → 用户确认 → 可追溯结果”的交互原则。

每次交付必须遵循 [开发规范](../DEVELOPMENT_GUIDELINES.md) 的质量门禁：`dart format`、`flutter analyze` 与相关 `flutter test`。新增 Repository 需有映射/错误测试；关键页面或流程需有 Widget 测试。

## 8. 文档同步规则

## 8A. Agent Runtime 前端对接基线（2026-08-04）

NexusMind 的前端定位同步为 Personal AI Operating System：家庭是首个场景，
SmartHome 是 Connector，不是应用的产品边界。所有新的 AI 交互均通过
`AgentRunRepository` 创建和查询 `AgentRun`；服务端兼容路由仍为
`/api/v1/expert-runs`，页面和 DTO 不再使用 `ExpertRun` 作为领域名称。

```text
Widget
  -> Provider / page state
  -> AgentRunRepository / ExpertRepository / ConnectorRepository
  -> ApiClient
  -> /api/v1
```

Widget 不得直接调用 Dio、ApiClient 或任何设备/供应商 API。保留现有
`TodoRepository`、`CalendarRepository` 和 Expert Mock；新增能力按下列职责
组织，不将 Connector 协议模型泄漏到页面：

| Repository | 页面职责 |
| --- | --- |
| `ExpertRepository` | 展示 Expert 的角色、能力、允许 Skill 和所需权限 |
| `AgentRunRepository` | 创建、查询、轮询、取消、重试和展示 RunEvent / RunAction |
| `SkillRepository` | 展示可用 Skill 与执行策略；不直接执行外部动作 |
| `ConnectorRepository` | 展示连接健康、授权状态、可用 Tool 和恢复入口 |
| `SmartHomeRepository` | 消费标准化空间、设备、能力和场景 DTO；第一阶段仅 Mock |

AgentRun 状态只允许：`draft`、`queued`、`planning`、`running`、`completed`、
`failed`、`cancelled`。UI 映射为：draft/queued 显示“准备中”，planning/running
显示“处理中”，completed 显示结果，failed 显示可读错误和重试，cancelled 显示
已取消。不要再依赖 `synthesizing` 或 `needs_input`。轮询在终态停止；离开页面后
可通过 Run ID 恢复。

Expert 只提供角色、Prompt、允许 Skill 和权限。RunAction 代表受控建议或待执行
动作，页面必须展示影响范围、权限和是否需要确认，并阻止重复提交。Skill 才是执行
边界，Connector 是外部系统唯一入口。Home Assistant、MQTT、Zigbee、Matter 以及
设备厂商协议都不出现在 Flutter 页面或 Repository 契约中。

Connector 中心展示状态、`authStatus`、成员权限和 Tool 可用性，绝不展示
credential、token、原始设备实体 ID 或协议字段。Home Assistant 将在第二阶段作为
SmartHome Connector Adapter 接入；当前仅对接 Mock/标准化 DTO。

产品范围、信息架构、数据边界或跨端流程变化时，先修改产品总纲，再在同一变更中更新本文和受影响的后端文档。UI token/组件规则变化还需同步 [UI 样式规范](../UI_STYLE_GUIDE.md) 与 `lib/core/ui/nexus_theme.dart`；工程架构变化还需同步 [开发规范](../DEVELOPMENT_GUIDELINES.md)。
