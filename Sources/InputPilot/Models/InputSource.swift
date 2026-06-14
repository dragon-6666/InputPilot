import Foundation

/// macOS 输入法数据模型，仅保存稳定字段，避免直接持久化 TIS 对象。
struct InputSource: Identifiable, Codable, Hashable {
    let id: String
    let localizedName: String
    let category: String

    var displayName: String {
        localizedName.isEmpty ? id : localizedName
    }
}
