# NexusMind 开发规范

## 适用范围与架构

项目使用 Flutter Material 3、Dart `^3.12.2`、Provider、GoRouter、Dio
以及既有的安全存储和本地存储抽象。必须遵循既有职责划分：`core/`
存放共享基础设施，`features/<feature>/` 存放契约与数据实现，`pages/`
存放界面，`main.dart` 负责依赖装配。不得引入与现有状态管理、路由、
网络或持久化方案竞争的框架。

页面只能依赖 Repository 抽象和 DTO。Repository 负责 API 与存储细节。
新的跨页面依赖必须在 `main.dart` 中通过 `MultiProvider` 注入；页面不得
自行创建客户端、Repository 或偏好设置实例。

## Dart 代码规范

本节规范适用于所有新增或修改的 Dart 代码，且优先于默认代码风格。

### 命名

- 类型名称，包括类、枚举和类型定义，必须使用 `UpperCamelCase`。超过
  两个字母的缩写视为普通单词：使用 `HttpRequest`，不使用 `HTTPRequest`。
- 变量、参数、函数和常量必须使用 `lowerCamelCase`。常量不得使用
  `SCREAMING_CAPS`；使用 `defaultTimeout`，不使用 `DEFAULT_TIMEOUT`。
- 不得使用匈牙利命名前缀，例如不得以 `k` 表示常量或以 `b` 表示布尔值。
- 文件名、目录名和导入前缀必须使用 `lowercase_with_underscores`，例如
  `file_system.dart` 和 `dart:math as math`。

### 导入与导出

文件头部的 `import` 与 `export` 必须按以下顺序排列，各组之间留一个空行：

1. `dart:` 核心库。
2. `package:` 第三方库。
3. 相对路径的项目文件。
4. `export` 语句，且必须位于全部 `import` 之后。

### 格式与控制流

- 提交前必须执行 `dart format`，代码应等效于已通过 `dart format` 格式化的结果。
- 除长 URL 或文件路径形式的 `import`、`export` 语句外，代码行应避免超过
  80 个字符。
- `if`、`for`、`while` 等控制流即使只有一行语句也必须使用花括号。
  唯一例外是没有 `else` 分支且可完整写在一行内的 `if`，例如：
  `if (arg == null) return defaultValue;`。

## 状态、路由与异步工作

- `ChangeNotifier` 仅用于需要响应式刷新的应用状态。页面局部交互状态使用
  `StatefulWidget` 管理。
- 响应式读取使用 `context.watch<T>()`，命令和一次性读取使用
  `context.read<T>()`。每次 `await` 后、更新界面前必须检查 `mounted`。
- 首次 Repository 请求在 `initState` 发起；异步界面必须提供加载、空状态和
  错误状态。命令执行中必须防止重复提交。
- 路由只能在 `router.dart` 中声明。Tab 切换使用 `go`；可关闭的详情页或创建
  流程使用 `push`。

## 数据与安全

- 先定义 Repository 接口，再提供本地或 HTTP 实现。HTTP 请求必须经由
  `ApiClient` 发出，并使用显式解析器。
- 以 `docs/BACKEND_DESIGN.md` 为 API 契约。DTO 的 `fromJson` 映射必须保留
  响应字段的原始大小写。
- Token 使用 `TokenStorage` 存储；非敏感配置使用 `AppSettings` 或
  `EnvConfig`。不得记录密码、Token 或完整 API 响应。
- 默认启动配置存放于 `env/.env`，可以定义 `API_BASE_URL` 与
  `USE_LOCAL_DATA`，但不得包含 Token、密码、密钥或其他敏感信息。CI 或
  临时运行可通过 `dart-define` 覆盖这些值。

## UI 实现

遵循 `docs/UI_STYLE_GUIDE.md`，并使用 `core/ui` 中的 `NexusTheme`、
`NexusLayout` 与 `NexusSurface`。组件样式必须来自当前 `ColorScheme`；
功能页面不得创建新的视觉 Token。所有新界面必须同时支持浅色、深色主题和
紧凑移动端宽度。

## 质量门槛

交付前必须运行 `dart format`、`flutter analyze` 和相关的 `flutter test`。
新增或修改 Repository 时，必须补充聚焦于映射与错误行为的测试；面向用户的
新路由或关键流程必须补充 Widget 测试。
