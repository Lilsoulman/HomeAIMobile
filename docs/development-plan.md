# HomeMind 移动端开发计划

> 本计划以 `../../core/docs/product.md` 为产品事实来源。收到“按照下一步计划进行开发”或“继续开发”时，选择下方依赖已满足的首个 `待做` 任务；若任务没有详细任务表，先按本文件表格格式补齐，再开发。接口字段、权限和状态机以 Swagger 与 `../../core/HomeMind.Api/Controllers/` 为准；后端未发布接口时停止并报告缺口，不 mock。

## 下一步（当前开发焦点）

| 顺序 | 任务 | 领域 | 状态 | 说明 |
| --- | --- | --- | --- | --- |
| 1 | R1-M | 移动端旧领域下线 | 完成 | 已移除下线领域入口、路由、依赖装配、DTO、Repository、测试与过时依赖；App 收敛为四 Tab 与受控语音入口 |
| 2 | P0-A | App 四 Tab 壳层与首页 | 阻塞 | Household State Swagger 契约未可用；现有 Dashboard 包含已下线模块，不能作为首页数据源 |
| 3 | P0-B | 已发布设备与既有场景 | 阻塞 | 依赖运行中 Swagger 核对路由、字段、权限和真实结果语义；当前 Swagger 不可访问，不能继续使用旧映射 |
| 4 | S0-M | 可靠场景执行 | 阻塞 | 等待场景生命周期、预览、Trust 和步骤结果契约发布后接入 |
| 5 | M0-M | 个人习惯与人工优先 | 阻塞 | 等待个人偏好、候选、单条编辑/删除和 `ManualOverride` 契约发布后接入 |
| 6 | N1-M | 家庭新手模式 | 阻塞 | 等待可恢复的新手引导契约发布后接入；HA 配置和发现仍由 Web 管理 |

### R1-M 移动端旧领域下线执行计划

| ID | 状态 | 依赖 | 编码任务 | 改动位置 | 完成标准与验证 |
| --- | --- | --- | --- | --- | --- |
| INFRA-B1 | 完成 | Flutter 3.47.1、Git `main`/`release` 分支 | 建立标准 Android staging/production flavors、编译期环境校验、时间戳版本规则与本地完整包构建入口 | `android/app/`、`lib/core/env/`、`config/`、根目录 BAT、发布文档 | main 构建 staging，用户版本固定 `0.0.0`；release 手输 `x.y.z`，buildNumber 自动使用 UTC 2020 起累计秒数；APK/AAB 均由标准 Flutter Engine 构建，生产 AAB 强制正式签名 |
| R1-M1 | 完成 | 产品总设计、当前路由与依赖图 | 盘点所有已下线领域的页面、路由、Provider、Repository、DTO、测试与文档引用，确认没有仍依赖这些入口的日常控制流程 | `lib/`、`test/`、`docs/` | 清单仅包含财务、缴费、快递、宠物、日程、出游、本地生活、团队运行、旧 Skill、微信授权交换等已排除领域；不波及会话、设备、场景和个人习惯 |
| R1-M2 | 完成 | R1-M1 | 删除遗留入口、路由、装配、Repository/DTO 与对应测试；不为旧 API 保留兼容层或 mock | `lib/`、`test/`、`pubspec.yaml` | App 不再能导航至下线领域，且无生产代码调用已下线路由 |
| R1-M3 | 完成 | R1-M2 | 修复保留功能的编译引用，更新空态和导航文案为四 Tab 日常控制模型 | `lib/main.dart`、`lib/router.dart`、`lib/pages/` | 不新增竞争性架构；未发布替代能力保持受控隐藏，不伪造结果 |
| R1-M4 | 完成 | R1-M3 | 清理测试夹具和移动端文档中的旧领域说明，补核心导航 Widget 测试 | `test/`、`docs/` | `dart format lib test`、`flutter analyze`、相关 `flutter test` 通过 |

### P0-A App 四 Tab 壳层与首页执行计划

| ID | 状态 | 依赖 | 编码任务 | 改动位置 | 完成标准与验证 |
| --- | --- | --- | --- | --- | --- |
| P0-A1 | 阻塞 | R1-M、已发布会话与设备/场景读取契约 | 已确认 `GET /homes/{homeId}/state` 的 Controller 响应仍为 `object`，运行中 Swagger 不可访问；现有 Dashboard 包含已下线模块，不能作为首页数据源 | Swagger、`../../core/HomeMind.Api/Controllers/Household/`、`Dashboard/` | 需发布 Household State 的字段级 Swagger 契约后继续；不使用旧仪表盘、日程或专家数据代替首页 |
| P0-A2 | 待做 | P0-A1 | 将根导航收敛为首页、场景、设备、我的四个 Tab，并保留全局语音入口的受控状态 | `lib/main.dart`、`lib/router.dart`、`lib/pages/` | 320–430px 下可用；Tab 切换用 `go`；无下线入口 |
| P0-A3 | 待做 | P0-A1、P0-A2 | 实现首页当前状态、一个动作、最近场景和异常的 loading/empty/error/retry 表面 | `lib/pages/dashboard_page.dart`、对应 feature | 不在 `build` 发请求；不加载完整设备列表；未发布数据只显示受控状态 |
| P0-A4 | 待做 | P0-A3 | 补 Repository 映射/错误测试和首页、四 Tab Widget 测试，回写 API/产品文档 | `test/`、`docs/` | `dart format lib test`、`flutter analyze`、相关 `flutter test` 通过 |

### P0-B 已发布设备与既有场景执行计划

