import Foundation
import Testing
@testable import BurnieSystem
import BurnieCore

final class JSONFileStoreTests {
    let directory = FileManager.default.temporaryDirectory.appending(path: "burnie-store-\(UUID().uuidString)/Burnie")
    lazy var store = JSONFileStore(directory: directory)

    deinit {
        try? FileManager.default.removeItem(at: directory.deletingLastPathComponent())
    }

    @Test func roundTripsExactDates() throws {
        let snapshot = UsageSnapshot(provider: .claude, fetchedAt: Date(timeIntervalSince1970: 1_791_689_041.931_156_2), plan: "PRO", tokensToday: 42)
        try store.save(snapshot, as: "snapshot-claude")
        #expect(try store.load("snapshot-claude") == snapshot)
    }

    @Test func missingFileIsNil() throws {
        let missing: UsageSnapshot? = try store.load("snapshot-cursor")
        #expect(missing == nil)
    }

    @Test func writesPrivateFilesWithoutLeftovers() throws {
        try store.save(UsageHistory(), as: "history")
        try store.save(UsageHistory(), as: "history")
        let files = FileManager.default
        #expect(try files.attributesOfItem(atPath: directory.appending(path: "history.json").path)[.posixPermissions] as? Int == 0o600)
        #expect(try files.attributesOfItem(atPath: directory.path)[.posixPermissions] as? Int == 0o700)
        #expect(try files.contentsOfDirectory(atPath: directory.path) == ["history.json"])
    }
}
