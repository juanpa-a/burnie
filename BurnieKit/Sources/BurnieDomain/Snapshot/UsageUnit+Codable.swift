import Foundation

/// `{"tokens": {}}` or `{"money": {}}` (SPEC section 12).
extension UsageUnit: Codable {
    private enum Case: String, CodingKey {
        case tokens, money
    }

    public init(from decoder: Decoder) throws {
        switch try decoder.container(keyedBy: Case.self).onlyCase() {
        case .tokens: self = .tokens
        case .money: self = .money
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Case.self)
        switch self {
        case .tokens: container.encodeEmptyCase(.tokens)
        case .money: container.encodeEmptyCase(.money)
        }
    }
}
