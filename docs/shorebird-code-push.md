# Shorebird Android Dart 代码热更新

## 发布模型

正式分发的 Android 测试包和生产包都由 Shorebird 构建。普通 `flutter build`
产物不具备接收 Shorebird Patch 的能力。

| Git 分支 | Flutter flavor | 包名 | 应用名 | 版本规则 | 配置 |
| --- | --- | --- | --- | --- | --- |
| `test` | `staging` | `com.homemind.nexusmindtest` | NexusMind Test | `0.0.0+Git提交总数` | `config/test.json` |
| `release` | `production` | `com.homemind.nexusmind` | NexusMind | 手动输入 `x.y.z+N` | `config/production.json` |

Android Gradle Plugin 禁止 flavor 名以 `test` 开头，因此内部 flavor 使用
`staging`，但 Git 分支和编译环境仍叫 `test`。`main` 保留用于日常集成，但不
允许执行发布脚本。test 的 buildNumber 使用
`git rev-list --count HEAD`，因此构建仓库必须包含完整 Git 历史，不能使用
shallow clone。release 的完整版本号由发布人输入，`N` 必须是正整数。

`APP_ENV` 在编译期写入；应用启动时会校验它与原生 flavor 是否一致。当前两套
配置都连接 `http://150.158.106.238`。HTTP 明文仅作为当前阶段的已知技术债，
正式面向公网发布前应迁移到 HTTPS。

## 自动化脚本

脚本均为本地 PowerShell 文件，默认只执行 Shorebird dry-run，不会在云端创建
Release 或 Patch。只有显式传入 `-Publish` 才会上传。

若 Windows 默认策略禁止执行本地脚本，只为当前终端临时放行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

关闭该终端后设置自动失效，不需要修改全局执行策略。

test 分支构建 APK：

```powershell
.\scripts\build_android_base.ps1 -Artifact apk
.\scripts\build_android_base.ps1 -Artifact apk -Publish
```

release 分支构建本地测试 APK 或正式 AAB：

```powershell
.\scripts\build_android_base.ps1 -Artifact apk -ReleaseVersion 1.0.0+1
.\scripts\build_android_base.ps1 -Artifact aab -ReleaseVersion 1.0.0+1 -Publish
```

production APK 在未配置正式证书时允许使用 debug 签名，仅供本地安装测试。
production AAB 无论 dry-run 还是上传，都要求存在未入库的
`android/key.properties` 和正式 keystore，否则脚本立即失败。

底包真正上传成功后，脚本将版本、flavor、源码提交和配置哈希保存到忽略目录
`.release-state/<flavor>.json`。构建产物复制到忽略目录
`artifacts/<flavor>/<完整版本>/`。

## 发布 Dart Patch

从已发布底包之后提交可热更新的 Dart 修改，完成验证和提交后执行：

```powershell
.\scripts\build_android_patch.ps1
.\scripts\build_android_patch.ps1 -Publish
```

脚本默认读取 `.release-state/<flavor>.json`，确保 Patch 使用底包发布时保存的
完整版本号。不能用当前 Git 提交数重新计算 Patch 目标版本。状态文件丢失时，可
明确指定已存在的 Shorebird Release：

```powershell
.\scripts\build_android_patch.ps1 -ReleaseVersion 0.0.0+123
.\scripts\build_android_patch.ps1 -ReleaseVersion 1.0.0+7 -Publish
```

正式上传底包或 Patch 时 Git 工作区必须干净。Patch 脚本会根据底包提交检查
变更范围；发现平台工程、Plugin 锁定、Shorebird 配置或 Asset 变更时会要求
重新发布底包，Shorebird 自身还会执行最终兼容性检查。

## 可热更新边界

适合 Patch：

- Dart 业务逻辑、状态管理、页面交互和由 Dart 生成的代码；
- 不包含原生实现的纯 Dart 依赖代码。

必须发布新底包：

- Android/iOS 等平台工程、权限、签名、包名、图标和启动图；
- 新增、删除或升级含原生实现的 Flutter Plugin；
- 图片、字体、`env/.env` 等 Flutter Asset；
- Flutter Engine、Flutter SDK、构建配置和 Shorebird 配置。

不得使用允许原生或 Asset 差异的参数绕过检查。当前保持 Shorebird 默认自动
更新：应用启动后后台检查和下载 Patch，并在下一次启动时生效；未引入
`shorebird_code_push`，也没有应用内手动更新 UI。

## 首次发布与验证

1. 在目标分支运行底包脚本（不带 `-Publish`），确认 dry-run 成功。
2. 运行同一命令并增加 `-Publish`，上传 Release 后安装生成的 APK。
3. 修改并提交可热更新 Dart 代码，先运行 Patch dry-run，再以 `-Publish` 上传。
4. 打开底包一次，等待后台下载；完全退出再启动，确认改动生效。
5. 验证登录、会话恢复、首页和本次修复流程，并在 Shorebird Console 核对目标
   Release、Patch 与安装情况。

首个正式生产底包发布前启用 Patch Signing。私钥只能放在本地安全存储或受控
Secret 中，不得提交到 Git。
