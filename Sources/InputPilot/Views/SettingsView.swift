import AppKit
import SwiftUI

struct SettingsView: View {
    @StateObject private var store = SettingsStore.shared
    @State private var inputSources: [InputSource] = InputSourceManager.shared.allSelectableInputSources()
    @State private var selectedSection: SettingsSection = .basic
    @State private var selectedRunningAppBundleID = ""
    @State private var accessibilityTrusted = AccessibilityService.shared.isTrusted

    private var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil }
            .sorted { ($0.localizedName ?? "").localizedStandardCompare($1.localizedName ?? "") == .orderedAscending }
    }

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selectedSection: $selectedSection)

            Divider()

            ScrollView {
                selectedContent
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 780, minHeight: 540)
        .task { inputSources = InputSourceManager.shared.allSelectableInputSources() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            accessibilityTrusted = AccessibilityService.shared.isTrusted
        }
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedSection {
        case .basic: basicSettings
        case .rules: appRules
        case .floating: floatingSettings
        case .permission: permissionSettings
        }
    }

    private var basicSettings: some View {
        SettingsCard(title: "基础设置", subtitle: "设置全局输入法、守护状态和开机启动。", icon: "switch.2") {
            SettingsRow(title: "输入法守护", subtitle: "窗口切换时自动恢复指定输入法。") {
                Toggle("", isOn: binding(\.guardianEnabled)).labelsHidden()
            }

            SettingsRow(title: "全局默认输入法", subtitle: "没有应用规则时使用此输入法。") {
                Picker("", selection: Binding(
                    get: { store.settings.globalInputSourceID ?? "" },
                    set: { setGlobalInputSource(id: $0) }
                )) {
                    Text("不设置").tag("")
                    ForEach(inputSources) { source in
                        Text(source.displayName).tag(source.id)
                    }
                }
                .labelsHidden()
                .frame(width: 260)
            }

            SettingsRow(title: "开机启动", subtitle: "登录后自动启动 InputPilot。") {
                Toggle("", isOn: Binding(
                    get: { store.settings.launchAtLogin },
                    set: { store.setLaunchAtLogin($0) }
                ))
                .labelsHidden()
            }
        }
    }

    private var appRules: some View {
        SettingsCard(title: "应用规则", subtitle: "为单个应用指定输入法，优先级高于全局规则。", icon: "app.badge") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Picker("当前运行应用", selection: $selectedRunningAppBundleID) {
                        Text("请选择应用").tag("")
                        ForEach(runningApps, id: \.bundleIdentifier) { app in
                            Text(app.localizedName ?? app.bundleIdentifier ?? "未知应用")
                                .tag(app.bundleIdentifier ?? "")
                        }
                    }
                    Button("添加规则") { addRuleForSelectedApp() }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedRunningAppBundleID.isEmpty || inputSources.isEmpty)
                }

                if store.settings.appRules.isEmpty {
                    EmptyStateView(text: "暂无应用规则。先打开目标应用，再从上方添加。")
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.settings.appRules) { rule in
                            RuleRow(rule: rule, inputSources: inputSources)
                            if rule.id != store.settings.appRules.last?.id { Divider() }
                        }
                    }
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var floatingSettings: some View {
        SettingsCard(title: "悬浮提示", subtitle: "用轻量提示展示当前输入法，避免误输入。", icon: "macwindow.on.rectangle") {
            SettingsRow(title: "显示悬浮框", subtitle: "切换应用或输入焦点时展示当前输入法。") {
                Toggle("", isOn: binding(\.floatingEnabled)).labelsHidden()
            }

            SettingsRow(title: "展示方式", subtitle: "焦点跟随需要辅助功能权限。") {
                Picker("", selection: binding(\.floatingDisplayMode)) {
                    ForEach(FloatingDisplayMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 220)
            }

            SettingsRow(title: "显示内容", subtitle: "焦点输入时建议仅显示图标，更轻量。") {
                Picker("", selection: binding(\.floatingAppearance)) {
                    ForEach(FloatingAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 190)
            }

            SettingsRow(title: "视觉风格", subtitle: "去掉蓝色背景，使用更克制的系统质感。") {
                Picker("", selection: binding(\.floatingTheme)) {
                    ForEach(FloatingTheme.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 190)
            }

            SettingsRow(title: "透明度", subtitle: "调整悬浮框背景强度。") {
                Slider(value: binding(\.floatingOpacity), in: 0.35...1)
                    .frame(width: 200)
                Text("\(Int(store.settings.floatingOpacity * 100))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }

            SettingsRow(title: "图标大小", subtitle: "控制焦点处输入法图标尺寸。") {
                Slider(value: binding(\.floatingSize), in: 22...44)
                    .frame(width: 200)
                Text("\(Int(store.settings.floatingSize))")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }

            SettingsRow(title: "自动消失", subtitle: "默认 3 秒后渐隐，减少遮挡。") {
                Toggle("", isOn: binding(\.floatingAutoHide)).labelsHidden()
                Slider(value: binding(\.floatingHideDelay), in: 1...8, step: 0.5)
                    .frame(width: 160)
                    .disabled(!store.settings.floatingAutoHide)
                Text("\(store.settings.floatingHideDelay, specifier: "%.1f")s")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .trailing)
            }

            SettingsRow(title: "渐隐动画", subtitle: "开启后悬浮框会平滑出现和消失。") {
                Toggle("", isOn: binding(\.floatingAnimationEnabled)).labelsHidden()
            }

            SettingsRow(title: "焦点偏移", subtitle: "调整图标与输入框之间的距离。") {
                Slider(value: binding(\.floatingOffsetY), in: 0...24, step: 1)
                    .frame(width: 200)
                Text("\(Int(store.settings.floatingOffsetY))")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }

            SettingsRow(title: "固定位置", subtitle: "固定位置模式下的屏幕坐标。") {
                TextField("X", value: binding(\.floatingX), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 72)
                TextField("Y", value: binding(\.floatingY), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 72)
                Button("预览") { AppGuardian.shared.enforce(reason: "preview") }
            }
        }
    }

    private var permissionSettings: some View {
        SettingsCard(title: "权限", subtitle: "焦点跟随模式需要辅助功能权限。", icon: "lock.shield") {
            SettingsRow(title: "辅助功能权限", subtitle: "用于读取当前输入焦点位置，不读取输入内容。") {
                Label(
                    accessibilityTrusted ? "已授权" : "未授权",
                    systemImage: accessibilityTrusted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(accessibilityTrusted ? .green : .orange)

                Button(accessibilityTrusted ? "重新检测" : "请求授权") { refreshAccessibilityPermission() }
            }

            Text("授权后会自动刷新状态，并在下一次焦点聚焦/窗口切换时显示在输入框附近。未授权时自动降级为固定位置显示。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { store.settings[keyPath: keyPath] },
            set: { store.settings[keyPath: keyPath] = $0 }
        )
    }

    private func setGlobalInputSource(id: String) {
        if let source = inputSources.first(where: { $0.id == id }) {
            store.settings.globalInputSourceID = source.id
            store.settings.globalInputSourceName = source.displayName
        } else {
            store.settings.globalInputSourceID = nil
            store.settings.globalInputSourceName = nil
        }
    }

    private func refreshAccessibilityPermission() {
        AccessibilityService.shared.requestPermissionPrompt()
        Task { @MainActor in
            for _ in 0..<20 {
                accessibilityTrusted = AccessibilityService.shared.isTrusted
                if accessibilityTrusted {
                    AppGuardian.shared.enforce(reason: "accessibility")
                    break
                }
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private func addRuleForSelectedApp() {
        guard let app = runningApps.first(where: { $0.bundleIdentifier == selectedRunningAppBundleID }),
              let bundleID = app.bundleIdentifier,
              let source = inputSources.first(where: { $0.id == store.settings.globalInputSourceID }) ?? inputSources.first else {
            return
        }

        store.upsertRule(AppInputRule(
            appName: app.localizedName ?? bundleID,
            bundleIdentifier: bundleID,
            inputSourceID: source.id,
            inputSourceName: source.displayName,
            isEnabled: true
        ))
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case basic
    case rules
    case floating
    case permission

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basic: "基础设置"
        case .rules: "应用规则"
        case .floating: "悬浮提示"
        case .permission: "权限"
        }
    }

    var icon: String {
        switch self {
        case .basic: "switch.2"
        case .rules: "app.badge"
        case .floating: "macwindow.on.rectangle"
        case .permission: "lock.shield"
        }
    }
}

private struct SettingsSidebar: View {
    @Binding var selectedSection: SettingsSection

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Text("拼")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("InputPilot").font(.headline)
                    Text("输入法守护").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)

            VStack(spacing: 6) {
                ForEach(SettingsSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        Label(section.title, systemImage: section.icon)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedSection == section ? .white : .primary)
                    .background(selectedSection == section ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .padding(.horizontal, 10)

            Spacer()
        }
        .frame(width: 190)
        .background(.bar)
    }
}

private struct RuleRow: View {
    @StateObject private var store = SettingsStore.shared
    let rule: AppInputRule
    let inputSources: [InputSource]

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { updateRule(isEnabled: $0) }
            ))
            .labelsHidden()

            VStack(alignment: .leading, spacing: 3) {
                Text(rule.appName).font(.headline)
                Text(rule.bundleIdentifier).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Picker("输入法", selection: Binding(
                get: { rule.inputSourceID },
                set: { updateRule(inputSourceID: $0) }
            )) {
                ForEach(inputSources) { source in
                    Text(source.displayName).tag(source.id)
                }
            }
            .frame(width: 240)

            Button(role: .destructive) {
                store.removeRule(bundleIdentifier: rule.bundleIdentifier)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
    }

    private func updateRule(isEnabled: Bool? = nil, inputSourceID: String? = nil) {
        var next = rule
        if let isEnabled { next.isEnabled = isEnabled }
        if let inputSourceID, let source = inputSources.first(where: { $0.id == inputSourceID }) {
            next.inputSourceID = source.id
            next.inputSourceName = source.displayName
        }
        store.upsertRule(next)
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.title2.bold())
                    Text(subtitle).foregroundStyle(.secondary)
                }
            }

            Divider()
            VStack(spacing: 0) { content }
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.18), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
        .padding(24)
    }
}

private struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 10) { content }
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { Divider().opacity(0.55) }
    }
}

private struct EmptyStateView: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(28)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
