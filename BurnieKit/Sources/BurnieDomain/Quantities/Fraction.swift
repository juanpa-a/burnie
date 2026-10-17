import Foundation

/// A number within 0…1, like a meter's fill. Building one clamps, so an API's 104%, a negative or NaN (read as 0) never
/// gets through, and decoding clamps the same way. Encodes as the bare number.
public struct Fraction: Hashable, Comparable, Sendable {
    public static let zero = Fraction(0)

    public let value: Double

    public init(_ value: Double) {
        self.value = value.isNaN ? 0 : min(max(value, 0), 1)
    }

    public static func < (lhs: Fraction, rhs: Fraction) -> Bool {
        lhs.value < rhs.value
    }
}

extension Fraction: Codable {
    public init(from decoder: Decoder) throws {
        self.init(try decoder.singleValueContainer().decode(Double.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
