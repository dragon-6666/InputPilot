import AppKit
import SwiftUI

/// 半透明输入法状态悬浮框，使用 NSPanel 保证不抢焦点。
@MainActor
final class FloatingWindowController {
    static let shared = FloatingWindowController()

    private let panel: NSPanel
    private let contentView: NSHostingView<FloatingBadgeView>
    private var hideTask: Task<Void, Never>?

    private init() {
        contentView = NSHostingView(rootView: FloatingBadgeView(
            text: "",
            iconText: "拼",
            opacity: 0.86,
            size: 30,
            appearance: .iconOnly,
            theme: .glass
        ))
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
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = contentView
    }

    func fittingSize(for settings: AppSettings, text: String) -> CGSize {
        let preview = NSHostingView(rootView: FloatingBadgeView(
            text: text,
            iconText: iconText(for: text),
            opacity: settings.floatingOpacity,
            size: settings.floatingSize,
            appearance: settings.floatingAppearance,
            theme: settings.floatingTheme
        ))
        let size = preview.fittingSize
        return CGSize(width: max(settings.floatingSize + 12, size.width), height: max(settings.floatingSize + 12, size.height))
    }

    func show(text: String, at point: CGPoint, settings: AppSettings) {
        let size = fittingSize(for: settings, text: text)
        contentView.rootView = FloatingBadgeView(
            text: text,
            iconText: iconText(for: text),
            opacity: settings.floatingOpacity,
            size: settings.floatingSize,
            appearance: settings.floatingAppearance,
            theme: settings.floatingTheme
        )
        contentView.layoutSubtreeIfNeeded()

        panel.setContentSize(size)
        panel.setFrameOrigin(clampedOrigin(point, size: size))
        panel.orderFrontRegardless()
        fade(to: 1, duration: settings.floatingAnimationEnabled ? 0.16 : 0)

        hideTask?.cancel()
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

struct FloatingBadgeView: View {
    let text: String
    let iconText: String
    let opacity: Double
    let size: Double
    let appearance: FloatingAppearance
    let theme: FloatingTheme

    var body: some View {
        HStack(spacing: appearance == .iconOnly ? 0 : 8) {
            Text(iconText)
                .font(.system(size: size * 0.48, weight: .semibold, design: .rounded))
                .foregroundStyle(foregroundColor)
                .frame(width: size, height: size)
                .background(iconBackground, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))

            if appearance == .iconAndName {
                Text(text)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(foregroundColor)
                    .lineLimit(1)
                    .padding(.trailing, 4)
            }
        }
        .padding(appearance == .iconOnly ? 6 : 7)
        .background(containerBackground, in: RoundedRectangle(cornerRadius: size * 0.38, style: .continuous))
        .shadow(color: .black.opacity(theme == .dark ? 0.22 : 0.10), radius: 10, y: 4)
        .fixedSize()
    }

    private var foregroundColor: Color {
        switch theme {
        case .dark: .white
        case .light, .glass: Color.primary
        }
    }

    private var containerBackground: some ShapeStyle {
        switch theme {
        case .glass:
            return AnyShapeStyle(.ultraThinMaterial.opacity(opacity))
        case .light:
            return AnyShapeStyle(Color.white.opacity(opacity))
        case .dark:
            return AnyShapeStyle(Color.black.opacity(max(0.35, opacity * 0.72)))
        }
    }

    private var iconBackground: some ShapeStyle {
        switch theme {
        case .glass:
            return AnyShapeStyle(Color.white.opacity(0.12))
        case .light:
            return AnyShapeStyle(Color.black.opacity(0.06))
        case .dark:
            return AnyShapeStyle(Color.white.opacity(0.12))
        }
    }
}
