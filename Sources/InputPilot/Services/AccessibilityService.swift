import AppKit
import ApplicationServices

/// 辅助功能能力封装：用于读取当前输入焦点和光标位置。
@MainActor
final class AccessibilityService {
    static let shared = AccessibilityService()

    private init() {}

    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestPermissionPrompt() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func focusedElementFrame() -> CGRect? {
        guard let element = focusedElement() else { return nil }
        return frame(of: element)
    }

    func focusedBadgeOrigin(badgeSize: CGSize, offsetY: Double) -> CGPoint? {
        guard isTrusted else { return nil }
        let targetFrame = focusedCaretFrame() ?? focusedElementFrame()
        guard let targetFrame else { return nil }
        return badgeOrigin(forAXFrame: targetFrame, badgeSize: badgeSize, offsetY: offsetY)
    }

    func focusedElementSignature() -> String? {
        guard let frame = focusedElementFrame() else { return nil }
        return "\(Int(frame.minX))-\(Int(frame.minY))-\(Int(frame.width))-\(Int(frame.height))"
    }

    private func badgeOrigin(forAXFrame frame: CGRect, badgeSize: CGSize, offsetY: Double) -> CGPoint {
        // AX 坐标是左上角原点，NSPanel 使用左下角原点，这里转换到光标/输入框下方。
        let screenMaxY = NSScreen.screens.map(\.frame.maxY).max() ?? NSScreen.main?.frame.maxY ?? 0
        let x = frame.midX - badgeSize.width / 2
        let y = screenMaxY - frame.maxY - CGFloat(offsetY) - badgeSize.height
        return CGPoint(x: x, y: y)
    }

    private func focusedElement() -> AXUIElement? {
        guard isTrusted else { return nil }

        let system = AXUIElementCreateSystemWide()
        var focusedObject: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focusedObject)
        guard result == .success, let element = focusedObject else { return nil }
        return (element as! AXUIElement)
    }

    private func focusedCaretFrame() -> CGRect? {
        guard let element = focusedElement() else { return nil }

        var rangeObject: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeObject) == .success,
              let rangeAX = rangeObject else {
            return nil
        }

        var range = CFRange(location: 0, length: 0)
        AXValueGetValue(rangeAX as! AXValue, .cfRange, &range)

        // 部分 App 只有选区长度为 0 时才能返回光标区域。
        guard let rangeValue = AXValueCreate(.cfRange, &range) else { return nil }
        var boundsObject: CFTypeRef?
        let result = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeValue,
            &boundsObject
        )
        guard result == .success, let boundsAX = boundsObject else { return nil }

        var rect = CGRect.zero
        AXValueGetValue(boundsAX as! AXValue, .cgRect, &rect)
        return rect.isNull || rect.isEmpty ? nil : rect
    }

    private func frame(of element: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let positionAX = positionValue,
              let sizeAX = sizeValue else {
            return nil
        }

        var point = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionAX as! AXValue, .cgPoint, &point)
        AXValueGetValue(sizeAX as! AXValue, .cgSize, &size)
        return CGRect(origin: point, size: size)
    }
}
