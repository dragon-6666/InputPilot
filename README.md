# InputPilot

InputPilot 是一个 macOS 菜单栏小工具，用来自动守护你常用的输入法，避免系统意外切回 ABC 后造成误输入。

## 主要功能

- 全局输入法守护：切换窗口或应用后自动恢复指定输入法。
- 应用级规则：可为不同 App 设置不同输入法。
- 菜单栏常驻：不占 Dock，支持快速启停守护。
- 开机启动：登录后自动运行。
- 悬浮提示：可在固定位置或输入焦点附近显示当前输入法状态。
- Apple Silicon 原生支持，最低支持 macOS 13。

## 下载安装

前往 GitHub Releases 下载最新的 `InputPilot.dmg`：

[下载 InputPilot](https://github.com/dragon-6666/InputPilot/releases)

安装方式：

1. 打开 `InputPilot.dmg`。
2. 将 `InputPilot.app` 拖入 `Applications`。
3. 从「应用程序」中启动 InputPilot。

## 首次打开提示

当前版本是免费开源分发包，没有使用 Apple Developer ID 公证。首次打开时，macOS 可能会提示无法验证开发者。

可以这样打开：

```text
右键 InputPilot.app → 打开 → 再点“打开”
```

如果仍被拦截：

```text
系统设置 → 隐私与安全性 → 仍要打开
```

## 权限说明

InputPilot 的「焦点跟随」悬浮提示需要辅助功能权限，用于获取当前输入框或光标位置。

授权路径：

```text
系统设置 → 隐私与安全性 → 辅助功能 → 打开 InputPilot
```

InputPilot 不读取、不保存你的输入内容。

> 免费分发包覆盖安装后，macOS 可能要求重新授权辅助功能权限，这是系统安全机制导致的。

## 使用说明

1. 点击菜单栏 InputPilot 图标。
2. 打开设置。
3. 在「基础设置」里选择全局默认输入法。
4. 如需针对某个 App 单独设置，进入「应用规则」添加规则。
5. 如需显示输入法提示，进入「悬浮提示」调整样式和消失时间。


## 截图预览

<p align="center">
  <img src="docs/images/settings-basic.png" width="720" alt="基础设置" />
</p>

<p align="center">
  <img src="docs/images/settings-rules.png" width="720" alt="应用规则" />
</p>

<p align="center">
  <img src="docs/images/floating-focus.png" width="420" alt="悬浮提示" />
</p>

<p align="center">
  <img src="docs/images/menubar.png" width="360" alt="菜单栏" />
</p>

## License

MIT
