# HomeMind 移动端 API 接入

## 事实来源与基础设施

字段、权限、状态码和示例的唯一事实来源是运行中的 Swagger（`http://localhost:5280/swagger`）及 `../../core/HomeMind.Api/Controllers/` 的 DTO；本文只说明移动端接入边界，不复制 DTO。全部请求使用 `/api/v1` 前缀，请求 JSON 为 `camelCase`，服务端包络与 `Data` 字段按实际 PascalCase 显式解析。

| 责任 | 位置 | 规则 |
| --- | --- | --- |
| 环境与地址 | `lib/core/env/env_config.dart` | 基础地址来自 dart-define、`env/.env` 或本地覆盖；`apiPrefix` 统一追加 `/api/v1` |
| 请求与刷新 | `lib/core/api/api_client.dart` | 全部 HTTP 经 Dio 单例；收到 `401` 时单飞刷新且仅重放原请求一次 |
| 响应与错误 | `lib/core/api/api_envelope.dart`、`api_exception.dart` | 解包 `{ Code, Msg, Data }` 并转换为页面可处理的异常 |
| 会话存储 | `lib/core/storage/token_storage.dart` | 使用安全存储；Token 不进入日志或页面状态 |
| 领域接入 | `lib/features/<feature>/` | Repository 契约、DTO、HTTP 实现和 parser 同域维护 |

## 通用接入流程

1. 在 Swagger、控制器 DTO 与 `../../core/docs/api-integration.md` 核对路由、请求体、`Data`、授权、幂等与状态机。未发布的契约不得生成客户端类型、mock 数据或入口。
2. 在对应 feature 先定义 Repository 接口、DTO 和显式 parser。Widget 只能接触 DTO，不能传递动态 JSON 或创建 HTTP 客户端。
3. 使用 `ApiClient.get/post/put/delete` 发出请求；请求与 query 使用 `camelCase`，令牌由拦截器附加。
4. `401` 刷新失败时清空会话并回登录；`403`、`404`、`409`、`422`、`502/503` 和网络失败必须显示真实状态，不得把命令已发送表示为已完成。
5. 为映射、错误和关键交互添加测试。异步界面完整处理 loading、empty、error、retry，副作用操作防止重复提交。

## 移动端已发布能力索引

| 领域 | 关键路由 | 移动端用途与边界 |
| --- | --- | --- |
| 会话 | `auth/register`、`auth/login`、`auth/refresh`、`auth/me`、`auth/logout` | 建立和恢复会话；家庭与角色以服务端会话为准 |
| 家庭与确认 | `homes/{homeId}/members`、`homes/{homeId}/confirmations`、`activities` | 只读家庭信息、待确认行动与动态；真实授权以 API 为准 |
| 设备与空间 | `smart-home/spaces`、`smart-home/devices`、`smart-home/devices/health` | 消费标准化空间、设备、能力、状态与健康摘要；不暴露 HA 原始字段 |
| 既有场景 | `smart-home/scenes`、`smart-home/scenes/{sceneKey}/run` | 读取和执行已发布场景；每次执行以 Swagger 规定的幂等与响应语义为准 |

`homeId` 始终必须与令牌家庭一致，不能由路由参数、缓存或用户输入越权覆盖。若当前 Swagger 与索引不一致，停止接入并以 Swagger 为准更新本文。

## 场景、确认与真实结果

当前场景执行只能消费已经发布的接口。用户发起操作后，页面展示服务端提供的动作、影响范围、解释和确认要求；只有服务端或 HA 实际回读确认后才显示完成。部分失败必须逐项展示，且仅为服务端标记为可重试的失败步骤提供重试入口。

待发布的 Household State、Trust、场景生命周期、三层场景解析、预览、逐步骤执行、撤销、个人偏好和人工优先契约，须以 `../../core/docs/api-integration.md` 第 5 节及 Swagger 为准。`memories` 与 `memory-candidates` 不能代替待发布的个人偏好 `M0` 契约，也不应在 App 中作为“我的习惯”入口。上述契约发布前，客户端保持受控状态，不推测成员身份、不应用个人覆盖、不自行计时确认，也不伪造场景结果。

## 下线领域

R1 已下线财务、缴费、快递、宠物、家庭日程、出游、本地生活、团队运行、旧 Skill 和微信授权交换路由。移动端不得调用、测试、宣传或为这些领域保留 API 说明；任何遗留客户端调用应在 R1 清理任务中移除。

## 地址与真机联调

- 默认 API 地址位于 `env/.env`；可用 `--dart-define=API_BASE_URL=https://...` 覆盖。
- Android 真机的 `localhost` 指向设备自身，使用后端电脑的局域网 IP；Android 模拟器通常使用 `10.0.2.2`。
- 切换地址会清空当前会话并要求重新登录。仅使用受信任的开发或测试地址，不在客户端配置第三方 Endpoint。
