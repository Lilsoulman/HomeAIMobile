# Shorebird Android Dart 代码热更新

## 分支、应用与版本

正式分发的 Android 测试包和生产包都由 Shorebird 构建。普通 `flutter build`
产物不具备接收 Shorebird Patch 的能力。

| Git 分支 | Flutter flavor | 包名 | 应用名 | versionName | buildNumber |
| --- | --- | --- | --- | --- | --- |
| `test` | `staging` | `com.homemind.nexusmindtest` | NexusMind Test | 永远 `0.0.0` | 自动时间戳 |
| `release` | `production` | `com.homemind.nexusmind` | NexusMind | 手动输入 `x.y.z` | 自动时间戳 |

Android Gradle Plugin 禁止 flavor 名以 `test` 开头，因此内部 flavor 使用
`staging`，但 Git 分支和编译环境仍叫 `test`。`main` 保留用于日常集成，但不
允许执行发布脚本。

buildNumber 使用“当前 UTC 时间减去 `2020-01-01T00:00:00Z` 的累计秒数”。
脚本还会查询 Shorebird 上该 flavor 的 Android Releases；如果时间戳没有超过
已有最大 buildNumber，则改用“最大值 + 1”。Android 上限校验为
`1..2100000000`。

例如 test 用户看到的版本始终是 `0.0.0`，但两个底包在 Android 和 Shorebird
内部可分别标识为 `0.0.0+209000123`、`0.0.0+209010456`。release 发布人只输入
`1.2.0`，脚本自动形成类似 `1.2.0+209020789` 的完整版本。

## 构建来源与自动上传

两个脚本都从当前本地检出的 Git 分支和工作区构建，不会自动 fetch、pull、
checkout、commit 或 push。正式上传要求工作区干净，因此发布源码等于当前
`HEAD`；Git Commit 只用于发布追溯，不参与 buildNumber 计算。

脚本默认直接构建并上传 Shorebird。只有显式传入 `-DryRun` 才只验证、不上传。
若 Windows 默认策略禁止执行本地脚本，只为当前终端临时放行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

关闭终端后该设置自动失效。

## 发布新底包

test 分支：

```powershell
# 构建 APK 并直接上传 Shorebird
.\scripts\build_android_base.ps1 -Artifact apk

# 只构建验证，不上传
.\scripts\build_android_base.ps1 -Artifact apk -DryRun
```

release 分支：

```powershell
# versionName 由发布人确定，buildNumber 自动生成
.\scripts\build_android_base.ps1 -Artifact apk -ReleaseVersion 1.2.0
.\scripts\build_android_base.ps1 -Artifact aab -ReleaseVersion 1.2.0

# 只验证
.\scripts\build_android_base.ps1 -Artifact apk -ReleaseVersion 1.2.0 -DryRun
```

production APK 在未配置正式证书时允许使用 debug 签名，仅供本地安装测试。
production AAB 无论上传还是 DryRun 都要求存在未入库的
`android/key.properties` 和正式 keystore，否则脚本立即失败。

正式上传前，脚本把完整版本、分支、源码 Commit、配置哈希和 Artifact 类型写入
`.release-state/<flavor>.pending.json`。相同源码、配置和版本重试时复用原来的
buildNumber；如果远端 Release 已存在，则只补全本地状态，不重复上传。成功后：

- 状态保存为 `.release-state/<flavor>.json`；
- pending 文件删除；
- APK/AAB 复制到 `artifacts/<flavor>/<完整版本>/`。

`.release-state/` 和 `artifacts/` 均被 Git 忽略。

## 发布 Dart Patch

从已发布底包之后提交只涉及 Dart 的修改，然后执行：

```powershell
# 构建并直接上传，发布到 stable track
.\scripts\build_android_patch.ps1

# 只验证，不上传
.\scripts\build_android_patch.ps1 -DryRun
```

Patch 脚本必须读取 `.release-state/<flavor>.json`，并使用底包保存的完整版本、
versionName 和 buildNumber。它不会根据 Patch 构建时间或 Git Commit 生成新的
buildNumber；Shorebird 会在目标底包下自动生成 patchNumber。

Patch 上传前写入 `.release-state/<flavor>.patch.pending.json`。上传中断后，相同
源码重试会先查询 Shorebird：如果已经出现更大的 patchNumber，则只完成本地
记录，不重复上传。成功记录保存在 `.release-state/<flavor>.patches.json`，包含：

- 目标底包完整版本和 base Git Commit；
- Patch Git Commit；
- Shorebird patchNumber 和 track；
- flavor、配置哈希和发布时间。

## 可热更新边界

适合 Patch：

- Dart 业务逻辑、状态管理、页面交互和由 Dart 生成的代码；
- 不包含原生实现的纯 Dart 依赖代码。

必须发布新底包：

- Android/iOS 等平台工程、权限、签名、包名、图标和启动图；
- 新增、删除或升级依赖及含原生实现的 Flutter Plugin；
- 图片、字体、`env/`、`config/` 等配置和 Flutter Asset；
- Flutter Engine、Flutter SDK、构建配置和 Shorebird 配置。

脚本会先检查从 base Commit 到当前 `HEAD` 的变更范围；不得使用允许原生或 Asset
差异的参数绕过检查。当前保持 Shorebird 默认自动更新：应用启动后后台检查和
下载 Patch，并在下一次启动时生效。

## 使用流程

1. 切换到目标分支，完成代码提交并保证工作区干净。
2. 修改到底包范围时运行 `build_android_base.ps1`，命令直接上传 Release。
3. 只修改可热更 Dart 代码时运行 `build_android_patch.ps1`，命令直接上传 Patch。
4. test 用户安装新的底包 APK；Patch 上传后打开应用等待下载，再完全退出并重启。
5. 核对登录、会话恢复、首页和本次修改，并在 Shorebird Console 核对完整 Release
   版本、patchNumber 和安装情况。

新底包不会通过 Shorebird 自动替换用户已安装的旧底包，仍需重新分发 APK/AAB。
首个正式生产底包发布前启用 Patch Signing；私钥只能放在本地安全存储或受控
Secret 中，不得提交到 Git。
