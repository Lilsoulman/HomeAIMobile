# NexusMind 前端开发计划

> **产品依据：** `D:\HomeMind\core\docs\main\NexusMind-Product-Master-Design.md`
> **前端设计依据：** [NexusMind-Frontend-Development.md](NexusMind-Frontend-Development.md)
> **计划性质：** 当前实施快照。只维护已完成和下一步，不保留迭代历史，也不改变产品或接口契约。

最近同步：2026-08-07
当前目标：在服务端 V2.2（B9-B14）与 V2.3 个人生活专家（B15-B17）契约已发布的前提下，已交付家庭协同数据层、管家工作台、设置、能力/家庭状态、个人生活专家（收藏管理、探店翻牌、行程规划与日历同步）与 MCP 边界静态审计；待交付 V2.4 我的连接（依赖 B18/B19 契约发布）。

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
| P0 单专家文件上下文 | 已完成 | 上传/选择/移除/删除/发起 Run 闭环 Widget 测试通过；`fileRefs` 仅传 `{id, role}`；视口/滚动可点击性修复后 `flutter test` 40/40 全绿 |
| P2 家庭协同数据层 | 已完成 | `Family`（成员/知识/决策）、`Steward`（管家动态/确认中心）、`Dashboard` 的 DTO/Repository/HTTP 实现按已发布契约完成（字段来自服务端 ViewModels 与 `frontend-api-integration.md`）；映射/错误/批量确认请求体约束测试通过，`flutter test` 49/49 全绿 |
| P1 客户端后端代理审计与收口 | 已完成 | 客户端无第三方 Key、Endpoint 或 SDK 直连（房间图 unsplash 直连移除，改本地渐变占位）；AI 与 Connector 均经 `ApiClient`；静态扫描无残留，相关测试全绿 |
| P3 管家工作台与确认中心 | 已完成 | Dashboard 聚合视图四区块（待确认 → 管家动态 → 家庭概览 → 快捷入口，各模块独立降级）；Plan 三段（待确认/任务/日历）；共享确认组件 `ConfirmationSection` 支持 L1 批量确认（新幂等键）、L2/L3 逐项确认/拒绝（理由输入）、失败重试复用同一幂等键（重入恢复）、批量局部失败按结果逐项更新；确认中心页面 `confirmation_center_page.dart`（风险过滤 + Dashboard/Plan 查看全部入口）；用例通过，`flutter test` 72/72 全绿 |
| P4 家庭设置 | 已完成 | ProfilePage 增加家庭成员/家庭知识入口；`family_members_page.dart` 成员列表/新建/编辑/生命周期状态（`memberStatus` 值域按服务端契约，终态变更走 `correctMember` 受控更正并必填理由）；`family_knowledge_page.dart` 知识列表/分类筛选/本地搜索/新建与编辑（`writeKnowledge` 同 key 重写）/删除二次确认/AI 来源与置信度/冲突解决展示；无权限/空/错误/重试状态可用；用例通过，`flutter test` 72/72 全绿 |
| P5 能力托管、家庭状态与风险组件 | 已完成 | `NexusPalette` 新增风险（riskL1/L2/L3）与健康（healthy/degraded/low_battery/offline）语义 token；公共组件 `RiskBadge`/`ConfirmationCard`/`StewardTimelineTile`（提取自 confirmation_section/dashboard_page 私有实现，确认中心与工作台同步改用）；`SmartHomeRepository` 新增 `fetchDeviceHealthSummary`（B10 聚合）/`fetchDeviceHealth`（B14 单设备详情），DTO 按 §8.12 契约映射；`home_plus_page.dart` 空间卡叠加健康徽标（离线/低电量/降级计数，按空间聚合）、设备卡显示健康语义标签与采样时间（不暴露原始数值）、空间卡点击打开空间详情（设备健康列表 + 管家动态入口）；新建 `steward_timeline_page.dart`（游标分页，`/home-plus/timeline` push 路由，dashboard 管家动态区块增加"查看全部"入口）；能力中心专家卡与工作台展示托管策略说明（家庭管家托管执行、L1 自动确认/L2 建议确认/L3 需逐项决定，产品既定策略静态文案，无猜测性 HTTP）；`UI_STYLE_GUIDE.md` 同步语义色与组件；用例通过，`flutter test` 89/89 全绿 |
| P5b 个人偏好收藏管理 | 已完成 | `FavoriteDto`/`FavoriteRepository`/`HttpFavoriteRepository` 按 B15 契约实现（`/api/v1/life/favorites`，category restaurant/travel/material、visibility private/family、import 的 Source 留痕）；Profile 新增「我的收藏」入口，`favorites_page.dart` 分类列表/新建/编辑/软删除（二次确认）/对话导入，详情 JSON 合法性校验与摘要展示，private 仅本人可见语义；用例通过，`flutter test` 117/117 全绿 |
| P5c 个人生活专家：翻牌与行程 | 已完成 | `LifeExpertRepository` 按 B16/B17 契约实现（`POST /api/v1/experts/personal-life-expert/runs`，recommend/plan 同步返回 + `calendar_create_event` confirm 幂等键，Data.Id 作 runId、缺失时确认安全降级）；能力中心新增翻牌/行程入口；`life_recommend_page.dart`（时间/位置/口味 → 建议卡，不渲染提示或思考链）与 `life_trip_page.dart`（目的地/天数 → 每日安排 + L1 确认影响范围展示、提交中禁用、确认后日历同步提示）；用例通过，`flutter test` 117/117 全绿 |
| P6 质量与 API 联调 | 已完成 | 新增收藏/生活专家 HTTP 映射、错误与页面 Widget 测试；`dart format lib/ test/`、`flutter analyze lib/`（无新增告警）、`flutter test --no-pub` 全量 117/117 通过 |
| P7 MCP 边界静态审计 | 已完成 | `lib/`、`pubspec.yaml`、android/ios 配置与日志均无 MCP stdio/SQLite 客户端引用；`NEXUSMIND_ACCESS_TOKEN`/`NEXUSMIND_MCP_ALLOW_SENSITIVE` 仅存在于 docs 约束描述，代码与配置零引用；`env/.env` 仅含 `API_BASE_URL` 单键；路由与 features/ 无本地 Agent 缓存页面、路由或 Repository |

