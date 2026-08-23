# HomeMind 移动端开发计划

> Codex/Agent 收到「按照下一步计划进行开发」（或「继续开发」）时：读取下方「下一步」区，选依赖已满足的首个 `待做` 任务；若该任务尚未展开详细任务表，**先在本文档按「P3-F 家庭财务执行计划」同款表格格式（ID/状态/依赖/编码任务/改动位置/完成标准与验证）生成任务表**，再按表逐项实现、验证、回写。禁止跳过计划直接写代码。后端 API 出入参以 Swagger + `../core/HomeMind.Api/Controllers/` 为准；后端未发布接口则停止并报告缺口，不 mock。

## 下一步（当前开发焦点）

| 顺序 | 任务 | 领域 | 状态 | 说明 |
| --- | --- | --- | --- | --- |
| 1 | F4 | 家庭财务移动端快速流 | 完成 | 已接入 finance/billing API、CSV 预览导入与缴费登记 |
| 2 | M3 快递 | 快递管家移动端 | 完成 | 已接入 B44 运单登记、列表、刷新与异常建议 |
| 3 | M3 宠物 | 宠物管家移动端 | 完成 | 已接入 B45 宠物档案、照护提醒与用品库存 API |
| 4 | M3 缴费 | 缴费管家移动端 | 完成 | 已接入 B43 账户、登记、提醒和年度趋势 API |
| 5 | M3 日程 | 家庭日程协同移动端 | 完成 | 已接入 B46 家庭事件、冲突、共同空档、到期提醒与明日预览 |
| 6 | F12 旅行计划时间线 | 个人计划移动端体验 | 完成 | 在计划入口聚合已确认的旅行日程，提供摘要、进度与时间线；无旅行事件时引导现有行程规划 |

## 工程基础设施

| ID | 状态 | 依赖 | 编码任务 | 改动位置 | 完成标准与验证 |
| --- | --- | --- | --- | --- | --- |
| INFRA-H1 | 完成 | Flutter 3.47.1、Shorebird 账号 | 接入 Shorebird 自动更新，仅允许 Dart 代码 Patch，不增加资源热更新或应用内更新 UI | `shorebird.yaml`、`pubspec.yaml`、`pubspec.lock`、`android/gradle.properties`、`docs/shorebird-code-push.md`、`docs/DEVELOPMENT_GUIDELINES.md` | `shorebird init`、doctor 与 Android AAB Release dry-run 通过；Release/Patch 边界、命令、签名和真机验证要求已记录 |
| INFRA-H2 | 完成 | INFRA-H1、Git `main`/`release` 分支 | 建立 Android staging/production flavors、编译期环境校验、时间戳版本规则与本地 Shorebird 底包/Patch 脚本 | `android/app/`、`lib/core/env/`、`config/`、`scripts/`、发布文档 | main 构建 staging，用户版本固定 `0.0.0`；release 手输 `x.y.z`，buildNumber 自动使用 UTC 2020 起累计秒数；脚本默认上传、支持 `-DryRun`，生产 AAB 强制正式签名，Patch 复用底包版本并记录 Git Commit 与 patchNumber |

### M3 家庭日程协同移动端执行计划

| ID | 状态 | 依赖 | 编码任务 | 改动位置 | 完成标准与验证 |
| --- | --- | --- | --- | --- | --- |
| M3-S1 | 完成 | B46 运行中 Swagger | 核对家庭事件、冲突、共同空档、证件到期提醒、提醒和明日预览的路由、camelCase 请求、PascalCase 响应、家庭权限与错误码 | `../core/HomeMind.Api/Controllers/Family/FamilyScheduleController.cs`、运行中 Swagger | 六类路由均已确认；`homeId` 受 JWT 家庭边界约束，读写分别需要 CalendarRead/CalendarWrite 与家庭主权限 |
| M3-S2 | 完成 | M3-S1 | 定义家庭日程 DTO 与 Repository，经 `ApiClient` 显式解析 API 响应并从当前会话取得 `homeId` | `lib/features/family_schedule/`、`lib/main.dart` | PascalCase 字段映射、查询参数、错误透传和证件提醒请求均有测试；不保存或展示证件号码、照片或原件 |
| M3-S3 | 完成 | M3-S2 | 实现家庭入口日程页：展示明日预览、冲突、共同空档和到期提醒；支持新建仅含展示名称的证件到期提醒 | `lib/pages/family_schedule_page.dart`、`lib/router.dart`、`lib/pages/home_plus_page.dart` | loading/empty/error/retry 完整；写入期间禁重复提交；只展示服务端标准化字段，不提供日历写入或证件详情入口 |
| M3-S4 | 完成 | M3-S2、M3-S3 | 补 Repository 映射/错误测试和关键页面 Widget 测试，并回写 API、产品与开发计划文档 | `test/family_schedule/`、`docs/api-integration.md`、`docs/mobile-product.md`、`docs/development-plan.md` | `dart format lib test`、`flutter analyze` 和相关 `flutter test` 通过 |

