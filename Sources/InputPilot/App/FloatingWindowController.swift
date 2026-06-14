import AppKit

/// 半透明输入法状态悬浮框，使用 NSPanel 保证不抢焦点。
@MainActor
final class FloatingWindowController {
    static let shared = FloatingWindowController()

    private let panel: NSPanel
    private let badgeView = FloatingBadgeContentView()
    private var hideTask: Task<Void, Never>?

    private init() {
        panel = NSPanel(
            contentRect: NSRect(x: 64, y: 64, width: 44, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.alphaValue = 0
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.ignoresMouseEvents = true
        panel.contentView = badgeView
    }

    func fittingSize(for settings: AppSettings, text: String) -> CGSize {
        FloatingBadgeContentView.fittingSize(
            text: text,
            iconText: iconText(for: text),
            size: settings.floatingSize,
            appearance: settings.floatingAppearance
        )
    }

    func show(text: String, at point: CGPoint, settings: AppSettings) {
        hideTask?.cancel()

        let iconText = iconText(for: text)
        let size = FloatingBadgeContentView.fittingSize(
            text: text,
            iconText: iconText,
            size: settings.floatingSize,
            appearance: settings.floatingAppearance
        )

        // 每次展示都完整刷新配置，避免频繁切换设置时出现旧样式残留。
        badgeView.configure(text: text, iconText: iconText, settings: settings)
        panel.setContentSize(size)
        panel.setFrameOrigin(clampedOrigin(point, size: size))
        panel.alphaValue = max(panel.alphaValue, 0)
        panel.orderFrontRegardless()
        fade(to: 1, duration: settings.floatingAnimationEnabled ? 0.16 : 0)

        guard settings.floatingAutoHide else { return }

        // 默认 3 秒后淡出，避免悬浮提示长期遮挡输入区域。
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(Int(settings.floatingHideDelay * 1000)))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.fadeOutAndHide(animated: settings.floatingAnimationEnabled)
            }
        }
    }

    func hide() {
        hideTask?.cancel()
        fadeOutAndHide(animated: false)
    }

    private func fadeOutAndHide(animated: Bool) {
        fade(to: 0, duration: animated ? 0.28 : 0) { [weak self] in
            self?.panel.orderOut(nil)
        }
    }

    private func fade(to alpha: CGFloat, duration: TimeInterval, completion: (@MainActor @Sendable () -> Void)? = nil) {
        guard duration > 0 else {
            panel.alphaValue = alpha
            completion?()
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: alpha > panel.alphaValue ? .easeOut : .easeIn)
            panel.animator().alphaValue = alpha
        } completionHandler: {
            Task { @MainActor in completion?() }
        }
    }

    private func iconText(for inputSourceName: String) -> String {
        let lowercased = inputSourceName.lowercased()
        if lowercased.contains("abc") { return "A" }
        if lowercased.contains("emoji") || inputSourceName.contains("表情") { return "☺" }
        if lowercased.contains("pinyin") || inputSourceName.contains("拼") || inputSourceName.contains("豆包") { return "拼" }
        return String(inputSourceName.prefix(1)).isEmpty ? "⌨" : String(inputSourceName.prefix(1))
    }

    private func clampedOrigin(_ point: CGPoint, size: NSSize) -> CGPoint {
        guard let screenFrame = NSScreen.screens.first(where: { $0.frame.insetBy(dx: -120, dy: -120).contains(point) })?.visibleFrame ?? NSScreen.main?.visibleFrame else {
            return point
        }

        return CGPoint(
            x: min(max(point.x, screenFrame.minX + 8), screenFrame.maxX - size.width - 8),
            y: min(max(point.y, screenFrame.minY + 8), screenFrame.maxY - size.height - 8)
        )
    }
}

