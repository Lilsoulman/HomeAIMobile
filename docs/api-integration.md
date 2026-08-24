# HomeMind 移动端 API 接入

## 现有基础设施

| 责任 | 位置 | 规则 |
| --- | --- | --- |
| 环境与地址 | `lib/core/env/env_config.dart` | 基础地址来自 dart-define、`env/.env` 或本地覆盖；API 前缀由 `apiPrefix` 统一追加 `/api/v1` |
| 请求与刷新 | `lib/core/api/api_client.dart` | 全部 HTTP 经 Dio 单例；401 单飞刷新并仅重放原请求一次 |
| 响应与错误 | `lib/core/api/api_envelope.dart`、`api_exception.dart` | 解包业务包络并转换为页面可处理的异常 |
| 会话存储 | `lib/core/storage/token_storage.dart` | 移动端用安全存储；不把 token 放在日志或页面状态 |
| 领域接入 | `lib/features/<feature>/` | Repository 接口、DTO、HTTP 实现和 parser 同域维护 |

## 接入步骤

1. 在 Core Swagger 与 `D:\HomeMind\core\docs\api-integration.md` 确认路由、请求体、`Data`、权限、幂等要求与状态机。
2. 在对应 feature 定义/更新 DTO 和 Repository 契约；解析服务端当前 PascalCase 响应，不把动态 JSON 传给 Widget。
3. 使用 `ApiClient.get/post/put/delete` 完成 HTTP 实现。请求体与 query 传 camelCase，令牌由拦截器添加。
4. 在 Provider/页面处理 loading、empty、error、retry。401 刷新失败由 `SessionExpiredException` 清空会话并回登录；不自行重复刷新。
5. 为映射、错误和关键交互添加测试，再接入路由与页面。

## 异步运行与确认

创建专家运行、技能运行或场景动作后，持久化页面所需的 `runId`，查询运行详情/公开事件。看到待确认 action 时，展示风险与影响范围；用户操作后调用确认接口，继续轮询直到终态。客户端不得推断成功、展示 Prompt 或消费引擎内部数据。

## 开发期模拟家庭数据

| 接口 | 移动端用途 | 数据边界 |
| --- | --- | --- |
| `GET /smart-home/mock/bootstrap` | test/staging 构建一次性读取模拟空间、设备、场景与健康摘要 | 仅在服务端显式启用 Development 模拟时调用；必须校验 `IsMock=true` 并展示 `Disclaimer`，只读展示，不执行、确认或写入 |
| `GET /smart-home/spaces`、`GET /smart-home/devices`、`GET /smart-home/scenes` | 模拟接口不可用时的真实标准化读接口回退 | 仅消费空间、设备、能力、状态摘要和场景公开字段；不显示凭据、厂商实体 ID 或原始状态 |

## 旅行计划时间线

计划入口的旅行视图复用已发布的日历接口 `GET /calendar/events`，按 `CalendarEventDto` 的标题、时间、地点和描述聚合已确认的旅行事件。创建行程仍使用生活专家 `plan` 流及 `calendar_create_event` 确认动作；客户端不新增旅行计划接口、不 mock 未发布数据，也不展示日历提供商字段或原始事件载荷。

## 快递管家（B44）

| 接口 | 移动端用途 | 数据边界 |

## 宠物管家（B45）

| 接口 | 移动端用途 | 数据边界 |
| --- | --- | --- |
| `GET/POST /homes/{homeId}/pets` | 宠物档案列表与创建 | `homeId` 来自会话；仅显示档案字段，不显示第三方服务数据 |
| `GET/POST /homes/{homeId}/pets/{petId}/care-events` | 照护日历查看与新增 | 仅支持疫苗、驱虫等家庭提醒，不提供医疗建议 |
| `GET/PUT /homes/{homeId}/pets/{petId}/supplies` | 用品库存与日均消耗 | 只展示库存预测；不创建购买或支付操作 |
| `GET /homes/{homeId}/pets/alerts` | 七日内照护和断粮提醒 | 仅提示确认中心关联项，不自动下单 |

