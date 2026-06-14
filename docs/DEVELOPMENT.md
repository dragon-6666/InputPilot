# InputPilot Development

本文档面向开发者，普通用户无需阅读。

## Bundle ID

当前默认 Bundle ID：

```text
com.wwl.inputpilot
```

如果用于正式分发，建议改成自己的反域名格式，例如：

```text
com.yourdomain.inputpilot
```

发布后不要频繁变更 Bundle ID，否则 macOS 可能要求用户重新授予辅助功能权限。

## 本地开发

```bash
swift run
```

## 本地打包

```bash
./scripts/create_dmg.sh
```

未设置 `DEVELOPER_ID_APPLICATION` 时会使用 ad-hoc 签名，适合免费开源分发和本地测试。

## GitHub 免费发布模式

当前 GitHub Actions 默认使用：

```text
ad-hoc 签名 + DMG + GitHub Release
```

推送 tag 即可发布：

```bash
git tag v1.0.1
git push origin v1.0.1
```

## 可选：Developer ID 签名与公证

如果后续需要更好的安装体验，可以使用 Apple Developer ID：

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
├── Models     # 设置、输入法、应用规则模型
├── Services   # 输入法、权限、守护、设置存储服务
└── Views      # SwiftUI 设置页面
```
