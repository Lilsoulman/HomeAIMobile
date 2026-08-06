# NexusMind 前端开发计划

> **产品依据：** `D:\HomeMind\core\docs\main\NexusMind-Product-Master-Design.md`
> **前端设计依据：** [NexusMind-Frontend-Development.md](NexusMind-Frontend-Development.md)
> **计划性质：** 当前实施快照。只维护已完成和下一步，不保留迭代历史，也不改变产品或接口契约。

最近同步：2026-08-06
当前目标：完成既有单专家文件上下文的测试收尾，同时在服务端 V2.2（B9-B14）与 V2.3 个人生活专家（B15-B17）契约已发布的前提下，依次交付家庭协同数据层、管家工作台、设置、能力/家庭状态，以及个人生活专家（收藏管理、探店翻牌、行程规划与日历同步）。

## 1. 不变基线

- Flutter Material 3、Dart、Provider、GoRouter、Dio，复用既有 `ApiClient`、安全存储和 `useLocalData` 装配；
- 页面只依赖 Repository 与 DTO；HTTP 仅通过 `ApiClient` 和显式 DTO parser；
- 底部五项统一为“管家 / 能力 / 待办 / 家庭 / 设置”；
- 客户端不得持有第三方 Key 或直连第三方 Endpoint；设备写入、场景执行和自动化创建必须经过确认与幂等保护；
- 创作者中心本地 MCP Bridge 只供 Codex/本机 Agent 使用：Flutter 不配置 stdio MCP、不读取其 SQLite、不保存同步令牌或敏感开关，也不将其同步状态作为 App 数据源；
- V2.4 个人 Connector 仅在 B18 OAuth/Scope API 发布后实现；家庭级配置与成员授权属于 Web 开发端，移动端只消费状态与本人授权/撤销能力；
- 所有异步界面具备 loading、empty、error、retry；发布前执行 `dart format`、`flutter analyze` 和相关 `flutter test`。

## 2. 已完成

| 能力 | 完成状态 | 最小验证结果 |
| --- | --- | --- |
| 应用壳、主题与五 Tab 路由基础 | 已完成 | Material 3 + Nexus 主题；Todo/Calendar 保留为 Plan 子能力 |
| Dashboard、Plan、Home+ 和 Connector 基础体验 | 已完成 | 标准化数据、局部 loading/error/empty/retry、场景可见确认和 Connector 健康/授权/发现状态 |
| AgentRun/Expert Run 闭环 | 已完成 | 七态 UI、可公开事件时间线、Action 确认、取消/重试、终态停轮询与新幂等键 |
| SmartHome、Todo、Calendar HTTP Repository | 已完成 | 通过 `ApiClient` 消费已发布契约，DTO 显式映射并有仓库测试 |
| 安全展示基线 | 已完成 | 页面不渲染 Prompt、思考过程、原始事件、供应商字段、凭据或设备实体 ID |

## 3. 下一步

| 优先级 | 交付 | 前置条件 | 最小验收 |
| --- | --- | --- | --- |
| P0 | 单专家文件上下文测试收尾 | 无新增产品或 API 依赖；修复现有 Widget 测试视口/滚动可点击性 | 上传、选择、移除、删除、发起 Run 闭环；`fileRefs` 仅传 `{id, role}`；相关仓库和 Widget 测试全绿 |
| P1 | 客户端后端代理审计与收口 | 以已发布 `/api/v1` AI、Connector、附件契约为准 | 客户端无第三方 Key、Endpoint 或 SDK 直连；AI 与 Connector 均经 `ApiClient`；静态扫描和相关 HTTP Repository 测试通过 |
| P2 | 家庭协同数据层 | 服务端 V2.2 B9-B14 字段级契约已发布 | `Family`、`Confirmation`、`Steward`、`Dashboard` 的 DTO/Repository 抽象、HTTP 实现和映射/错误/风险限制测试完成；不猜测 HTTP 字段 |
| P3 | 管家工作台与确认中心 | P2 的 Repository 可用；批量确认 API 明确原子校验和幂等语义 | Dashboard 为“待确认 → 动态 → 家庭概览 → 快捷入口”；Plan 为“待确认/任务/日历”；L1 批量确认、L2/L3 逐项确认、重入恢复和局部失败用例通过 |
| P4 | 家庭设置 | Family API 字段级契约已发布（B11）；成员和知识权限规则可消费 | `settings_page.dart`、成员和知识库页面及路由完成；成员生命周期、知识写入权限/冲突、CRUD、删除确认、无权限和重试可用 |
| P5 | 能力托管、家庭状态与风险组件 | Steward、Expert 托管和设备健康字段可消费 | 能力中心的托管/风险说明、家庭离线/低电量/弱信号、动态入口、`ConfirmationCard`/`RiskBadge`/`StewardTimelineTile` 和主题语义完成 |
| P5b | 个人偏好收藏管理 | 服务端 V2.3 B15 收藏契约已发布（`life.favorite.read/write`） | `FavoriteDto`/`FavoriteRepository`、`favorites_page.dart`（分类列表/新建/编辑/软删除/导入）；`private` 仅本人可见、无权限/空/错误/重试状态可用 |
| P5c | 个人生活专家：翻牌与行程 | 服务端 V2.3 B16/B17 契约已发布（`POST /api/v1/experts/personal-life-expert/runs` 与行程确认） | `life` 分类能力详情、翻牌页（时间/位置/口味 → 建议卡）、行程页（目的地/天数 → 每日安排 + `calendar_create_event` L1 确认与幂等提交、确认后日历同步提示）；不渲染提示或思考链 |
| P6 | 质量与 API 联调 | P2--P5c 完成且服务端接口已发布 | 新增页面 Widget 测试、HTTP 映射/错误测试和回归测试全绿；`dart format lib/ test/`、`flutter analyze lib/`、`flutter test --no-pub` 通过 |
| P7 | MCP 边界静态审计 | 无 API 或产品能力前置依赖 | 确认 `lib/`、移动端配置和日志中不存在 MCP stdio/SQLite 客户端、`NEXUSMIND_ACCESS_TOKEN` 或 `NEXUSMIND_MCP_ALLOW_SENSITIVE`；不为本地 Agent 缓存创建页面、路由或 Repository。 |
| P8 | V2.4 我的连接 | B18/B19 字段、OAuth 状态与撤销契约发布 | 家庭/个人 scope 状态、个人授权发起/完成/过期/撤销、跨成员不泄露、无 Token 落端测试通过；不提供家庭级密钥或成员授权配置。 |

## 4. 范围与门禁

- 专家团协作不在当前产品范围；除非产品总设计先新增并记录该决策，计划不创建对应前端任务。
- 服务端字段级契约未发布时，不新增猜测性的 HTTP 实现；本地 Repository 与受控 UI 状态可先行。
- P3--P5 的所有写操作均须展示影响范围、权限、风险和确认要求，提交中禁止重复操作并使用新的幂等键。
- Creator MCP 的同步与敏感数据策略仅由 `D:\HomeMind\core\docs\mcp-creator-center.md` 和后端设计约束；任何需要在 App 中呈现的创作者能力，先发布字段级 `/api/v1` 契约，再纳入本计划。
- 任一交付改变 UI Token/组件时，同步 `docs/UI_STYLE_GUIDE.md` 与 `lib/core/ui/nexus_theme.dart`；改变工程架构时同步 `docs/DEVELOPMENT_GUIDELINES.md`。
- 完成状态只在满足本计划的最小验收后回写；已过时的下一步应被替换，不追加历史记录。
