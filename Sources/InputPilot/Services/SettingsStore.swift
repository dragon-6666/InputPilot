import Combine
import Foundation
import ServiceManagement

/// 用户设置存储层。所有 UI 与守护逻辑都通过这里读写，避免状态分散。
@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var settings: AppSettings {
        didSet { save() }
    }

    private let defaultsKey = "inputpilot.settings.v1"
    private var saveTask: Task<Void, Never>?

    private init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = AppSettings()
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            settings.launchAtLogin = enabled
        } catch {
            // 启动项注册失败时保持 UI 与真实状态一致，错误由设置页展示兜底提示。
            settings.launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    func upsertRule(_ rule: AppInputRule) {
        settings.appRules.removeAll { $0.bundleIdentifier == rule.bundleIdentifier }
        settings.appRules.append(rule)
        settings.appRules.sort { $0.appName.localizedStandardCompare($1.appName) == .orderedAscending }
    }

    func removeRule(bundleIdentifier: String) {
        settings.appRules.removeAll { $0.bundleIdentifier == bundleIdentifier }
    }

    private func save() {
        saveTask?.cancel()
        let snapshot = settings
        saveTask = Task { [defaultsKey] in
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled, let data = try? JSONEncoder().encode(snapshot) else { return }
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
