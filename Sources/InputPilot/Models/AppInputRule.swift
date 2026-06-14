import Foundation

/// 单个应用的输入法规则，按 bundleIdentifier 命中。
struct AppInputRule: Identifiable, Codable, Hashable {
    var id: String { bundleIdentifier }
    var appName: String
    var bundleIdentifier: String
    var inputSourceID: String
    var inputSourceName: String
    var isEnabled: Bool
}