## 家庭日程协同管家（B46）

| 接口 | 移动端用途 | 数据边界 |
| --- | --- | --- |
| `GET /homes/{homeId}/schedule/events` | 查看未来七天家庭成员聚合日程 | `homeId` 来自会话；仅展示成员、标题和标准化时间，不暴露日历提供商字段 |
| `GET /homes/{homeId}/schedule/conflicts` | 提示两个成员的日程重叠 | 只展示服务端检测到的公开冲突摘要，不自动改期或写入日历 |
| `GET /homes/{homeId}/schedule/availability` | 显示全员共同空档 | `from`、`to` 和 `durationMinutes` 使用 camelCase 查询参数；最长窗口和权限由服务端校验 |
| `GET/POST /homes/{homeId}/schedule/document-deadlines` | 查看和创建家庭证件到期提醒 | 创建只传 `documentType`、家庭内 `displayName`、可选 `holderUserId` 与 `expiresOn`；不传、不存、不显示证件号码、照片或原件 |
| `GET /homes/{homeId}/schedule/reminders` | 查看缴费与证件的到期提醒 | 只消费服务端标准化提醒和既有确认关联，不自动执行操作 |
| `GET /homes/{homeId}/schedule/tomorrow-preview` | 展示睡前明日预览 | 仅显示聚合的日程、冲突和提醒计数；读写权限与家庭主授权由 API 的 `403` 决定 |

## 缴费管家（B43）

| 接口 | 移动端用途 | 数据边界 |
| --- | --- | --- |
| `GET/POST /homes/{homeId}/billing/accounts` | 查看和结构化建档缴费账户 | `homeId` 来自会话；不返回或保存账户号码、票据原文与第三方凭据 |
| `POST /homes/{homeId}/billing/accounts/{accountId}/payments` | 登记已完成缴费 | 仅记录既有缴费事实，不触发或代替任何支付；重复到期日由 API 返回 `409` |
| `GET /homes/{homeId}/billing/reminders` | 查看提前三天或一天的到期提醒 | 仅跳转既有确认中心 L1 卡，不自动缴费 |
| `GET /homes/{homeId}/billing/trend` | 展示年度已登记缴费的月度聚合趋势 | 读取 `Year`、`TotalAmount`、`Months`；可选 `year` 查询参数；不推导或伪造支付数据 |

## 快递管家（B44）
| --- | --- | --- |
| `GET /homes/{homeId}/courier/shipments` | 查看当前用户登记的运单 | 仅展示服务端脱敏的 `TrackingNumberMasked` |
| `POST /homes/{homeId}/courier/shipments` | 登记运单 | 请求使用 `trackingNumber`、`carrier?`、`label?`、`isFreshFood`、`expectedDeliveryAt?`；不在本地保存完整运单号 |
| `POST /homes/{homeId}/courier/shipments/{shipmentId}/refresh` | 刷新物流和异常建议 | 消费 `Shipment`、`NewEvents`、`Anomalies` 的 PascalCase 响应字段 |
| `GET /homes/{homeId}/courier/anomalies` | 显示站内异常建议 | 仅显示建议，不能催件、改址、下单或联系第三方 |

## 地址与真机联调

- 默认 API 地址在 `env/.env`；test/production 构建分别使用 `config/test.json` 与 `config/production.json`，当前均指向 `http://150.158.106.238`。构建或调试可用 `--dart-define=API_BASE_URL=https://...` 覆盖。
- 当前公网地址仍使用明文 HTTP，仅作为阶段性联调配置；正式面向公网发布前必须迁移 HTTPS。
- Android 真机的 `localhost` 指向设备自身，使用后端电脑的局域网 IP；Android 模拟器通常使用 `10.0.2.2`。
- 切换地址会清空当前会话并要求重新登录。仅使用受信任的开发/测试地址，不在客户端配置第三方 Endpoint。
