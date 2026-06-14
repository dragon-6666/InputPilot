import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let packaging = root.appendingPathComponent("Packaging")
let iconset = packaging.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.createDirectory(at: packaging, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func drawIcon(size: Int, menu: Bool = false) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSGraphicsContext.current?.imageInterpolation = .high

    if menu {
        NSColor.black.setFill()
        let path = NSBezierPath(roundedRect: rect.insetBy(dx: CGFloat(size) * 0.14, dy: CGFloat(size) * 0.14), xRadius: CGFloat(size) * 0.18, yRadius: CGFloat(size) * 0.18)
        path.fill()
        NSColor.white.setFill()
        let dot = NSBezierPath(ovalIn: NSRect(x: CGFloat(size) * 0.64, y: CGFloat(size) * 0.62, width: CGFloat(size) * 0.14, height: CGFloat(size) * 0.14))
        dot.fill()
        return image
    }

    let bg = NSBezierPath(roundedRect: rect.insetBy(dx: CGFloat(size) * 0.055, dy: CGFloat(size) * 0.055), xRadius: CGFloat(size) * 0.22, yRadius: CGFloat(size) * 0.22)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.20, green: 0.55, blue: 1.0, alpha: 1),
        NSColor(calibratedRed: 0.36, green: 0.24, blue: 0.92, alpha: 1)
    ])?.draw(in: bg, angle: 135)

    NSColor.white.withAlphaComponent(0.16).setStroke()
    bg.lineWidth = max(2, CGFloat(size) * 0.012)
    bg.stroke()

    let plate = NSBezierPath(roundedRect: rect.insetBy(dx: CGFloat(size) * 0.18, dy: CGFloat(size) * 0.25), xRadius: CGFloat(size) * 0.08, yRadius: CGFloat(size) * 0.08)
    NSColor.white.withAlphaComponent(0.92).setFill()
    plate.fill()

    NSColor(calibratedRed: 0.13, green: 0.29, blue: 0.78, alpha: 1).setFill()
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: CGFloat(size) * 0.34, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.13, green: 0.29, blue: 0.78, alpha: 1)
    ]
    let text = "拼" as NSString
    let textSize = text.size(withAttributes: attrs)
    text.draw(at: NSPoint(x: (CGFloat(size) - textSize.width) / 2, y: CGFloat(size) * 0.30), withAttributes: attrs)

    NSColor(calibratedRed: 0.22, green: 0.60, blue: 1, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: CGFloat(size) * 0.68, y: CGFloat(size) * 0.66, width: CGFloat(size) * 0.13, height: CGFloat(size) * 0.13)).fill()
    return image
}

func savePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else { return }
    try data.write(to: url)
}

let sizes = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)]
for (points, scale) in sizes {
    let pixels = points * scale
    let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
    try savePNG(drawIcon(size: pixels), to: iconset.appendingPathComponent(name))
}
try savePNG(drawIcon(size: 36, menu: true), to: packaging.appendingPathComponent("MenuBarIconTemplate.png"))
