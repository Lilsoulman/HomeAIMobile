# NexusMind

NexusMind 是 Flutter 多平台个人效率应用，包含首页 Dashboard、待办看板/列表、月视图日历和个人设置。

## 运行

```bash
flutter pub get
flutter run
```

浏览器调试：`flutter run -d chrome`。使用 VS Code 启动后，保存 Dart 文件会自动热重载；命令行启动时在终端按 `r` 热重载，按 `R` 热重启。上述能力仅适用于 Debug 模式。

## Dart 代码热更新

正式应用的 Dart 代码热更新使用 Shorebird。项目保持自动更新模式，不包含图片、
配置或其他资源热更新。底包和 Patch 的边界、命令与验证流程见
[`docs/shorebird-code-push.md`](docs/shorebird-code-push.md)。

## 验证

```bash
flutter analyze
flutter test
flutter build web
```

入口代码位于 `lib/main.dart`，平台工程位于 `android/`、`ios/`、`web/` 和 `windows/`。待办、日程、智能家居与专家文件默认使用本地仓库；以 `--dart-define=USE_LOCAL_DATA=false` 运行时，已接入的 Todo、Calendar、SmartHome 与专家文件能力会切换到对应的 HTTP 仓库。
## API integration

The mobile client follows the backend contract in
`D:\NexusMind\core\DEVELOPMENT.md` and
`D:\NexusMind\core\docs\api-implementation.md`.

- Base URL: `http://localhost:5280/api/v1` by default.
- Request bodies and query parameters use camelCase.
- The response envelope is `Code`, `Msg`, `Data`; business fields follow the
  backend PascalCase contract.
- Authenticated calls send `Authorization: Bearer <accessToken>`. Access token
  refresh is serialized and the original request is retried once after 401.
- A stable installation id is generated and sent on register/login.

## Environment configuration

Edit `env/.env`, then launch normally:

```bash
flutter run
```

The tracked development default enables HTTP repositories:

```dotenv
USE_LOCAL_DATA=false
API_BASE_URL=http://localhost:5280
```

This file is bundled with the application, so it must never contain tokens,
passwords, keys, or other secrets. On an Android device, `localhost` points to
the device itself. Use the backend computer's LAN IP instead; Android emulators
normally use `10.0.2.2`.

CI and temporary debugging can still override `env/.env` with `dart-define`:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5280 --dart-define=USE_LOCAL_DATA=false
```

The login page's developer settings also allow changing the base URL. Changing
it clears the current session and requires a new login. WeChat exchange and
iCal network fetch remain intentionally gated by the backend with HTTP 501.
