import Foundation

/// A meter keyed by its property names. `scope` is written only for a team's meter, so a meter of the user's own is
/// saved as it was before scopes, and a meter without one, as every snapshot saved before them, reads as own (SPEC
/// section 12).
extension Meter: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, fill, value, caption, scope, period
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(MeterID.self, forKey: .id),
            fill: try container.decode(Fraction.self, forKey: .fill),
            value: try container.decode(MeterValue.self, forKey: .value),
            caption: try container.decode(MeterCaption.self, forKey: .caption),
            scope: try container.decodeIfPresent(MeterScope.self, forKey: .scope) ?? .own,
            period: try container.decodeIfPresent(DateInterval.self, forKey: .period)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fill, forKey: .fill)
        try container.encode(value, forKey: .value)
        try container.encode(caption, forKey: .caption)
        if scope != .own {
            try container.encode(scope, forKey: .scope)
        }
        try container.encodeIfPresent(period, forKey: .period)
    }
}
