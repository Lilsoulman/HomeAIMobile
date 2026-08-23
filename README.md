# NexusMind

NexusMind 是 Flutter 多平台个人效率应用，包含首页 Dashboard、待办看板/列表、月视图日历和个人设置。

## 运行

```bash
flutter pub get
flutter run
```

浏览器调试：`flutter run -d chrome`。使用 VS Code 启动后，保存 Dart 文件会自动热重载；命令行启动时在终端按 `r` 热重载，按 `R` 热重启。上述能力仅适用于 Debug 模式。

## Dart 代码热更新

Android 测试包和生产包的 Dart 代码热更新统一使用 Shorebird。`main` 分支构建
`staging` flavor，`release` 分支构建 `production` flavor。脚本默认完成构建并
上传 Shorebird，只有显式传入 `-DryRun` 才不会上传。底包和 Patch 的边界、
版本规则、命令与验证流程见
[`docs/shorebird-code-push.md`](docs/shorebird-code-push.md)。

Windows 下，main 工作区可直接双击 `build_staging_base.bat` 或
`build_staging_patch.bat`；release 工作区使用对应的 `build_production_base.bat`
或 `build_production_patch.bat`。启动器会显示 DryRun/上传菜单，执行后保持窗口
打开，并将完整成功或失败日志保存到 `.release-logs/`。

## 验证

```bash
flutter analyze
flutter test
flutter build web
```

入口代码位于 `lib/main.dart`，平台工程位于 `android/`、`ios/`、`web/` 和
`windows/`。业务数据统一通过既有 HTTP Repository 和自有后端 API 获取。
## API integration

The mobile client follows the backend contract in
`D:\NexusMind\core\DEVELOPMENT.md` and
`D:\NexusMind\core\docs\api-implementation.md`.

- Base URL: `http://150.158.106.238/api/v1` by default.
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

当前跟踪的默认地址为：

```dotenv
API_BASE_URL=http://150.158.106.238
```

This file is bundled with the application, so it must never contain tokens,
passwords, keys, or other secrets. On an Android device, `localhost` points to
the device itself. Use the backend computer's LAN IP instead; Android emulators
normally use `10.0.2.2`.

构建 flavor 使用对应的 JSON 配置；临时调试也可直接覆盖地址：

```powershell
flutter run --flavor staging --dart-define-from-file=config/test.json
flutter run --flavor staging --dart-define=APP_ENV=test --dart-define=API_BASE_URL=http://192.168.1.10:5280
```

The login page's developer settings also allow changing the base URL. Changing
it clears the current session and requires a new login. WeChat exchange and
iCal network fetch remain intentionally gated by the backend with HTTP 501.
