import Foundation

/// An amount of money in US cents. Adding saturates at the bounds of `Int` instead of trapping; no real spend gets near
/// them. Encodes as the bare number.
public struct Cents: Hashable, Comparable, Sendable {
    public let amount: Int

    public init(_ amount: Int) {
        self.amount = amount
    }

    public static func < (lhs: Cents, rhs: Cents) -> Bool {
        lhs.amount < rhs.amount
    }
}

extension Cents: AdditiveArithmetic {
    public static let zero = Cents(0)

    public static func + (lhs: Cents, rhs: Cents) -> Cents {
        Cents(lhs.amount.saturatingAdding(rhs.amount))
    }

    public static func - (lhs: Cents, rhs: Cents) -> Cents {
        Cents(lhs.amount.saturatingSubtracting(rhs.amount))
    }
}

extension Cents: Codable {
    public init(from decoder: Decoder) throws {
        self.init(try decoder.singleValueContainer().decode(Int.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(amount)
    }
}