## 3. 下一步

| 优先级 | 交付 | 前置条件 | 最小验收 |
| --- | --- | --- | --- |
| P8 | V2.4 我的连接 | B18/B19 字段、OAuth 状态与撤销契约发布 | 家庭/个人 scope 状态、个人授权发起/完成/过期/撤销、跨成员不泄露、无 Token 落端测试通过；不提供家庭级密钥或成员授权配置。 |

## 4. 范围与门禁

- 专家团协作不在当前产品范围；除非产品总设计先新增并记录该决策，计划不创建对应前端任务。
- 服务端字段级契约未发布时，不新增猜测性的 HTTP 实现；本地 Repository 与受控 UI 状态可先行。
- P3--P5 的所有写操作均须展示影响范围、权限、风险和确认要求，提交中禁止重复操作并使用新的幂等键。
- Creator MCP 的同步与敏感数据策略仅由 `D:\HomeMind\core\docs\mcp-creator-center.md` 和后端设计约束；任何需要在 App 中呈现的创作者能力，先发布字段级 `/api/v1` 契约，再纳入本计划。
- 任一交付改变 UI Token/组件时，同步 `docs/UI_STYLE_GUIDE.md` 与 `lib/core/ui/nexus_theme.dart`；改变工程架构时同步 `docs/DEVELOPMENT_GUIDELINES.md`。
- 完成状态只在满足本计划的最小验收后回写；已过时的下一步应被替换，不追加历史记录。
