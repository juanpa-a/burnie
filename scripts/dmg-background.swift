// Draws the background of Burnie's DMG window: a headline on warm paper and a hand-drawn
// arrow from Burnie.app to the Applications shortcut, where Finder places the two icons.
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
    static let headlineLineHeight: CGFloat = 52
    static let headlineTop: CGFloat = 96
}

enum Palette {
    static let paper = CGColor(srgbRed: 1, green: 0.99, blue: 0.94, alpha: 1)
    static let ink = NSColor(srgbRed: 0.08, green: 0.07, blue: 0.06, alpha: 1)
    static let ember = CGColor(srgbRed: 0xF0 / 255, green: 0x88 / 255, blue: 0x3E / 255, alpha: 1)
}

// MARK: - Headline

/// One array per line; italic runs set the verb apart, the way a hand would underline it.
let headline: [[(text: String, italic: Bool)]] = [
    [("Keep your tokens in check,", false)],
    [("drag ", true), ("Burnie to Applications", false)],
]

func serifFont(italic: Bool) -> NSFont {
    var descriptor = NSFont.systemFont(ofSize: Layout.headlineSize).fontDescriptor.withDesign(.serif)!
    if italic {
        descriptor = descriptor.withSymbolicTraits(.italic)
    }
    return NSFont(descriptor: descriptor, size: Layout.headlineSize)!
}

func attributedLine(_ runs: [(text: String, italic: Bool)]) -> NSAttributedString {
    let line = NSMutableAttributedString()
    for run in runs {
        line.append(NSAttributedString(string: run.text, attributes: [
            .font: serifFont(italic: run.italic),
            .foregroundColor: Palette.ink,
        ]))
    }
    return line
}

func drawHeadline(in context: CGContext) {
    context.saveGState()
    context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
    for (index, runs) in headline.enumerated() {
        let line = CTLineCreateWithAttributedString(attributedLine(runs))
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        let baseline = Layout.headlineTop + CGFloat(index) * Layout.headlineLineHeight
        context.textPosition = CGPoint(x: (Layout.window.width - width) / 2, y: baseline)
        CTLineDraw(line, context)
    }
    context.restoreGState()
}

// MARK: - Arrow

/// A swoop with a loop in the middle, as if drawn with a marker, ending in an open arrowhead.
/// Points are offsets from the midpoint between the two icons.
func drawArrow(in context: CGContext) {
    let center = CGPoint(x: (Layout.appIcon.x + Layout.applicationsIcon.x) / 2, y: Layout.appIcon.y)
    func point(_ dx: CGFloat, _ dy: CGFloat) -> CGPoint { CGPoint(x: center.x + dx, y: center.y + dy) }

    let tip = point(70, 2)
    let path = CGMutablePath()
    path.move(to: point(-72, -22))
    path.addCurve(to: point(-30, 14), control1: point(-78, 6), control2: point(-58, 18))
    path.addCurve(to: point(0, -8), control1: point(-12, 11), control2: point(6, 2))
    path.addCurve(to: point(-14, 6), control1: point(-6, -20), control2: point(-26, -6))
    path.addCurve(to: tip, control1: point(0, 20), control2: point(40, 12))
    path.move(to: point(57, -7))
    path.addLine(to: tip)
    path.addLine(to: point(60, 13))

    context.saveGState()
    context.setStrokeColor(Palette.ember)
    context.setLineWidth(3.5)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.addPath(path)
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
    drawHeadline(in: context)
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