### F12 旅行计划时间线执行计划

| ID | 状态 | 依赖 | 编码任务 | 改动位置 | 完成标准与验证 |
| --- | --- | --- | --- | --- | --- |
| F12-1 | 完成 | 已发布 Calendar API、生活专家行程规划流 | 在计划入口增加旅行视图，按已确认日历事件识别旅行行程并展示摘要、状态和纵向时间线 | `lib/pages/plan_page.dart` | 只消费 `CalendarEventDto` 标准字段，不新增未发布接口或客户端假数据 |
| F12-2 | 完成 | F12-1 | 增加无行程引导至现有行程规划页，并补旅行时间线与空状态 Widget 测试 | `test/plan_page_test.dart` | 行程事件、状态摘要、时间线卡片和空状态均可验证 |
| F12-3 | 完成 | F12-1、F12-2 | 回写产品、API 与开发计划文档并执行格式、分析和定向测试 | `docs/mobile-product.md`、`docs/api-integration.md`、`docs/development-plan.md` | `dart format`、相关 `flutter test` 通过；不得显示供应商字段或原始载荷 |

### M3 宠物管家移动端执行计划

| ID | 状态 | 依赖 | 编码任务 | 改动位置 | 完成标准与验证 |
| --- | --- | --- | --- | --- | --- |
| M3-P1 | 完成 | B45 已发布 | 定义宠物档案、照护、用品、提醒 DTO 与 Repository，并按 Swagger 映射 PascalCase 响应 | `lib/features/pet/` | Repository 映射、请求字段和错误透传测试通过 |
| M3-P2 | 完成 | M3-P1 | 接入宠物 HTTP Repository 与家庭上下文 `homeId` | `lib/features/pet/`、`lib/main.dart` | 四类 API 路径真实可调用，不 mock 后端结果 |
| M3-P3 | 完成 | M3-P2 | 实现宠物管家页面：提醒、宠物档案、照护与用品库存，支持新增与刷新 | `lib/pages/pet_page.dart`、`lib/router.dart`、`lib/pages/home_plus_page.dart` | loading/empty/error/retry；写操作防重复；不展示敏感字段 |
| M3-P4 | 完成 | M3-P3 | 补 Repository 与 Widget 测试并回写产品/API 文档 | `test/pet/`、`docs/api-integration.md`、`docs/mobile-product.md` | `dart format`、`flutter analyze`、相关 `flutter test` 通过 |

### M3 缴费管家移动端执行计划

| ID | 状态 | 依赖 | 编码任务 | 改动位置 | 完成标准与验证 |
| --- | --- | --- | --- | --- | --- |
| M3-B1 | 完成 | B43 运行中 Swagger | 核对缴费账户、缴费登记、到期提醒和年度趋势的路由、camelCase 请求、PascalCase 响应、权限与错误码 | `../core/HomeMind.Api/Controllers/Finance/BillingController.cs`、运行中 Swagger | 四条 B43 路由已确认；仅消费家庭内脱敏的账单视图，不提供支付入口 |
| M3-B2 | 完成 | M3-B1 | 扩展财务 DTO 与 Repository，显式解析年度趋势并经 `ApiClient` 请求当前会话家庭的真实 API | `lib/features/finance/` | `year` 查询参数正确传递；PascalCase `Year`、`TotalAmount`、`Months` 映射且错误原样透传 |
| M3-B3 | 完成 | M3-B2 | 在家庭财务页展示本年度已登记缴费金额和月度汇总，保留 loading/empty/error/retry 状态 | `lib/pages/finance_page.dart` | 仅展示服务端聚合；无支付、账户号或原始票据入口 |
| M3-B4 | 完成 | M3-B2、M3-B3 | 补映射、错误和关键页面 Widget 测试，并回写 API/产品文档 | `test/finance/`、`docs/api-integration.md`、`docs/mobile-product.md` | `dart format lib test`、定向 `flutter test` 通过；`flutter analyze` 仅保留既有 info 提示 |

### F4 家庭财务移动端快速流

