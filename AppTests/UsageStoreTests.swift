import BurnieCore
import BurnieSystem
import BurnieTestSupport
import Foundation
import Testing

/// The store driven the way the app model will be: use cases in (its methods), what the views read out, over
/// providers made of fakes, a manual clock and sleeper, and a cache and settings kept in memory. Every wait is on a
/// signal; should a change lose one, the time limit fails the test instead of hanging the run.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct UsageStoreTests {
    /// One provider made of fakes, handed to the store the way `ProviderAssembly` hands the real ones.
    struct FakeProvider {
        let id: ProviderID
        let limits: FakeLimitsSource
        let activity: FakeActivitySource
        let watcher = FakeActivityWatcher()
        let renewer: FakeSignInRenewer?

        /// How many times each source was read: the limits, then the activity.
        var reads: [Int] {
            [limits.calls, activity.calls]
        }

        func assembly(clock: Clock) -> ProviderAssembly {
            ProviderAssembly(
                provider: CompositeUsageProvider(id: id, limits: limits, activity: activity, clock: clock),
                watcher: watcher,
                signInRenewer: renewer
            )
        }
    }

    /// A `Setting` kept in memory that remembers each value saved, so tests see what the store persisted and when.
    final class InMemorySetting<Value> {
        /// What the next launch loads.
        var value: Value
        private(set) var saves: [Value] = []

        init(_ value: Value) {
            self.value = value
        }

        var setting: Setting<Value> {
            Setting(
                load: { self.value },
                save: { value in
                    self.value = value
                    self.saves.append(value)
                }
            )
        }
    }

    /// Saturday 2026-10-10, 2 PM in Mexico City, the clock's time zone.
    static let now = Date.iso("2026-10-10T20:00:00Z")
    static let today = LocalDay.day("2026-10-10")
    static let claudeLimits = LimitsReading(plan: "MAX", meters: [
        Meter(id: .session, fraction: 0.64, value: .percent(64), caption: .noActiveSession),
        Meter(id: .weekly, fraction: 0.24, value: .percent(24), caption: .noActiveSession),
    ])
    static let cursorLimits = LimitsReading(plan: "PRO", meters: [
        Meter(id: .cursorModels, fraction: 0.2, value: .percent(20), caption: .noActiveSession),
        Meter(id: .otherModels, fraction: 0.8, value: .percent(80), caption: .noActiveSession),
        Meter(id: .onDemand, fraction: 0.67, value: .money(usedCents: 1_340, limitCents: 2_000), caption: .onDemandIdle),
    ])
    static let activity = ActivityReading(tokens: [today: 1_800_000, .day("2026-10-08"): 400_000])

    /// Seven daily points ending today.
    static func week(_ tokens: [Int]) -> [DailyPoint] {
        zip(today.advanced(by: -6)...today, tokens).map { DailyPoint(day: $0, value: $1) }
    }

    /// The name of `id`'s snapshot file in Application Support, where the store caches what it shows.
    static func snapshotFile(_ id: ProviderID) -> String {
        "snapshot-\(id.rawValue)"
    }

    /// The name of the history file in Application Support, where the store keeps every provider's days.
    static let historyFile = "history"

    let clock = ManualClock(now: Self.now)
    let sleeper = ManualSleeper()
    let systemEvents = FakeSystemEvents()
    let cache = InMemorySnapshotStore()
    let claude = FakeProvider(
        id: .claude,
        limits: FakeLimitsSource(.success(Self.claudeLimits)),
        activity: FakeActivitySource(.success(Self.activity)),
        renewer: FakeSignInRenewer()
    )
    let cursor = FakeProvider(
        id: .cursor,
        limits: FakeLimitsSource(.success(Self.cursorLimits)),
        activity: FakeActivitySource(.success(Self.activity)),
        renewer: nil
    )
    let enabled = InMemorySetting(Set(ProviderID.allCases))
    let favorite = InMemorySetting<ProviderID?>(nil)
    let showRing = InMemorySetting(true)
    let showWeekChart = InMemorySetting(true)
    let showOnDemand = InMemorySetting(true)

    /// The store as the app starts it, once the first refresh of each enabled provider's tasks is done, so every
    /// task has its timer armed.
    func launch() async -> UsageStore {
        let store = UsageStore(
            providers: [claude.assembly(clock: clock), cursor.assembly(clock: clock)],
            cache: cache,
            clock: clock,
            sleeper: sleeper,
            systemEvents: systemEvents,
            enabledSetting: enabled.setting,
            favoriteSetting: favorite.setting,
            showRingSetting: showRing.setting,
            showWeekChartSetting: showWeekChart.setting,
            showOnDemandSetting: showOnDemand.setting
        )
        store.start()
        await sleeper.nextSleeps(store.enabled.count * UsageSource.allCases.count)
        return store
    }

    func cachedSnapshot(_ id: ProviderID) throws -> UsageSnapshot? {
        try cache.load(Self.snapshotFile(id))
    }

    func cachedHistory() throws -> UsageHistory? {
        try cache.load(Self.historyFile)
    }
}