/// 使用 AppKit 自绘，确保圆角外完全透明，不再出现浅色直角背景。
private final class FloatingBadgeContentView: NSView {
    private var text = ""
    private var iconText = "拼"
    private var opacity: Double = 0.86
    private var size: Double = 30
    private var badgeAppearance: FloatingAppearance = .iconOnly
    private var theme: FloatingTheme = .glass

    override var isOpaque: Bool { false }

    func configure(text: String, iconText: String, settings: AppSettings) {
        self.text = text
        self.iconText = iconText
        opacity = settings.floatingOpacity
        size = settings.floatingSize
        badgeAppearance = settings.floatingAppearance
        theme = settings.floatingTheme
        frame.size = Self.fittingSize(text: text, iconText: iconText, size: settings.floatingSize, appearance: settings.floatingAppearance)
        needsDisplay = true
        layoutSubtreeIfNeeded()
    }

    static func fittingSize(text: String, iconText: String, size: Double, appearance: FloatingAppearance) -> CGSize {
        let padding: CGFloat = appearance == .iconOnly ? 6 : 7
        let iconSize = CGFloat(size)
        let height = iconSize + padding * 2
        guard appearance == .iconAndName else {
            return CGSize(width: iconSize + padding * 2, height: height)
        }

        let textWidth = (text as NSString).size(withAttributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold)
        ]).width
        return CGSize(width: padding * 2 + iconSize + 8 + min(max(textWidth, 42), 180) + 4, height: height)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        let bounds = bounds.insetBy(dx: 0.5, dy: 0.5)
        let radius = min(CGFloat(size) * 0.38, bounds.height / 2)
        let containerPath = NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius)
        containerColor.setFill()
        containerPath.fill()

        if theme == .light {
            NSColor.black.withAlphaComponent(0.06).setStroke()
            containerPath.lineWidth = 1
            containerPath.stroke()
        }

        drawIcon(in: NSRect(x: bounds.minX + contentPadding, y: bounds.midY - CGFloat(size) / 2, width: CGFloat(size), height: CGFloat(size)))

        if badgeAppearance == .iconAndName {
            drawName(in: NSRect(
                x: bounds.minX + contentPadding + CGFloat(size) + 8,
                y: bounds.minY,
                width: bounds.width - contentPadding * 2 - CGFloat(size) - 8,
                height: bounds.height
            ))
        }
    }

    private var contentPadding: CGFloat { badgeAppearance == .iconOnly ? 6 : 7 }

    private var containerColor: NSColor {
        switch theme {
        case .glass:
            return NSColor.windowBackgroundColor.withAlphaComponent(opacity)
        case .light:
            return NSColor.white.withAlphaComponent(opacity)
        case .dark:
            return NSColor.black.withAlphaComponent(max(0.35, opacity * 0.72))
        }
    }

    private var foregroundColor: NSColor {
        switch theme {
        case .dark: .white
        case .glass, .light: .labelColor
        }
    }

    private var iconBackgroundColor: NSColor {
        switch theme {
        case .glass:
            return NSColor.white.withAlphaComponent(0.16)
        case .light:
            return NSColor.black.withAlphaComponent(0.06)
        case .dark:
            return NSColor.white.withAlphaComponent(0.12)
        }
    }

    private func drawIcon(in rect: NSRect) {
        let path = NSBezierPath(roundedRect: rect, xRadius: CGFloat(size) * 0.28, yRadius: CGFloat(size) * 0.28)
        iconBackgroundColor.setFill()
        path.fill()

        let font = NSFont.systemFont(ofSize: CGFloat(size) * 0.48, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: foregroundColor
        ]
        let attributed = NSAttributedString(string: iconText, attributes: attributes)
        let textSize = attributed.size()
        attributed.draw(at: NSPoint(x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2))
    }

    private func drawName(in rect: NSRect) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributed.size()
        attributed.draw(in: NSRect(x: rect.minX, y: rect.midY - textSize.height / 2, width: rect.width, height: textSize.height))
    }
}
