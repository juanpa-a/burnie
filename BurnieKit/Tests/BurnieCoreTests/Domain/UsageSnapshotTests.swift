import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct UsageSnapshotTests {
    /// What `Fixtures/Persistence/snapshot-claude.json` holds: percent meters with periods, a plan, today's tokens and
    /// a partial issue over the cached meters.
    static let claude = UsageSnapshot(
        provider: .claude,
        fetchedAt: .iso("2026-10-10T19:55:00Z"),
        plan: "MAX",
        today: .tokens(1_250_000),
        meters: [
            Meter(
                id: .session, fraction: 0.64, value: .percent(64), caption: .resetsIn(.iso("2026-10-10T22:00:00Z")),
                period: DateInterval(start: .iso("2026-10-10T17:00:00Z"), duration: 5 * 3_600)
            ),
            Meter(
                id: .weekly, fraction: 0.38, value: .percent(38), caption: .resetsAt(.iso("2026-10-15T15:00:00Z")),
                period: DateInterval(start: .iso("2026-10-08T15:00:00Z"), duration: 7 * 86_400)
            ),
        ],
        issue: .rateLimited(retryAt: .iso("2026-10-10T20:05:00Z"))
    )

    /// What `Fixtures/Persistence/snapshot-cursor.json` holds: a money budget, an idle on-demand meter without a limit
    /// and today's spend, with no issue.
    static let cursor = UsageSnapshot(
        provider: .cursor,
        fetchedAt: .iso("2026-10-10T19:50:00Z"),
        plan: "ENTERPRISE",
        today: .money(cents: 1_240),
        meters: [
            Meter(
                id: .included, fraction: 0.421, value: .money(usedCents: 4_210, limitCents: 10_000),
                caption: .cycleEnds(.iso("2026-11-01T00:00:00Z")),
                period: DateInterval(start: .iso("2026-10-01T00:00:00Z"), end: .iso("2026-11-01T00:00:00Z"))
            ),
            Meter(id: .onDemand, fraction: 0, value: .money(usedCents: 0, limitCents: nil), caption: .onDemandIdle),
        ]
    )

    @Test("snapshot-<provider id>.json decodes in today's flat shape", arguments: [
        ("snapshot-claude.json", claude),
        ("snapshot-cursor.json", cursor),
    ])
    func snapshotFileDecodesInTodaysShape(file: String, snapshot: UsageSnapshot) throws {
        #expect(try Fixture.persisted(UsageSnapshot.self, from: file) == snapshot)
    }

    @Test("meter ids and the missingScope issue are saved under their frozen names")
    func frozenNamesAreWhatGetsSaved() throws {
        let meterIDs: [MeterID] = [.session, .weekly, .cursorModels, .otherModels, .included, .onDemand]
        let savedIDs = String(decoding: try JSONEncoder().encode(meterIDs), as: UTF8.self)
        #expect(savedIDs == #"["session","weekly","cursorModels","otherModels","included","onDemand"]"#)

        let savedIssue = String(decoding: try JSONEncoder().encode(ProviderIssue.missingScope), as: UTF8.self)
        #expect(savedIssue == #"{"missingScope":{}}"#)
    }
}
