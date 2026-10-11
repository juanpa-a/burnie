import Foundation

/// Tokens per day and provider, persisted in `history.json` as `{ "claude": { "2026-10-10": 1250000 } }`.
///
/// Days in the activity window are rewritten from the source on every refresh; older ones
/// stay frozen, because Claude Code deletes old transcripts and Cursor's CSV is only requested for 8 days.
public struct UsageHistory: Sendable, Equatable {
    public static let retentionDays = 35

    private var tokens: [ProviderID: [LocalDay: Int]] = [:]

    public init() {}

    /// Overwrites the days in `points` and prunes anything past the retention.
    public mutating func record(_ points: [DailyPoint], for provider: ProviderID, today: LocalDay) {
        for point in points {
            tokens[provider, default: [:]][point.day] = point.value
        }
        let oldestKept = today.advanced(by: 1 - Self.retentionDays)
        tokens[provider] = tokens[provider]?.filter { $0.key >= oldestKept }
    }

    /// The `count` days ending on `today`; days without data are 0.
    public func points(for provider: ProviderID, endingAt today: LocalDay, count: Int = 7) -> [DailyPoint] {
        let days = tokens[provider] ?? [:]
        return (today.advanced(by: 1 - count)...today).map { DailyPoint(day: $0, value: days[$0, default: 0]) }
    }
}

extension UsageHistory: Codable {
    public init(from decoder: Decoder) throws {
        tokens = try decoder.singleValueContainer().decode([ProviderID: [LocalDay: Int]].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(tokens)
    }
}
