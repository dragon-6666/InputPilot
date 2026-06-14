import AppKit
import Combine

/// 输入法守护核心：根据当前激活应用计算目标输入法，并执行快速切换。
@MainActor
final class AppGuardian: ObservableObject {
    static let shared = AppGuardian()

    @Published private(set) var currentInputSourceName: String = "未知输入法"
    @Published private(set) var currentAppName: String = ""

    private let inputManager = InputSourceManager.shared
    private let settingsStore = SettingsStore.shared
    private let floatingWindow = FloatingWindowController.shared
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var lastFocusSignature: String?

    private init() {}

    func start() {
        observeWorkspace()
        settingsStore.$settings
            .sink { [weak self] _ in self?.enforce(reason: "settings") }
            .store(in: &cancellables)

        timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.enforce(reason: "poll") }
        }
        enforce(reason: "start")
    }

    func stop() {
        cancellables.removeAll()
        timer?.invalidate()
        timer = nil
    }

    func enforce(reason: String) {
        let settings = settingsStore.settings
        guard settings.guardianEnabled else {
            updateFloatingOnly(settings: settings)
            return
        }

        let activeApp = NSWorkspace.shared.frontmostApplication
        currentAppName = activeApp?.localizedName ?? ""
        let target = targetInputSource(for: activeApp, settings: settings)

        let focusSignature = settings.floatingDisplayMode == .focusFollow ? AccessibilityService.shared.focusedElementSignature() : nil
        var shouldShowFloating = reason != "poll"
        if let current = inputManager.currentInputSource() {
            let previousName = currentInputSourceName
            currentInputSourceName = current.displayName
            if let target, current.id != target.id, inputManager.selectInputSource(id: target.id) {
                currentInputSourceName = target.displayName
                shouldShowFloating = true
            }
            if previousName != currentInputSourceName {
                shouldShowFloating = true
            }
        }

        if reason == "poll", let focusSignature, focusSignature != lastFocusSignature {
            shouldShowFloating = true
        }
        if let focusSignature {
            lastFocusSignature = focusSignature
        }

        if shouldShowFloating {
            showFloating(settings: settings)
        }
    }

    private func targetInputSource(for app: NSRunningApplication?, settings: AppSettings) -> InputSource? {
        if let bundleID = app?.bundleIdentifier,
           let rule = settings.appRules.first(where: { $0.bundleIdentifier == bundleID && $0.isEnabled }) {
            return InputSource(id: rule.inputSourceID, localizedName: rule.inputSourceName, category: "")
        }

        guard let id = settings.globalInputSourceID else { return nil }
        return InputSource(id: id, localizedName: settings.globalInputSourceName ?? id, category: "")
    }

    private func observeWorkspace() {
        let center = NSWorkspace.shared.notificationCenter
        center.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { [weak self] _ in self?.enforce(reason: "activate") }
            .store(in: &cancellables)
    }

    private func updateFloatingOnly(settings: AppSettings) {
        if let current = inputManager.currentInputSource() {
            currentInputSourceName = current.displayName
        }
        showFloating(settings: settings)
    }

    private func showFloating(settings: AppSettings) {
        guard settings.floatingEnabled else {
            floatingWindow.hide()
            return
        }

        let fallbackPoint = CGPoint(x: settings.floatingX, y: settings.floatingY)
        var displayPoint = fallbackPoint

        let badgeSize = floatingWindow.fittingSize(for: settings, text: currentInputSourceName)
        if settings.floatingDisplayMode == .focusFollow,
           let focusPoint = AccessibilityService.shared.focusedBadgeOrigin(badgeSize: badgeSize, offsetY: settings.floatingOffsetY) {
            displayPoint = focusPoint
        }

        floatingWindow.show(text: currentInputSourceName, at: displayPoint, settings: settings)
    }
}
