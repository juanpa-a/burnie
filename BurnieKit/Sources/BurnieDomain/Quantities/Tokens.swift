import Foundation

/// A count of model tokens. Adding saturates at the bounds of `Int` instead of trapping; no real usage gets near them.
/// Encodes as the bare number.
public struct Tokens: Hashable, Comparable, Sendable {
    public let count: Int

    public init(_ count: Int) {
        self.count = count
    }

    public static func < (lhs: Tokens, rhs: Tokens) -> Bool {
        lhs.count < rhs.count
    }
}

extension Tokens: AdditiveArithmetic {
    public static let zero = Tokens(0)

    public static func + (lhs: Tokens, rhs: Tokens) -> Tokens {
        Tokens(lhs.count.saturatingAdding(rhs.count))
    }

    public static func - (lhs: Tokens, rhs: Tokens) -> Tokens {
        Tokens(lhs.count.saturatingSubtracting(rhs.count))
    }
}

extension Tokens: Codable {
    public init(from decoder: Decoder) throws {
        self.init(try decoder.singleValueContainer().decode(Int.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(count)
    }
}
