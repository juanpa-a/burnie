import Foundation

/// `{"own": {}}` or `{"team": {}}` (SPEC section 12).
extension MeterScope: Codable {
    private enum Case: String, CodingKey {
        case own, team
    }

    public init(from decoder: Decoder) throws {
        switch try decoder.container(keyedBy: Case.self).onlyCase() {
        case .own: self = .own
        case .team: self = .team
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Case.self)
        switch self {
        case .own: container.encodeEmptyCase(.own)
        case .team: container.encodeEmptyCase(.team)
        }
    }
}
