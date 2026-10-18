/// One pixel's color: channels from 0 to 1, not premultiplied by its alpha.
struct Pixel {
    /// How far apart two channels can be and still count as the same, after 8-bit rounding.
    static let tolerance = 0.01

    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    /// The same color seen through `opacity`.
    func faded(by opacity: Double) -> Pixel {
        Pixel(red: red, green: green, blue: blue, alpha: alpha * opacity)
    }

    func isClose(to other: Pixel) -> Bool {
        zip([red, green, blue, alpha], [other.red, other.green, other.blue, other.alpha]).allSatisfy { abs($0 - $1) <= Self.tolerance }
    }
}

extension Pixel {
    /// From a bitmap's red, green, blue and alpha bytes, with the color premultiplied by the alpha.
    init(premultiplied rgba: [UInt8]) {
        let alpha = Double(rgba[3]) / 255
        let channel = { (value: UInt8) in alpha == 0 ? 0 : Double(value) / 255 / alpha }
        self.init(red: channel(rgba[0]), green: channel(rgba[1]), blue: channel(rgba[2]), alpha: alpha)
    }
}
