import AppKit
import SwiftUI

@main
struct InputPilotApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

/// AppKit 生命周期入口。菜单栏工具用 NSApplicationDelegate 更适合控制 Dock 行为。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        AppGuardian.shared.start()

        if SettingsStore.shared.settings.globalInputSourceID == nil {
            SettingsWindowController.shared.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppGuardian.shared.stop()
    }
}
