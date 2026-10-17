import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

/// What SPEC section 12 freezes on disk, pinned by fixtures that are never edited (T-7). The one Domain test file that
/// names real provider ids, as the files on users' disks do; `check-architecture.sh` allowlists it for G-5.
struct PersistenceContractTests {
    static let claude = ProviderID(rawValue: "claude")
    static let cursor = ProviderID(rawValue: "cursor")

    /// What `snapshot-limits.json` holds: a money budget with a period, a percent meter, an idle on-demand feature
    /// without a limit, today's spend and a partial issue.
    static let limits = UsageSnapshot(
        provider: .alpha,
        content: .limits(
            view: Stamped(
                LimitsPart(
                    plan: PlanName(rawValue: "ENTERPRISE"),
                    meters: MeterSet(
                        primary: Meter(
                            id: .budget,
                            fill: Fraction(0.421),
                            value: .money(used: Cents(4_210), limit: Cents(10_000)),
                            caption: .cycleEnds(.iso("2026-11-01T00:00:00Z")),
                            period: DateInterval(start: .iso("2026-10-01T00:00:00Z"), end: .iso("2026-11-01T00:00:00Z"))
                        ),
                        others: [Meter(id: MeterID(rawValue: "weekly"), fill: Fraction(0.38), value: .percent(38), caption: .resetsAt(.iso("2026-10-15T15:00:00Z")))]
                    ),
                    unit: .money,
                    features: SnapshotFeatures(onDemand: Meter(id: .extra, fill: .zero, value: .money(used: .zero, limit: nil), caption: .onDemandIdle))
                ),
                at: .iso("2026-10-10T19:50:00Z")
            ),
            today: .money(Cents(1_240))
        ),
        issue: .rateLimited(retryAt: .iso("2026-10-10T20:05:00Z"))
    )

    /// What `snapshot-activity-only.json` holds: today's tokens alone, with a specific issue.
    static let activityOnly = UsageSnapshot(
        provider: .beta,
        content: .activityOnly(Stamped(.tokens(Tokens(1_250_000)), at: .iso("2026-10-10T19:55:00Z"))),
        issue: .specific(SpecificIssue(code: "missingScope"))
    )

    @Test("history.json keeps its shape: provider, then day, then tokens")
    func historyKeepsItsShape() throws {
        let history = try Fixture.persisted(UsageHistory.self, from: "history.json")
        let today = LocalDay.day("2026-10-10")
        #expect(history.points(for: Self.claude, endingAt: today, count: 4).map(\.tokens.count) == [0, 18_420_000, 25_310_000, 1_250_000])
        #expect(history.points(for: Self.cursor, endingAt: today, count: 3).map(\.tokens.count) == [0, 2_662_000, 29_200])
        #expect(try Fixture.persisted(history, matches: "history.json"))
    }

    @Test("snapshots are saved in the new shape, every enum keyed by its case name", arguments: [
        ("snapshot-limits.json", limits),
        ("snapshot-activity-only.json", activityOnly),
    ])
    func snapshotKeepsItsShape(file: String, snapshot: UsageSnapshot) throws {
        #expect(try Fixture.persisted(UsageSnapshot.self, from: file) == snapshot)
        #expect(try Fixture.persisted(snapshot, matches: file))
    }

    @Test("a snapshot in the flat shape of before the refactor doesn't decode, so it reads as no cache", arguments: [
        "snapshot-claude.json", "snapshot-cursor.json",
    ])
    func flatSnapshotDoesNotDecode(file: String) {
        #expect(throws: DecodingError.self) { try Fixture.persisted(UsageSnapshot.self, from: file) }
    }

    @Test(arguments: Gen.seeds(200))
    func everySnapshotRoundTrips(seed: UInt64) throws {
        var gen = Gen(seed: seed)
        let snapshot = gen.snapshot()
        let saved = try JSONEncoder.persistence.encode(snapshot)
        #expect(try JSONDecoder.persistence.decode(UsageSnapshot.self, from: saved) == snapshot, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func everyHistoryRoundTrips(seed: UInt64) throws {
        var gen = Gen(seed: seed)
        var history = UsageHistory()
        for _ in 0..<gen.int(in: 0...4) {
            let today = gen.localDay()
            history.record(gen.activityPart(around: today).tokens, for: gen.providerID(), today: today)
        }
        let saved = try JSONEncoder.persistence.encode(history)
        #expect(try JSONDecoder.persistence.decode(UsageHistory.self, from: saved) == history, "seed \(seed)")
    }
}