| ID | 状态 | 依赖 | 编码任务 | 改动位置 | 完成标准与验证 |
| --- | --- | --- | --- | --- | --- |
| F4-1 | 完成 | F2 | 定义财务/缴费 DTO 与 Repository，接入真实 finance、billing API | `lib/features/finance` | PascalCase 响应映射；homeId 从会话获取；错误原样传递 |
| F4-2 | 完成 | F4-1 | 实现财务快速流页面：汇总、流水、缴费账户、提醒、登记已缴 | `lib/pages/finance_page.dart`、`lib/router.dart` | loading/empty/error/retry；写操作禁重复提交；不显示敏感字段 |
| F4-3 | 完成 | F4-2 | 增加 CSV 文本预览导入与结构化缴费建档入口 | `lib/pages/finance_page.dart` | 仅上传 CSV/结构化字段，不上传图片或原始票据 |
| F4-4 | 完成 | F4-2 | 补 Repository 映射和关键页面 Widget 测试，更新依赖注入 | `test/finance`、`lib/main.dart` | `dart format`、定向 `flutter test` 通过；分析仅保留既有 lint 提示 |

### M3 快递管家移动端执行计划

| ID | 状态 | 依赖 | 编码任务 | 改动位置 | 完成标准与验证 |
| --- | --- | --- | --- | --- | --- |
| M3-C1 | 完成 | B44 运行中 Swagger | 核对已发布的运单登记、列表、刷新和异常建议接口的路由、camelCase 请求、PascalCase 响应、权限与错误码 | `../core/HomeMind.Api/Controllers/Courier/`、运行中 Swagger | 四条 B44 路由已在 Swagger 确认；仅消费脱敏后的运单尾号 |
| M3-C2 | 完成 | M3-C1 | 定义快递 DTO 与 Repository，使用 `ApiClient` 显式解析列表、刷新结果与异常建议 | `lib/features/courier/` | 不保存或展示完整运单号；`homeId` 来自会话；错误原样传递 |
| M3-C3 | 完成 | M3-C2 | 实现家庭入口中的快递列表、异常建议、刷新和登记流 | `lib/pages/courier_page.dart`、`lib/router.dart`、`lib/main.dart` | loading/empty/error/retry；登记和刷新防重复提交；仅创建站内建议，不提供催件、改址或下单入口 |
| M3-C4 | 完成 | M3-C2、M3-C3 | 补 Repository 映射/错误测试和关键页面 Widget 测试，并回写 API 与移动端产品文档 | `test/courier/`、`docs/api-integration.md`、`docs/mobile-product.md` | `dart format lib test`、`flutter analyze` 和定向 `flutter test` 通过 |

## 交付顺序

| 阶段 | 范围 | 交付与验收 |
| --- | --- | --- |
| M0 会话与骨架 | Env、令牌、安全存储、路由、主题 | 登录→`me`→401 刷新→会话失效回登录 |
| M1 效率与家庭 | Dashboard、待办、日历、家庭、确认和动态 | 每个异步页面有加载/空/失败/重试；家庭隔离正确 |
| M2 个人能力 | 收藏、生活专家、会话、个人连接 | DTO 显式映射；敏感信息不展示；终态停止轮询 |
| M3 轻量管家 | 财务、缴费、快递、宠物、家庭日程等已发布 API | 先只读和提醒，再写入；按权限和确认模型交付 |
| M4 轻量 AI 工具 | 场景、轻量剪辑发起与进度 | 不把复杂编辑器搬到移动端；失败不伪造成功 |

## 实现约束

1. 页面只依赖 Repository 和 DTO；HTTP 只经 `ApiClient`，路由只在 `router.dart` 定义。
2. 先定义 Repository 接口，再补 HTTP 实现和显式 parser；本地实现仅用于受控开发切换，不代替未发布 API。
3. `ChangeNotifier` 只放跨页面响应状态，局部交互使用 `StatefulWidget`；每次 `await` 后更新 UI 前检查 `mounted`。
4. 写操作禁用重复点击；幂等接口为一次用户意图复用 UUID；运行终态或页面释放后停止轮询。
5. 改动 UI token/组件同步 `UI_STYLE_GUIDE.md` 和主题；改动架构同步 `DEVELOPMENT_GUIDELINES.md`。

## 完成定义

- 已在 Core Swagger 核对接口、权限、错误语义与数据敏感性。
- 有 Repository/API 映射测试和关键页面 Widget 测试。
- 运行 `dart format`、`flutter analyze`、相关 `flutter test`；发布前运行完整测试。
- 同步本目录受影响的产品、计划或接入说明，不追加任务历史。
