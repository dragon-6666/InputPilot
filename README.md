# InputPilot

InputPilot 是一个面向 Apple Silicon Mac 的原生菜单栏工具，用于监控并自动恢复你习惯使用的输入法，避免系统意外切回 ABC 后造成误输入。

## 功能

- 全局输入法守护：窗口/应用切换后自动检查并切回预设输入法。
- 应用级规则：为指定 App 设置独立输入法，优先级高于全局规则。
- 菜单栏常驻：不占 Dock，支持快速启停守护与打开设置。
- 开机启动：基于 macOS `SMAppService`。
- 悬浮提示：支持固定位置与焦点跟随展示当前输入法。
- 原生实现：Swift 6 + SwiftUI + AppKit，最低支持 macOS 13。

## Bundle ID

正式第三方分发默认使用：

```text
com.wwl.inputpilot
```

如果后续有公司或个人域名，建议改成自己的反域名格式，例如 `com.yourdomain.inputpilot`，发布后不要频繁变更，否则辅助功能权限可能需要重新授权。

## 权限说明

焦点跟随模式需要辅助功能权限。首次使用时可在「设置 - 权限」中点击请求授权，然后在系统设置中允许 InputPilot。

开发测试包如果使用 ad-hoc 签名，覆盖安装后 macOS 可能重新要求辅助功能授权。正式发布请使用固定 Developer ID Application 证书签名并公证。

## 本地开发

```bash
cd InputPilot
swift run
```

## 本地打包

生成测试 `.dmg`：

```bash
./scripts/create_dmg.sh
```

未设置 `DEVELOPER_ID_APPLICATION` 时会使用 ad-hoc 签名，仅适合本地测试。

## GitHub 免费发布模式

当前项目默认使用免费分发模式：

```text
ad-hoc 签名 + DMG + GitHub Release
```

不需要 Apple Developer 账号，也不需要 Developer ID 和公证。缺点是用户首次打开时 macOS 会提示安全拦截。

用户安装后如果打不开，可以这样操作：

```text
右键 InputPilot.app → 打开 → 再点“打开”
```

或者：

```text
系统设置 → 隐私与安全性 → 仍要打开
```

> 注意：免费分发包因为没有固定 Developer ID 签名，覆盖安装后辅助功能权限可能需要重新授权，这是 macOS 的安全机制。

## GitHub Release

推送 tag 即可发布 DMG：

```bash
git tag v0.1.0
git push origin v0.1.0
```

GitHub Actions 会自动：

1. 构建 Apple Silicon 版本。
2. 使用 ad-hoc 签名。
3. 生成 `InputPilot.dmg`。
4. 上传到 GitHub Release。

## 可选：未来正式签名

如果以后要改善安装体验，可以再接入 Apple Developer ID：

```bash
export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
./scripts/create_dmg.sh

export NOTARY_KEY_ID="YOUR_KEY_ID"
export NOTARY_ISSUER_ID="YOUR_ISSUER_ID"
export NOTARY_KEY_PATH="/path/to/AuthKey_XXXXXX.p8"
./scripts/notarize_dmg.sh dist/InputPilot.dmg
```

## 项目结构

```text
Sources/InputPilot
├── App        # AppKit 生命周期、菜单栏、窗口、悬浮框
├── Core       # 预留核心能力目录
├── Models     # 设置、输入法、应用规则模型
├── Services   # 输入法、权限、守护、设置存储服务
├── Views      # SwiftUI 设置页面
└── Packaging  # Info.plist 与发布配置
```

## License

MIT
