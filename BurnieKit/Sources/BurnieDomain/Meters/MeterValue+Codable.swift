import Foundation

/// `{"percent": 64}` or `{"money": {"used": 1340, "limit": 2000}}` (SPEC section 12).
extension MeterValue: Codable {
    private enum Case: String, CodingKey {
        case percent, money
    }

    private enum MoneyKey: String, CodingKey {
        case used, limit
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Case.self)
        switch try container.onlyCase() {
        case .percent:
            self = .percent(try container.decode(Int.self, forKey: .percent))
        case .money:
            let money = try container.nestedContainer(keyedBy: MoneyKey.self, forKey: .money)
            self = .money(used: try money.decode(Cents.self, forKey: .used), limit: try money.decodeIfPresent(Cents.self, forKey: .limit))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Case.self)
        switch self {
        case .percent(let percent):
            try container.encode(percent, forKey: .percent)
        case .money(let used, let limit):
            var money = container.nestedContainer(keyedBy: MoneyKey.self, forKey: .money)
            try money.encode(used, forKey: .used)
            try money.encodeIfPresent(limit, forKey: .limit)
        }
    }
}
