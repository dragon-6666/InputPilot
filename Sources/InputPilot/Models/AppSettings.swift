import Foundation

/// 应用设置快照，集中管理便于后续扩展迁移。
struct AppSettings: Codable, Equatable {
    var guardianEnabled: Bool = true
    var globalInputSourceID: String?
    var globalInputSourceName: String?
    var appRules: [AppInputRule] = []
    var launchAtLogin: Bool = false
    var floatingEnabled: Bool = true
    var floatingOpacity: Double = 0.86
    var floatingDisplayMode: FloatingDisplayMode = .fixedPosition
    var floatingAppearance: FloatingAppearance = .iconOnly
    var floatingTheme: FloatingTheme = .glass
    var floatingAutoHide: Bool = true
    var floatingHideDelay: Double = 3
    var floatingAnimationEnabled: Bool = true
    var floatingSize: Double = 30
    var floatingOffsetY: Double = 8
    var floatingX: Double = 64
    var floatingY: Double = 64

    enum CodingKeys: String, CodingKey {
        case guardianEnabled, globalInputSourceID, globalInputSourceName, appRules, launchAtLogin
        case floatingEnabled, floatingOpacity, floatingDisplayMode, floatingAppearance, floatingTheme
        case floatingAutoHide, floatingHideDelay, floatingAnimationEnabled, floatingSize, floatingOffsetY
        case floatingX, floatingY
    }

    init() {}

    /// 兼容旧版本配置，新增字段缺失时使用安全默认值。
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guardianEnabled = try container.decodeIfPresent(Bool.self, forKey: .guardianEnabled) ?? true
        globalInputSourceID = try container.decodeIfPresent(String.self, forKey: .globalInputSourceID)
        globalInputSourceName = try container.decodeIfPresent(String.self, forKey: .globalInputSourceName)
        appRules = try container.decodeIfPresent([AppInputRule].self, forKey: .appRules) ?? []
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        floatingEnabled = try container.decodeIfPresent(Bool.self, forKey: .floatingEnabled) ?? true
        floatingOpacity = try container.decodeIfPresent(Double.self, forKey: .floatingOpacity) ?? 0.86
        floatingDisplayMode = try container.decodeIfPresent(FloatingDisplayMode.self, forKey: .floatingDisplayMode) ?? .fixedPosition
        floatingAppearance = try container.decodeIfPresent(FloatingAppearance.self, forKey: .floatingAppearance) ?? .iconOnly
        floatingTheme = try container.decodeIfPresent(FloatingTheme.self, forKey: .floatingTheme) ?? .glass
        floatingAutoHide = try container.decodeIfPresent(Bool.self, forKey: .floatingAutoHide) ?? true
        floatingHideDelay = try container.decodeIfPresent(Double.self, forKey: .floatingHideDelay) ?? 3
        floatingAnimationEnabled = try container.decodeIfPresent(Bool.self, forKey: .floatingAnimationEnabled) ?? true
        floatingSize = try container.decodeIfPresent(Double.self, forKey: .floatingSize) ?? 30
        floatingOffsetY = try container.decodeIfPresent(Double.self, forKey: .floatingOffsetY) ?? 8
        floatingX = try container.decodeIfPresent(Double.self, forKey: .floatingX) ?? 64
        floatingY = try container.decodeIfPresent(Double.self, forKey: .floatingY) ?? 64
    }
}
