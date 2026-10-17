// expect: none
import Foundation

extension Fraction {
    /// NaN becomes 0; anything else is clamped to 0...1.
    public static func clamping(_ value: Double) -> Fraction {
        Fraction(value: value.isNaN ? 0 : min(max(value, 0), 1))
    }
}
