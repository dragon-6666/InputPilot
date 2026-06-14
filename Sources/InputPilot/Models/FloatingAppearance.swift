import Foundation

/// 悬浮提示内容样式。
enum FloatingAppearance: String, Codable, CaseIterable, Identifiable {
    case iconOnly
    case iconAndName

    var id: String { rawValue }

    var title: String {
        switch self {
        case .iconOnly: "仅图标"
        case .iconAndName: "图标和名称"
        }
    }
}

/// 悬浮提示视觉风格。
enum FloatingTheme: String, Codable, CaseIterable, Identifiable {
    case glass
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glass: "磨砂"
        case .light: "浅色"
        case .dark: "深色"
        }
    }
}
