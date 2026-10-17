import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct UsageSnapshotOnDemandTests {
    static let included = Meter(id: .included, fraction: 0.4, value: .money(usedCents: 200, limitCents: 500), caption: .noActiveSession)
    static let onDemand = Meter(id: .onDemand, fraction: 0, value: .money(usedCents: 0, limitCents: 1_000), caption: .onDemandIdle)

    static func snapshot(_ meters: [Meter]) -> UsageSnapshot {
        UsageSnapshot(provider: .cursor, fetchedAt: .iso("2026-10-10T20:00:00Z"), plan: "ENTERPRISE", today: .money(cents: 10), meters: meters)
    }

    @Test("B-40 a snapshot has on-demand only with an on-demand meter")
    func snapshotWithOnDemandMeterHasOnDemand() {
        #expect(Self.snapshot([Self.included, Self.onDemand]).hasOnDemand)
        #expect(!Self.snapshot([Self.included]).hasOnDemand)
    }

    @Test("B-40 hiding on-demand removes only its meter")
    func hidingOnDemandKeepsEverythingElse() {
        #expect(Self.snapshot([Self.included, Self.onDemand]).hidingOnDemand() == Self.snapshot([Self.included]))
    }

    @Test("B-40 hiding on-demand without it changes nothing")
    func hidingOnDemandWithoutItChangesNothing() {
        #expect(Self.snapshot([Self.included]).hidingOnDemand() == Self.snapshot([Self.included]))
    }
}
