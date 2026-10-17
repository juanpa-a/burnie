import BurnieCore
import LegacyTestSupport
import Foundation
import Testing

/// What each section shows, what the cache keeps and what the week chart reads, as refreshes arrive.
extension UsageStoreTests {
    static let cachedClaude = UsageSnapshot(
        provider: .claude,
        fetchedAt: now.addingTimeInterval(-3_600),
        plan: "PRO",
        today: .tokens(900_000),
        meters: [Meter(id: .session, fraction: 0.4, value: .percent(40), caption: .noActiveSession)]
    )

    @Test("B-11 refreshing a provider's limits keeps its latest activity")
    func limitsRefreshKeepsTheActivity() async throws {
        let store = await launch()
        let teamLimits = LimitsReading(plan: "TEAMS", meters: [
            Meter(id: .included, fraction: 0.37, value: .money(usedCents: 18_420, limitCents: 50_000), caption: .noActiveSession),
        ])
        cursor.limits.set(.success(teamLimits))
        cursor.activity.set(.success(ActivityReading(tokens: [Self.today: 2_000_000])))

        sleeper.resume(where: CursorWaits.limits.contains)
        await sleeper.nextSleeps(1)

        let shown = try #require(store.snapshot(for: .cursor))
        #expect(shown.meters == teamLimits.meters)
        #expect(shown.today == .tokens(1_800_000))
        #expect(cursor.activity.calls == 1)
    }

    @Test("B-11 refreshing a provider's activity keeps its latest limits")
    func activityRefreshKeepsTheLimits() async throws {
        let store = await launch()
        cursor.limits.set(.failure(.offline))
        cursor.activity.set(.success(ActivityReading(tokens: [Self.today: 2_000_000])))

        sleeper.resume { $0 == CursorWaits.activity }
        await sleeper.nextSleeps(1)

        let shown = try #require(store.snapshot(for: .cursor))
        #expect(shown.meters == Self.cursorLimits.meters)
        #expect(shown.today == .tokens(2_000_000))
        #expect(cursor.limits.calls == 1)
    }

    @Test("B-18 a total failure over a cached snapshot shows the cache with the issue on top")
    func totalFailureShowsTheCacheWithTheIssue() async throws {
        try cache.save(Self.cachedClaude, as: Self.snapshotFile(.claude))
        claude.limits.set(.failure(.notFound))
        claude.activity.set(.failure(.notFound))
        let store = await launch()
        #expect(store.states[.claude] == .ready(Self.cachedClaude.with(issue: .notFound)))
    }

    @Test("B-18 a total failure without a cache shows the failure alone")
    func totalFailureWithoutACacheFails() async {
        claude.limits.set(.failure(.notFound))
        claude.activity.set(.failure(.notFound))
        let store = await launch()
        #expect(store.states[.claude] == .failed(.notFound))
    }

    @Test("B-19 the cache saves each snapshot as shown: merged, with its partial issue")
    func cacheKeepsTheShownSnapshot() async throws {
        let store = await launch()
        #expect(try cachedSnapshot(.cursor) == store.snapshot(for: .cursor))

        cursor.limits.set(.failure(.signInExpired))
        sleeper.resume(where: CursorWaits.limits.contains)
        await sleeper.nextSleeps(1)

        let shown = try #require(store.snapshot(for: .cursor))
        #expect(shown.meters == Self.cursorLimits.meters)
        #expect(shown.issue == .signInExpired)
        #expect(try cachedSnapshot(.cursor) == shown)
    }

    @Test("B-19 a total failure saves nothing, so the cache keeps the last good snapshot")
    func totalFailureSavesNothing() async throws {
        try cache.save(Self.cachedClaude, as: Self.snapshotFile(.claude))
        claude.limits.set(.failure(.notFound))
        claude.activity.set(.failure(.notFound))
        _ = await launch()
        #expect(try cachedSnapshot(.claude) == Self.cachedClaude)
    }

    @Test("B-40 with the On-demand switch off, sections hide the on-demand meter and the switch stays")
    func onDemandOffHidesTheMeterAndKeepsTheSwitch() async throws {
        let store = await launch()
        store.setShowOnDemand(false)

        let snapshot = try #require(store.snapshot(for: .cursor))
        #expect(snapshot.hasOnDemand)
        #expect(store.shownState(for: .cursor) == .ready(snapshot.hidingOnDemand()))
        #expect(store.hasOnDemand)
    }

    @Test("B-40 the On-demand switch shows only while an enabled provider's snapshot has on-demand")
    func onDemandSwitchFollowsEnabledSnapshots() async throws {
        let cachedCursor = UsageSnapshot(provider: .cursor, fetchedAt: Self.now, meters: Self.cursorLimits.meters)
        try cache.save(cachedCursor, as: Self.snapshotFile(.cursor))
        enabled.value = [.claude]
        let store = await launch()
        #expect(!store.hasOnDemand)

        store.setEnabled(.cursor, true)
        #expect(store.hasOnDemand)
    }

    @Test("snapshot-<provider id>.json and history.json that don't decode read as no cache, never a crash")
    func undecodableFilesReadAsNoCache() async throws {
        // JSON of the wrong shape, as a damaged file or one from another version would be.
        try cache.save("not a snapshot", as: Self.snapshotFile(.claude))
        try cache.save("not a history", as: Self.historyFile)
        claude.limits.set(.failure(.notFound))
        claude.activity.set(.failure(.notFound))

        let store = await launch()

        // Without a cache, the failed refresh shows alone (B-18).
        #expect(store.states[.claude] == .failed(.notFound))
        #expect(store.history[.claude] == Self.week([0, 0, 0, 0, 0, 0, 0]))
    }

    @Test("B-42 each activity refresh saves the history it recorded")
    func activityRefreshSavesTheHistory() async throws {
        let store = await launch()
        #expect(try cachedHistory()?.points(for: .claude, endingAt: Self.today) == Self.week([0, 0, 0, 0, 400_000, 0, 1_800_000]))

        claude.activity.set(.success(ActivityReading(tokens: [Self.today: 2_000_000])))
        claude.watcher.reportChange()
        await sleeper.nextSleeps(1)

        #expect(try cachedHistory()?.points(for: .claude, endingAt: Self.today) == Self.week([0, 0, 0, 0, 0, 0, 2_000_000]))
        #expect(store.history[.claude] == Self.week([0, 0, 0, 0, 0, 0, 2_000_000]))
    }

    @Test("B-43 the history has 7 points per provider ending today, with 0 for days without data")
    func historyEndsTodayZeroFilled() async throws {
        var savedHistory = UsageHistory()
        let cursorDays = [DailyPoint(day: .day("2026-10-05"), value: 700), DailyPoint(day: .day("2026-10-09"), value: 900)]
        savedHistory.record(cursorDays, for: .cursor, today: Self.today)
        try cache.save(savedHistory, as: Self.historyFile)
        cursor.activity.set(.failure(.offline))

        let store = await launch()

        #expect(store.history[.claude] == Self.week([0, 0, 0, 0, 400_000, 0, 1_800_000]))
        #expect(store.history[.cursor] == Self.week([0, 700, 0, 0, 0, 900, 0]))
    }
}
