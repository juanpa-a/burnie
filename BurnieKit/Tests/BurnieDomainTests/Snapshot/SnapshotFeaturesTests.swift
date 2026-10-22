import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct SnapshotFeaturesTests {
    static let onDemand = Meter(id: .extra, fill: .zero, value: .money(used: .zero, limit: Cents(1_000)), caption: .onDemandIdle)

    @Test("B-40 a snapshot has on-demand only with an on-demand meter")
    func hasOnDemandOnlyWithItsMeter() {
        #expect(SnapshotFeatures(onDemand: Self.onDemand).has(.onDemand))
        #expect(!SnapshotFeatures.empty.has(.onDemand))
    }

    @Test("B-40 hiding on-demand removes it; hiding nothing keeps it")
    func hidingOnDemandRemovesIt() {
        let features = SnapshotFeatures(onDemand: Self.onDemand)
        #expect(features.hiding([.onDemand]) == .empty)
        #expect(features.hiding([]) == features)
    }

    @Test func encodesItsFeaturesByName() throws {
        #expect(String(decoding: try JSONEncoder.persistence.encode(SnapshotFeatures.empty), as: UTF8.self) == "{}")
    }
}
