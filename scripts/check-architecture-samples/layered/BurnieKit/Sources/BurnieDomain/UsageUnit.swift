// expect: none
import Foundation

/// How a plan measures usage. Raw values and coding keys may spell words: they are wire format, not copy.
public enum UsageUnit: String, Sendable, Codable {
    case tokens = "tokens"
    case money = "money"

    enum CodingKeys: String, CodingKey {
        case unit
    }

    public static let fallback = UsageUnit(rawValue: "tokens") ?? .tokens
}
