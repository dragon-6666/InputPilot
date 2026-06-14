import AppKit
import Combine

/// 菜单栏入口，提供常用操作，详细配置放到设置窗口。
@MainActor
final class StatusBarController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let guardian = AppGuardian.shared
    private let settingsStore = SettingsStore.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        configureMenuBarIcon()
        rebuildMenu()

        guardian.$currentInputSourceName
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)

        settingsStore.$settings
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)
    }

    private func configureMenuBarIcon() {
        guard let button = statusItem.button else { return }
        if let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "InputPilot") {
            image.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
        } else {
            button.title = "拼"
        }
        button.toolTip = "InputPilot"
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "当前输入法：\(guardian.currentInputSourceName)", action: nil, keyEquivalent: "")
        menu.addItem(.separator())

        let toggleTitle = settingsStore.settings.guardianEnabled ? "暂停守护" : "启用守护"
        menu.addItem(NSMenuItem(title: toggleTitle, action: #selector(toggleGuardian), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "打开设置…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出 InputPilot", action: #selector(quit), keyEquivalent: "q"))

        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    @objc private func toggleGuardian() {
        settingsStore.settings.guardianEnabled.toggle()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
