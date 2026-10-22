import Foundation

/// `{"tokens": 1250000}` or `{"money": 1240}` (SPEC section 12).
extension TodayUsage: Codable {
    private enum Case: String, CodingKey {
        case tokens, money
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Case.self)
        switch try container.onlyCase() {
        case .tokens: self = .tokens(try container.decode(Tokens.self, forKey: .tokens))
        case .money: self = .money(try container.decode(Cents.self, forKey: .money))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Case.self)
        switch self {
        case .tokens(let tokens): try container.encode(tokens, forKey: .tokens)
        case .money(let cents): try container.encode(cents, forKey: .money)
        }
    }
}
