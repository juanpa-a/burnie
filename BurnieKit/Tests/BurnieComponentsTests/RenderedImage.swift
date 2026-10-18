import SwiftUI

/// A component drawn to a bitmap at one pixel per point, for the tests that look at its size or its colors.
@MainActor
struct RenderedImage {
    private let image: CGImage

    /// `view` at `width` and its own height; nil when nothing rendered.
    init?(_ view: some View, width: CGFloat) {
        let renderer = ImageRenderer(content: view.frame(width: width).fixedSize(horizontal: false, vertical: true))
        renderer.scale = 1
        guard let image = renderer.cgImage else { return nil }
        self.image = image
    }

    var size: CGSize {
        CGSize(width: image.width, height: image.height)
    }

    /// The sRGB color of the pixel at `x`, `y`, counted from the top-left corner.
    func color(atX x: Int, y: Int) -> Pixel {
        var rgba = [UInt8](repeating: 0, count: 4)
        // The context writes into `rgba` while it draws, so it only lives inside the closure that lends it the bytes.
        rgba.withUnsafeMutableBytes { bytes in
            let context = CGContext(
                data: bytes.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            // Draws the image shifted so that pixel lands on the context's single one; Core Graphics counts rows from
            // the bottom.
            context.draw(image, in: CGRect(x: -x, y: y + 1 - image.height, width: image.width, height: image.height))
        }
        return Pixel(premultiplied: rgba)
    }
}
