#if DEBUG
import Foundation
import BurnieCore

extension UsageStore {
    /// Store for previews with the canvas's sample data; each argument changes one part.
    static func preview(
        claude: ProviderState = .ready(PreviewData.claude),
        cursor: ProviderState = .ready(PreviewData.cursor),
        enabled: Set<ProviderID> = Set(ProviderID.allCases),
        favorite: ProviderID? = nil,
        showRing: Bool = true,
        showWeekChart: Bool = true,
        history: [ProviderID: [DailyPoint]] = PreviewData.history
    ) -> UsageStore {
        UsageStore(
            previewing: [.claude: claude, .cursor: cursor],
            history: history,
            enabled: enabled,
            favorite: favorite,
            showRing: showRing,
            showWeekChart: showWeekChart,
            sourceLocations: [.claude: "~/.claude"],
            signInRenewers: [.claude: PreviewSignInRenewer()],
            clock: PreviewData.clock
        )
    }
}

/// Takes a second, like `claude` answering, and always renews.
private struct PreviewSignInRenewer: SignInRenewer {
    func renewSignIn() async throws {
        try await Task.sleep(for: .seconds(1))
    }
}

/// Fixed sample data: Saturday, October 10, 2026, 2:00 PM in Mexico City.
enum PreviewData {
    struct FixedClock: Clock {
        let now: Date
        let timeZone: TimeZone
    }

    static let now = Date(timeIntervalSince1970: 1_791_662_400)
    static let clock = FixedClock(now: now, timeZone: TimeZone(identifier: "America/Mexico_City")!)

    static let claudeMeters = [
        Meter(id: .session, fraction: 0.64, value: .percent(64), caption: .resetsIn(now.addingTimeInterval(2 * 3_600 + 14 * 60))),
        Meter(id: .weekly, fraction: 0.38, value: .percent(38), caption: .resetsAt(now.addingTimeInterval(5 * 86_400 - 5 * 3_600))),
    ]

    static let claude = UsageSnapshot(provider: .claude, fetchedAt: now.addingTimeInterval(-120), plan: "MAX", tokensToday: 1_250_000, meters: claudeMeters)

    static let cursor = UsageSnapshot(
        provider: .cursor,
        fetchedAt: now.addingTimeInterval(-120),
        plan: "PRO",
        tokensToday: 2_400_000,
        meters: [
            Meter(id: .cursorModels, fraction: 0.35, value: .percent(35), caption: .cycleEnds(now.addingTimeInterval(22 * 86_400))),
            Meter(id: .otherModels, fraction: 0.8, value: .percent(80), caption: .cycleEnds(now.addingTimeInterval(22 * 86_400))),
            Meter(id: .onDemand, fraction: 0.67, value: .money(usedCents: 1_340, limitCents: 2_000), caption: .cycleEnds(now.addingTimeInterval(22 * 86_400))),
        ]
    )

    static let history: [ProviderID: [DailyPoint]] = [
        .claude: points([420_000, 980_000, 0, 1_200_000, 640_000, 1_100_000, 1_250_000]),
        .cursor: points([1_100_000, 0, 4_000_000, 2_800_000, 1_100_000, 1_900_000, 2_400_000]),
    ]

    /// First launch: no day has data yet.
    static let emptyHistory: [ProviderID: [DailyPoint]] = [
        .claude: points(Array(repeating: 0, count: 7)),
        .cursor: points(Array(repeating: 0, count: 7)),
    ]

    private static func points(_ values: [Int]) -> [DailyPoint] {
        let today = LocalDay(now, in: clock.timeZone)
        return values.enumerated().map { index, value in
            DailyPoint(day: today.advanced(by: index - values.count + 1), value: value)
        }
    }
}
#endif
