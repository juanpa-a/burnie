import Foundation

/// Tokens per day and provider, persisted in `history.json` as `{ "claude": { "2026-10-10": 1250000 } }`.
///
/// Each activity refresh rewrites the days of its window; older days stay frozen, because providers forget them
/// (Claude Code deletes old transcripts; Cursor's events are only requested for the window).
public struct UsageHistory: Hashable, Sendable {
    /// How long a day is kept.
    public static let retentionDays = 35

    private var tokens: [ProviderID: [LocalDay: Tokens]] = [:]

    public init() {}

    /// Rewrites every day of the activity window ending `today` from `tokens`, 0 for the days it doesn't mention, and
    /// prunes `provider`'s days past the retention. Other providers stay as they are, so a disabled provider's days
    /// wait until it records again (B-42).
    public mutating func record(_ tokens: [LocalDay: Tokens], for provider: ProviderID, today: LocalDay) {
        var days = self.tokens[provider, default: [:]]
        for day in ActivityWindow.days(endingAt: today) {
            days[day] = tokens[day, default: .zero]
        }
        let oldestKept = today.advanced(by: 1 - Self.retentionDays)
        self.tokens[provider] = days.filter { $0.key >= oldestKept }
    }

    /// The `count` consecutive days ending on `today`, 0 for the days without data; none for a `count` below 1.
    public func points(for provider: ProviderID, endingAt today: LocalDay, count: Int) -> [DailyPoint] {
        guard count > 0 else { return [] }
        let days = tokens[provider] ?? [:]
        return (today.advanced(by: 1 - count)...today).map { DailyPoint(day: $0, tokens: days[$0, default: .zero]) }
    }
}

extension UsageHistory: Codable {
    public init(from decoder: Decoder) throws {
        tokens = try decoder.singleValueContainer().decode([ProviderID: [LocalDay: Tokens]].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(tokens)
    }
}
