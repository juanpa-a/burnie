import Foundation

/// `{"resetsIn": 1760000000}` or `{"noActiveSession": {}}` (SPEC section 12).
extension MeterCaption: Codable {
    private enum Case: String, CodingKey {
        case resetsIn, resetsAt, cycleEnds, noActiveSession, onDemandIdle
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Case.self)
        let name = try container.onlyCase()
        switch name {
        case .resetsIn: self = .resetsIn(try container.decode(Date.self, forKey: name))
        case .resetsAt: self = .resetsAt(try container.decode(Date.self, forKey: name))
        case .cycleEnds: self = .cycleEnds(try container.decode(Date.self, forKey: name))
        case .noActiveSession: self = .noActiveSession
        case .onDemandIdle: self = .onDemandIdle
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Case.self)
        switch self {
        case .resetsIn(let date): try container.encode(date, forKey: .resetsIn)
        case .resetsAt(let date): try container.encode(date, forKey: .resetsAt)
        case .cycleEnds(let date): try container.encode(date, forKey: .cycleEnds)
        case .noActiveSession: container.encodeEmptyCase(.noActiveSession)
        case .onDemandIdle: container.encodeEmptyCase(.onDemandIdle)
        }
    }
}
