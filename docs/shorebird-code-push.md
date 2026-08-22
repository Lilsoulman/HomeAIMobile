# Shorebird Dart 代码热更新

## 当前接入

- Shorebird 应用配置位于仓库根目录的 `shorebird.yaml`。
- `pubspec.yaml` 将该文件打入应用资产，供 Shorebird Updater 识别应用。
- 当前保持 `auto_update` 默认值。应用启动时在后台检查并下载补丁，补丁在
  下一次启动时生效。
- 不引入 `shorebird_code_push`，不提供应用内手动检查、下载或安装界面。
- 本阶段不处理图片、配置或其他资源的远端更新。
- Android 发布基线固定为 Flutter 3.47.1；本机需安装 Android
  command-line tools、接受 SDK licenses，并保证 `flutter` 可由 `PATH` 找到。
- `file_picker` 固定在兼容现有实例 API 的 10.3.10，以使用 Flutter 工程的
  `compileSdkVersion`；升级到 11.x 前必须先处理其静态 API 破坏性变更。

## 可热更新边界

适合使用 Shorebird Patch 的变更：

- Dart 业务逻辑、状态管理和页面交互；
- 由 Dart 生成的代码；
- 不包含原生实现的纯 Dart 依赖变更。

必须发布新底包的变更：

- Android、iOS 等平台工程和原生代码；
- 新增、删除或升级含原生实现的 Flutter Plugin；
- 图片、字体、`env/.env` 等 Flutter Asset；
- Flutter Engine、Flutter SDK 或构建配置变更；
- 权限、签名、包名、应用图标和启动图变更。

不得使用 `--allow-native-diffs` 或 `--allow-asset-diffs` 绕过检查。检测到
原生或资源差异时，应提升版本号并重新发布底包。

## 首个底包

用户只有安装 Shorebird 构建的底包后，才能接收对应版本的 Patch。普通
`flutter build` 产物不能作为该版本的 Shorebird 底包。

发布前先验证，不上传：

```powershell
shorebird release android --artifact=aab --flutter-version=3.47.1 --dry-run
```

当前工程已用该命令通过 AAB 构建验证；dry-run 不会创建或上传 Release。

正式生成并上传 Release：

```powershell
shorebird release android --artifact=aab --flutter-version=3.47.1
```

将该命令生成的 AAB 提交到应用商店。`pubspec.yaml` 中的 `version` 必须与商店
版本一致。测试 APK 可将 `--artifact=aab` 改为 `--artifact=apk`，但不能拿普通
Flutter APK 验证 Patch。

## 发布 Dart Patch

1. 从已发布底包对应的源码提交开始修改，只提交可热更新范围内的 Dart 变更。
2. 执行格式化、静态分析和相关测试。
3. 对目标 Release 做不上传验证：

```powershell
shorebird patch android --release-version=1.0.0 --dry-run
```

4. 验证通过后正式上传：

```powershell
shorebird patch android --release-version=1.0.0
```

将示例版本 `1.0.0` 替换为目标底包的实际版本。Release 和 Patch 必须使用一致的
`--flavor`、`--target`、`--dart-define` 与混淆参数；不能依赖未记录的本机环境。

## 验证标准

- Shorebird Release 安装到 Android 真机或模拟器；
- 启动一次并记录底包行为；
- 上传 Patch 后再次启动，让补丁在后台下载；
- 完全退出并重新启动，确认 Dart 改动生效；
- 验证登录、会话恢复、首页和本次修复对应流程；
- 在 Shorebird Console 确认目标 Release、Patch 和安装情况。

在首个正式底包发布前配置 Patch Signing。私钥只能保存在本地安全存储、CI
Secret 或 KMS，不得写入仓库；底包只携带用于验签的公钥。
