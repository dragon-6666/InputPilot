import Foundation

/// 悬浮框展示方式。
enum FloatingDisplayMode: String, Codable, CaseIterable, Identifiable {
    case focusFollow
    case fixedPosition

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focusFollow: "焦点跟随"
        case .fixedPosition: "固定位置"
        }
    }
}
