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

    /// The provider's tokens over its cycle (B-79): from the day the cycle starts on, or from the day the history is
    /// recorded since when that's later, through today; nil when the history has no day of the cycle.
    public func cycleTotal(for provider: ProviderID, startingOn cycleStart: LocalDay, today: LocalDay) -> Tokens? {
        guard let recorded = recordedSince(for: provider) else { return nil }
        let first = max(cycleStart, recorded)
        guard first <= today else { return nil }
        return total(for: provider, from: first, through: today)
    }

    /// The provider's tokens from `first` through `last`, 0 for the days without data; zero when `first` is after
    /// `last`.
    func total(for provider: ProviderID, from first: LocalDay, through last: LocalDay) -> Tokens {
        points(for: provider, endingAt: last, count: first.distance(to: last) + 1).map(\.tokens).reduce(.zero, +)
    }

    /// The first day of the unbroken run of recorded days that ends on the provider's latest one; nil before it
    /// records. A missing day means Burnie didn't record it, so nothing before it is counted on (B-79).
    func recordedSince(for provider: ProviderID) -> LocalDay? {
        guard let days = tokens[provider], var first = days.keys.max() else { return nil }
        while days[first.advanced(by: -1)] != nil {
            first = first.advanced(by: -1)
        }
        return first
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
