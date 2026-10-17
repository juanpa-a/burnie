import Foundation

/// `{"limits": {"view": {"value": …, "at": …}, "today": {"tokens": 1250000}}}` or
/// `{"activityOnly": {"value": {"tokens": 1250000}, "at": …}}` (SPEC section 12).
extension SnapshotContent: Codable {
    private enum Case: String, CodingKey {
        case limits, activityOnly
    }

    private enum LimitsKey: String, CodingKey {
        case view, today
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Case.self)
        switch try container.onlyCase() {
        case .limits:
            let limits = try container.nestedContainer(keyedBy: LimitsKey.self, forKey: .limits)
            self = .limits(
                view: try limits.decode(Stamped<LimitsPart>.self, forKey: .view),
                today: try limits.decodeIfPresent(TodayUsage.self, forKey: .today)
            )
        case .activityOnly:
            self = .activityOnly(try container.decode(Stamped<TodayUsage>.self, forKey: .activityOnly))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Case.self)
        switch self {
        case .limits(let view, let today):
            var limits = container.nestedContainer(keyedBy: LimitsKey.self, forKey: .limits)
            try limits.encode(view, forKey: .view)
            try limits.encodeIfPresent(today, forKey: .today)
        case .activityOnly(let usage):
            try container.encode(usage, forKey: .activityOnly)
        }
    }
}