| ID | 状态 | 依赖 | 编码任务 | 改动位置 | 完成标准与验证 |
| --- | --- | --- | --- | --- | --- |
| P0-B1 | 阻塞 | R1-M、运行中 Swagger | 核对标准化空间、设备、能力、健康、既有场景读取与执行的请求/响应、权限、幂等和真实结果语义 | Swagger、`../../core/HomeMind.Api/Controllers/SmartHome/` | `http://localhost:5280/swagger` 当前不可访问；不得以旧 Repository/DTO 或 Controller 推测结果语义 |
| P0-B2 | 待做 | P0-B1 | 定义或收敛设备与场景 Repository/DTO；经 `ApiClient` 显式解析响应并透传错误 | `lib/features/smart_home/` | 映射与错误测试覆盖；页面不直接调用网络层 |
| P0-B3 | 待做 | P0-B2 | 实现设备按空间的高频控制和既有场景列表/执行；副作用前展示已发布的影响与确认信息 | `lib/pages/`、`lib/router.dart` | loading/empty/error/retry；提交中禁重复；仅在真实回读后显示完成 |
| P0-B4 | 待做 | P0-B3 | 为设备、场景和失败结果补 Widget 测试，并同步受影响文档 | `test/`、`docs/` | `dart format lib test`、`flutter analyze`、相关 `flutter test` 通过 |

### S0-M 可靠场景执行执行计划

| ID | 状态 | 依赖 | 编码任务 | 改动位置 | 完成标准与验证 |
| --- | --- | --- | --- | --- | --- |
| S0-M1 | 待做 | Core `S0` 已在 Swagger 发布 | 核对场景生命周期、三层来源、预览、Trust 裁决、确认截止、`SceneExecution`、`ExecutionStep`、重试和撤销契约 | Swagger、`../../core/HomeMind.Api/Controllers/SmartHome/` | 未发布则停止；所有字段、状态和权限有记录 |
| S0-M2 | 待做 | S0-M1 | 定义场景预览、执行、步骤结果和确认 DTO/Repository，并处理幂等与轮询终态 | `lib/features/smart_home/` | 仅使用可公开字段；终态或页面释放后停止轮询 |
| S0-M3 | 待做 | S0-M2 | 实现预览、解释卡、确认、部分失败、失败步骤重试和受审计撤销界面 | `lib/pages/`、`lib/widgets/` | 不显示引擎过程；不自行倒计时、默认执行或全量回滚 |
| S0-M4 | 待做 | S0-M3 | 补 Repository/Widget 测试并回写产品、API、计划和 UI 文档 | `test/`、`docs/` | 格式、分析和相关测试通过 |

### M0-M 个人习惯与人工优先执行计划

| ID | 状态 | 依赖 | 编码任务 | 改动位置 | 完成标准与验证 |
| --- | --- | --- | --- | --- | --- |
| M0-M1 | 待做 | Core `M0` 已在 Swagger 发布 | 核对个人候选、个人习惯、单条修改/删除、关闭覆盖和 `ManualOverride` 契约 | Swagger、`../../core/HomeMind.Api/Controllers/Memory/` | 认证主动调整才可生成候选；不能读取或改写家庭级治理数据 |
| M0-M2 | 待做 | M0-M1 | 定义个人习惯 DTO/Repository，并在“我的”中实现查看、单条修改与删除 | `lib/features/memory/`、`lib/pages/` | 只显示用户可理解字段；不显示 `source`、`confidence`、`condition`、`weight` |
| M0-M3 | 待做 | M0-M2 | 补映射、错误和我的习惯 Widget 测试，回写文档 | `test/`、`docs/` | 自动执行与匿名操作不产生个人偏好；格式、分析和定向测试通过 |

## 交付顺序

| 阶段 | 范围 | 交付与验收 |
| --- | --- | --- |
| R1 | 旧领域下线 | App 与文档不再暴露下线能力；保留功能无编译或路由依赖 |
| P0 | 日常控制 | 四 Tab、全局语音入口、已发布设备和场景的真实读取与执行 |
| S0 | 可靠场景 | 生命周期、预览、信任裁决、确认、真实步骤结果、重试和撤销 |
| M0 | 个人偏好 | 个人习惯、认证主动调整候选和人工优先窗口 |
| N1 / P1 | 新手模式与可靠性 | 可恢复家庭引导、场景健康和低打扰主动建议；均以已发布契约为前提 |

## 实现约束

1. 页面只依赖 Repository 和 DTO；HTTP 只经 `ApiClient`，路由只在 `router.dart` 定义。
2. 先定义 Repository 接口，再补 HTTP 实现和显式 parser；本地实现仅用于受控开发切换，不代替未发布 API。
3. `ChangeNotifier` 只放跨页面响应状态，局部交互使用 `StatefulWidget`；每次 `await` 后更新 UI 前检查 `mounted`。
4. 写操作禁用重复点击；一次用户意图按 Swagger 使用幂等键；运行终态或页面释放后停止轮询。
5. Household State、Trust、场景生命周期、确认超时与人工优先均由服务端裁决，客户端不得推断、覆盖或伪造结果。
6. 改动 UI token/组件同步 `UI_STYLE_GUIDE.md` 和主题；改动架构同步 `DEVELOPMENT_GUIDELINES.md`。

## 完成定义

- 已在 Core Swagger 核对接口、权限、错误语义与数据敏感性。
- 有 Repository/API 映射测试和关键页面 Widget 测试。
- 已运行 `dart format lib test`、`flutter analyze` 和相关 `flutter test`；发布前运行完整测试。
- 同步本目录受影响的产品、计划、接入说明与 UI 文档，不保留已下线领域的说明或 API 索引。
