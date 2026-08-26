# HomeMind 移动端开发规范

## 适用范围与架构

项目使用 Flutter Material 3、Dart `^3.12.2`、Provider、GoRouter、Dio 以及既有安全存储和本地存储抽象。必须遵循既有职责划分：`core/` 存放共享基础设施，`features/<feature>/` 存放契约与数据实现，`pages/` 存放界面，`main.dart` 负责依赖装配。不得引入竞争性的状态管理、路由、网络或持久化框架。

页面只能依赖 Repository 抽象和 DTO；Repository 负责 API 与存储细节。新的跨页面依赖必须在 `main.dart` 中通过 `MultiProvider` 注入；页面不得自行创建客户端、Repository 或偏好设置实例。

## Dart 代码规范

- 类型使用 `UpperCamelCase`，变量、参数、函数和常量使用 `lowerCamelCase`；文件、目录和导入前缀使用 `lowercase_with_underscores`。
- `import` 按 `dart:`、`package:`、相对项目路径顺序分组，`export` 位于全部 import 后。
- 提交前运行 `dart format`；除长 URL 或 import/export 外，代码行避免超过 80 字符。
- `if`、`for`、`while` 等控制流必须使用花括号；只有无 `else` 且可完整写为一行的提前返回可省略。

## 状态、路由与异步工作

- `ChangeNotifier` 只用于需要响应式刷新的跨页面状态；页面局部交互使用 `StatefulWidget`。
- `context.watch<T>()` 用于响应式读取，`context.read<T>()` 用于命令；每次 `await` 后、更新 UI 前必须检查 `mounted`。
- 首次 Repository 请求在 `initState` 发起；异步界面提供 loading、empty、error、retry 和无权限状态。命令执行中必须防止重复提交。
- 路由只能在 `router.dart` 声明。Tab 切换使用 `go`；可关闭详情页或创建流程使用 `push`。

## 数据与安全

- 以运行中的 Swagger、`../../core/docs/api-integration.md` 和相关 Controller DTO 为 API 契约。请求使用 camelCase，DTO 的 `fromJson` 必须显式保留响应实际 PascalCase。
- 后端未发布 Household State、Trust、场景生命周期/执行、个人偏好或语音契约时，不得以本地数据或猜测替代；入口保持受控隐藏。
- HTTP 请求必须经由 `ApiClient`，先定义 Repository 接口再提供实现。Token 使用 `TokenStorage`；非敏感配置使用 `AppSettings` 或 `EnvConfig`。
- `env/.env` 只能含 `API_BASE_URL`、`USE_LOCAL_DATA` 等开发配置，不能包含 Token、密码、密钥或第三方 Endpoint。
- 不得记录或展示密码、Token、HA URL、HA 实体 ID、Prompt、模型推理、原始设备/Provider 数据或完整 API 响应。

## Android 构建与发布

- Android 测试包和生产包统一使用标准 Flutter Engine 构建完整 APK/AAB。
  `main` 分支只能构建 `staging` flavor（编译环境仍为 `APP_ENV=test`），
  `release` 分支只能构建 `production` flavor；具体流程见 `docs/android-build.md`。
- staging 的用户版本固定为 `0.0.0`，production 用户版本 `x.y.z` 由发布人输入；
  两者 buildNumber 均使用 UTC 2020-01-01 起累计秒数，Git 不参与编号计算。
- 构建入口不上传第三方服务，并使用 `--no-pub` 避免打包过程改写依赖文件。
  production 必须从干净的 `release` 工作区构建；staging 有本地修改时必须显示
  不可追溯警告。
- 代码、依赖、原生工程、Flutter SDK、图片、字体和配置变化均通过新的完整包分发。
- production AAB 必须使用未入库的正式签名；本地 production APK 可使用 debug
  签名测试。私钥只允许存放于本地安全位置、CI Secret 或 KMS，不得提交仓库。

## UI 实现

遵循 `docs/UI_STYLE_GUIDE.md`，并使用 `core/ui` 中既有的 `NexusTheme`、`NexusLayout` 与 `NexusSurface`。组件样式必须来自当前 `ColorScheme`；功能页面不得创建新的视觉 Token。

App 只实现首页、场景、设备、我的四个 Tab 和全局语音入口中的产品能力；财务、缴费、快递、宠物、日程、出游、专家/Skill 等已砍领域不得新增、修改或恢复。所有新界面必须支持浅色、深色主题和紧凑移动端宽度。

## 质量门槛

交付前必须运行 `dart format lib test`、`flutter analyze` 和相关 `flutter test`。新增或修改 Repository 时，必须补充聚焦于映射和错误行为的测试；面向用户的新路由或关键场景流程必须补充 Widget 测试。
