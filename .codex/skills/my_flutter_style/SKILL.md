---
description: NexusMind Flutter 客户端的项目专属编码规范。编写、分析或审查本项目 Dart/Flutter 代码时必须遵循。
---

# NexusMind Flutter 编码规范

## 1. 技术基线

- Dart SDK 为 `^3.12.2`，使用 Flutter Material 3。
- 静态检查继承 `package:flutter_lints/flutter.yaml`；提交前运行 `dart format`、`flutter analyze` 和相关 `flutter test`。
- 遵循 Effective Dart：类型、类和枚举使用 `UpperCamelCase`；变量、字段、参数、方法使用 `lowerCamelCase`；文件名使用 `snake_case`；私有成员以 `_` 开头。
- 不引入新的状态管理、路由、网络或存储框架。项目已使用 `provider`、`go_router`、`dio`、`shared_preferences` 和 `flutter_secure_storage`。

## 2. 目录与职责

```text
lib/
  core/                 # 跨功能基础设施：api、env、storage、settings、analytics
  features/<feature>/   # 业务契约、DTO 与本地/HTTP Repository 实现
  experts/              # 专家领域模型及其 Repository 契约（历史目录，保持现状）
  pages/                # 页面和页面专用 UI；profile/、auth/ 为子模块
  main.dart             # 启动初始化、依赖组装、主题、Provider 根节点和导航壳
  router.dart           # GoRouter 路由表、认证重定向和 Shell 路由
test/                   # 与 lib/ 对应的单元测试和 Widget 测试
```

- 按现有目录归属扩展；不要为了重命名或“整洁”迁移已有模块。
- `core` 只能放可被多个功能复用的基础能力，不能依赖 `pages` 或具体 feature。
- `pages` 依赖 Repository 抽象和 DTO/领域对象，不得依赖 `Http*Repository`、Dio 或存储实现。

## 3. 依赖注入与状态

- 根依赖在 `main.dart` 初始化后通过 `MultiProvider` 注入。新增跨页面 Repository 时，在此处以其抽象类型提供：`Provider<FooRepository>.value(...)`。
- 仅需要响应 UI 更新的可变应用状态使用 `ChangeNotifier`，以 `ChangeNotifierProvider.value` 注入，并在状态实际变更后调用 `notifyListeners()`。当前例子：`AuthController`、`EnvConfig`、`AppSettings`。
- 在 widget 中使用 `context.watch<T>()` 订阅并重建；只读取服务、执行命令或在回调中使用 `context.read<T>()`。异步 `await` 后访问 `BuildContext` 前先检查 `context.mounted`（State 内也可使用 `mounted`）。
- 页面内部的短生命周期交互状态保留在 `StatefulWidget` 的 `State` 中。不要为单页表单、加载态等状态新增全局 Provider。
- Repository 通过构造函数传入页面或从 Provider 读取；不要在页面中手动创建 Repository、`ApiClient`、`SharedPreferences` 或 token storage。

## 4. 数据层与 API

- 每个功能以 `abstract class <Feature>Repository` 定义页面可用的契约；实现放在同目录的 `local_*_repository.dart` 与 `http_*_repository.dart`。
- 本地实现用于 `USE_LOCAL_DATA` 默认开发模式；HTTP 实现用于真实 API。新增功能时两种实现都应满足同一接口，切换只在 `main.dart` 组装处发生。
- HTTP 请求一律经 `core/api/ApiClient`，不得在 feature 或 page 中新建 `Dio`。使用 `ApiClient.request<T>`，传入明确的 `parseData`，并让 `ApiException` 传递到 UI 层展示。
- API 根地址来自 `EnvConfig`：默认 `http://localhost:5280`，可由 `--dart-define=API_BASE_URL=...` 覆盖，也可在开发者设置中运行时修改。不要硬编码 API host 或 `/api/v1` 前缀。
- 请求体、查询参数和路径参数使用 camelCase。响应信封固定为 `{Code, Msg, Data}`；DTO 在 `fromJson` 中保留后端 `Data` 的字段大小写，按实际契约读取，不做全局键名转换。
- 已认证请求由 `ApiClient` 统一携带 Bearer token、串行刷新 401 token 并最多重放原请求一次。不要在 Repository 里重复实现拦截、刷新或跳登录。
- HTTP 后端契约以 `docs/BACKEND_DESIGN.md` 第 7 节为唯一来源；客户端映射说明见 `docs/api-integration.md`。不得在客户端臆造路由或字段。

