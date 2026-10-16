// Draws the background of Burnie's DMG window: a headline and a hint on dotted warm paper, and a
// hand-drawn arrow from Burnie.app to the Applications shortcut, where Finder places the two icons.
//
// Usage: swift scripts/dmg-background.swift <output folder>
// Writes background.png (1x) and background@2x.png.

import AppKit

// MARK: - Layout (points, origin at the top left, as Finder places icons)

enum Layout {
    static let window = CGSize(width: 660, height: 440)
    static let appIcon = CGPoint(x: 170, y: 290)
    static let applicationsIcon = CGPoint(x: 490, y: 290)
    static let headlineSize: CGFloat = 40
    static let headlineBaseline: CGFloat = 104
    static let hintSize: CGFloat = 16
    static let hintBaseline: CGFloat = 142
    static let dotSpacing: CGFloat = 22
    static let dotRadius: CGFloat = 0.9
}

enum Palette {
    static let paper = CGColor(srgbRed: 1, green: 0.99, blue: 0.94, alpha: 1)
    static let ink = NSColor(srgbRed: 0.08, green: 0.07, blue: 0.06, alpha: 1)
    static let mutedInk = ink.withAlphaComponent(0.55)
    static let dots = ink.withAlphaComponent(0.07).cgColor
    static let ember = NSColor(srgbRed: 0xF0 / 255, green: 0x88 / 255, blue: 0x3E / 255, alpha: 1)
}

// MARK: - Paper

func drawDots(in context: CGContext) {
    context.saveGState()
    context.setFillColor(Palette.dots)
    let diameter = 2 * Layout.dotRadius
    for y in stride(from: Layout.dotSpacing / 2, to: Layout.window.height, by: Layout.dotSpacing) {
        for x in stride(from: Layout.dotSpacing / 2, to: Layout.window.width, by: Layout.dotSpacing) {
            context.fillEllipse(in: CGRect(x: x - Layout.dotRadius, y: y - Layout.dotRadius, width: diameter, height: diameter))
        }
    }
    context.restoreGState()
}

// MARK: - Text

/// The serif headline, with the promise set in ember italics, and a quiet sans hint under it.
let headline: [(text: String, emphasized: Bool)] = [
    ("Keep your tokens ", false),
    ("in check", true),
]
let hint = "Drag Burnie to Applications to get started"

func serifFont(italic: Bool) -> NSFont {
    var descriptor = NSFont.systemFont(ofSize: Layout.headlineSize).fontDescriptor.withDesign(.serif)!
    if italic {
        descriptor = descriptor.withSymbolicTraits(.italic)
    }
    return NSFont(descriptor: descriptor, size: Layout.headlineSize)!
}

func headlineLine() -> NSAttributedString {
    let line = NSMutableAttributedString()
    for run in headline {
        line.append(NSAttributedString(string: run.text, attributes: [
            .font: serifFont(italic: run.emphasized),
            .foregroundColor: run.emphasized ? Palette.ember : Palette.ink,
        ]))
    }
    return line
}

func hintLine() -> NSAttributedString {
    NSAttributedString(string: hint, attributes: [
        .font: NSFont.systemFont(ofSize: Layout.hintSize, weight: .medium),
        .foregroundColor: Palette.mutedInk,
    ])
}

func drawCentered(_ text: NSAttributedString, baseline: CGFloat, in context: CGContext) {
    let line = CTLineCreateWithAttributedString(text)
    let width = CTLineGetTypographicBounds(line, nil, nil, nil)
    context.textPosition = CGPoint(x: (Layout.window.width - width) / 2, y: baseline)
    CTLineDraw(line, context)
}

func drawText(in context: CGContext) {
    context.saveGState()
    context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
    drawCentered(headlineLine(), baseline: Layout.headlineBaseline, in: context)
    drawCentered(hintLine(), baseline: Layout.hintBaseline, in: context)
    context.restoreGState()
}

// MARK: - Arrow

/// A dashed swoop with a loop in the middle, as if drawn with a marker, ending in a solid open arrowhead.
/// Points are offsets from the midpoint between the two icons.
func drawArrow(in context: CGContext) {
    let center = CGPoint(x: (Layout.appIcon.x + Layout.applicationsIcon.x) / 2, y: Layout.appIcon.y)
    func point(_ dx: CGFloat, _ dy: CGFloat) -> CGPoint { CGPoint(x: center.x + dx, y: center.y + dy) }

    let tip = point(70, 2)
    let swoop = CGMutablePath()
    swoop.move(to: point(-72, -22))
    swoop.addCurve(to: point(-30, 14), control1: point(-78, 6), control2: point(-58, 18))
    swoop.addCurve(to: point(0, -8), control1: point(-12, 11), control2: point(6, 2))
    swoop.addCurve(to: point(-14, 6), control1: point(-6, -20), control2: point(-26, -6))
    swoop.addCurve(to: tip, control1: point(0, 20), control2: point(40, 12))
    let head = CGMutablePath()
    head.move(to: point(57, -7))
    head.addLine(to: tip)
    head.addLine(to: point(60, 13))

    context.saveGState()
    context.setStrokeColor(Palette.ember.cgColor)
    context.setLineWidth(3.5)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setLineDash(phase: 0, lengths: [7, 7])
    context.addPath(swoop)
    context.strokePath()
    context.setLineDash(phase: 0, lengths: [])
    context.addPath(head)
    context.strokePath()
    context.restoreGState()
}

// MARK: - Rendering

func render(scale: CGFloat) -> CGImage {
    let context = CGContext(
        data: nil,
        width: Int(Layout.window.width * scale),
        height: Int(Layout.window.height * scale),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.translateBy(x: 0, y: Layout.window.height * scale)
    context.scaleBy(x: scale, y: -scale)
    context.setFillColor(Palette.paper)
    context.fill(CGRect(origin: .zero, size: Layout.window))
    drawDots(in: context)
    drawText(in: context)
    drawArrow(in: context)
    return context.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL, scale: CGFloat) {
    let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    let dpi = 72 * scale
    CGImageDestinationAddImage(destination, image, [kCGImagePropertyDPIWidth: dpi, kCGImagePropertyDPIHeight: dpi] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { fatalError("Can't write \(url.path)") }
}

guard CommandLine.arguments.count == 2 else {
    print("Usage: swift dmg-background.swift <output folder>")
    exit(1)
}
let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
writePNG(render(scale: 1), to: folder.appendingPathComponent("background.png"), scale: 1)
writePNG(render(scale: 2), to: folder.appendingPathComponent("background@2x.png"), scale: 2)
