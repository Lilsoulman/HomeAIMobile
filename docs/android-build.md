# Android 普通构建

Android 测试包和生产包均使用标准 Flutter `release` 构建。构建只读取当前本地
工作区，不会自动拉取、切换、提交、推送 Git 或上传第三方服务。

| Git 分支 | Flutter flavor | 包名 | 应用名 | versionName | buildNumber |
| --- | --- | --- | --- | --- | --- |
| `main` | `staging` | `com.homemind.nexusmindtest` | NexusMind Test | 固定 `0.0.0` | UTC 秒数 |
| `release` | `production` | `com.homemind.nexusmind` | NexusMind | 手动输入 `x.y.z` | UTC 秒数 |

buildNumber 是当前 UTC 时间相对 `2020-01-01T00:00:00Z` 的累计秒数，必须位于
Android versionCode 的有效范围内。staging 使用 `config/test.json`，production
使用 `config/production.json`。

## 双击构建

- main 工作区：双击 `build_staging_android.bat`；
- release 工作区：双击 `build_production_android.bat`。

菜单中的 `1` 构建 APK，`2` 构建 AAB。完整日志保存在 `.build-logs/`，成功产物
复制到 `artifacts/<flavor>/<versionName+buildNumber>/`。两个目录均不提交 Git。

构建入口使用 `--no-pub`，避免打包过程隐式改写 lock 和 generated 文件。首次构建或
依赖变化后应先显式运行 `flutter pub get`，审查并提交需要保留的依赖变更，再执行
Android 构建。

staging 允许从有本地修改的工作区构建，但会打印不可追溯警告。production 必须在
干净的 `release` 分支构建。production AAB 必须提供未入库的
`android/key.properties` 和正式 keystore；production APK 未配置正式证书时允许
使用 debug 签名，仅供本地安装测试。

## 完整包更新

每次代码、资源、依赖或原生配置变化都需要重新构建并分发完整 APK/AAB。曾安装
旧版特制 Engine 包的设备可以用版本号更高且签名一致的普通 APK 覆盖；签名不一致
时必须卸载旧应用再安装，这会清除该应用的本地数据。