## 5. 认证、存储与配置

- `AuthController` 是登录态的唯一真相来源。登录、注册、登出、bootstrap 和会话过期均通过它处理；路由认证重定向由 `GoRouter.refreshListenable` 监听它完成。
- token 只通过 `TokenStorage` 读写。原生端使用 `SecureTokenStorage`，Web 端使用 `SharedPrefsTokenStorage` 降级；不得直接读写 token 键或将 token 写入日志。
- 非敏感设置使用现有 `AppSettings` / `EnvConfig` 封装的 `SharedPreferences` 实例。新增键使用稳定、带命名空间的键名（例如 `settings.<name>`），异步持久化成功后再通知监听者。
- 改变 API 地址必须沿用开发者设置现有流程，并清除当前会话；不要让旧 token 跨服务器复用。

## 6. 路由与页面

- 在 `router.dart` 集中声明路由。根部五个 tab 属于 `StatefulShellRoute.indexedStack`；同一 tab 的二级页面声明为该分支的嵌套路由。
- 页面切换使用 `context.go()`，进入可返回的详情或创建页使用 `context.push()`。传递路径参数时从 `GoRouterState.pathParameters` 读取并校验。
- 认证页只有 `/login` 与 `/register`；新增受保护页面须受既有 redirect 规则覆盖。不要在页面中复制认证守卫。
- 保持 `MaterialApp.router` 和现有 `NexusMindShell` 底部导航架构；主题仍由 `AppSettings` 和根 `_Root` 统一提供。

## 7. UI 与异步操作

- 使用 Material 3 和当前主题的 `ColorScheme`、`cardColor`、`dividerColor`，支持深浅色模式；避免在普通页面硬编码与主题无关的颜色。
- 交互按钮的异步回调需要防止重复提交，并为加载、空数据和失败提供清晰的 UI 状态。失败信息优先展示 `ApiException.msg`，其他异常使用用户可理解的兜底文案。
- 网络或 Repository 调用不要放进 `build()`。首次加载放在 `initState()`，依赖变更时使用合适的生命周期方法，并在完成后检查 mounted。
- 调试追踪使用 `core/analytics/track.dart` 或 `debugPrint` 并受 `kDebugMode` 限制；不得使用 `print`，不得记录密码、token、完整 API 响应或其他敏感上下文。

## 8. 测试要求

- Repository 的新增或变更行为应在 `test/` 中有针对性单元测试，覆盖成功路径、关键状态变迁、过滤/映射规则和预期失败。
- 页面路由、认证重定向和重要用户流程使用 Widget 测试。依赖采用内存 `TokenStorage`、mock `SharedPreferences` 或本地 Repository，避免真实网络。
- 测试从公开接口观察行为，不测试私有实现细节。测试名称使用行为描述，并保持输入数据确定性。

## 9. 修改检查清单

- 新功能是否同时定义 Repository 抽象，并按需要提供 local 与 HTTP 实现？
- 新 HTTP 映射是否与 `docs/BACKEND_DESIGN.md` 的端点、字段和信封一致？
- 新依赖是否在 `main.dart` 统一组装，页面是否只依赖抽象？
- 所有异步 UI 更新是否在 mounted 检查后执行，所有敏感数据是否避免日志与非安全存储？
- 变更是否通过 `dart format`、`flutter analyze` 以及相关 `flutter test`？
