import Carbon
import Foundation

/// 封装 macOS Text Input Source API，负责读取和切换输入法。
@MainActor
final class InputSourceManager {
    static let shared = InputSourceManager()

    private init() {}

    func allSelectableInputSources() -> [InputSource] {
        guard let sources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }

        return sources.compactMap { source in
            guard boolProperty(source, kTISPropertyInputSourceIsSelectCapable) == true,
                  let id = stringProperty(source, kTISPropertyInputSourceID) else {
                return nil
            }

            let category = stringProperty(source, kTISPropertyInputSourceCategory) ?? ""
            let name = stringProperty(source, kTISPropertyLocalizedName) ?? ""
            guard shouldExposeInputSource(id: id, localizedName: name, category: category) else {
                return nil
            }

            return InputSource(
                id: id,
                localizedName: name.isEmpty ? readableName(from: id) : name,
                category: category
            )
        }
        .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }

    func currentInputSource() -> InputSource? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let id = stringProperty(source, kTISPropertyInputSourceID) else {
            return nil
        }

        return InputSource(
            id: id,
            localizedName: stringProperty(source, kTISPropertyLocalizedName) ?? id,
            category: stringProperty(source, kTISPropertyInputSourceCategory) ?? ""
        )
    }

    @discardableResult
    func selectInputSource(id: String) -> Bool {
        guard let source = inputSource(id: id) else { return false }
        return TISSelectInputSource(source) == noErr
    }

    private func shouldExposeInputSource(id: String, localizedName: String, category: String) -> Bool {
        // com.apple.PressAndHold 是系统“长按弹出重音字符”的内部输入源，不是真正给用户切换的键盘输入法。
        if id == "com.apple.PressAndHold" { return false }
        if id.contains("PressAndHold") { return false }

        let allowedCategories = [
            kTISCategoryKeyboardInputSource as String,
            "TISCategoryKeyboardInputMode"
        ]
        guard allowedCategories.contains(category) else { return false }

        // 名称为空且不是常规 com.apple/第三方 bundle 风格时不展示，避免设置页出现不可读条目。
        return !localizedName.isEmpty || id.contains(".")
    }

    private func readableName(from id: String) -> String {
        id.split(separator: ".").last.map(String.init) ?? id
    }

    private func inputSource(id: String) -> TISInputSource? {
        let filter: CFDictionary = [kTISPropertyInputSourceID: id] as CFDictionary
        guard let sources = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else {
            return nil
        }
        return sources.first
    }

    private func stringProperty(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }

    private func boolProperty(_ source: TISInputSource, _ key: CFString) -> Bool? {
        guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
        return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(pointer).takeUnretainedValue())
    }
}
