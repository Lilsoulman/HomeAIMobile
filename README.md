# NexusMind

NexusMind 是 Flutter 多平台个人效率应用，包含首页 Dashboard、待办看板/列表、月视图日历和个人设置。

## 运行

```bash
flutter pub get
flutter run
```

Web 版本：`flutter run -d chrome`

## 验证

```bash
flutter analyze
flutter test
flutter build web
```

入口代码位于 `lib/main.dart`，平台工程位于 `android/`、`ios/`、`web/` 和 `windows/`。待办及日程目前使用内存 mock 数据，后续可替换为 HTTP 或本地持久化仓库。
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

Override the API host at build or run time:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5280
```

The login page's developer settings also allow changing the base URL. Changing
it clears the current session and requires a new login. WeChat exchange and
iCal network fetch remain intentionally gated by the backend with HTTP 501.
