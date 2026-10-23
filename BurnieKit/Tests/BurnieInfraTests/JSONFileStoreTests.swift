import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInfra

final class JSONFileStoreTests {
    let directory = FileManager.default.temporaryDirectory.appending(path: "burnie-store-\(UUID().uuidString)/Burnie")
    lazy var store = JSONFileStore(directory: directory)

    deinit {
        try? FileManager.default.removeItem(at: directory.deletingLastPathComponent())
    }

    func snapshot(_ provider: ProviderID, at date: Date) -> UsageSnapshot {
        UsageSnapshot(provider: provider, content: .activityOnly(Stamped(TodayUsage(tokens: Tokens(42)), at: date)))
    }

    func write(_ text: String, to name: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(text.utf8).write(to: directory.appending(path: name))
    }

    @Test("B-19 a snapshot is saved as snapshot-<provider id>.json and read back with exact dates")
    func roundTripsExactDates() throws {
        let saved = snapshot(.alpha, at: Date(timeIntervalSince1970: 1_791_689_041.931_156_2))
        store.save(saved)
        #expect(store.snapshot(for: .alpha) == saved)
        #expect(FileManager.default.fileExists(atPath: directory.appending(path: "snapshot-alpha.json").path))
    }

    @Test("SPEC 12 a snapshot file's dates are seconds since 1970")
    func datesAreSecondsSince1970() throws {
        try write(#"{"content":{"activityOnly":{"at":1791661800,"value":{"tokens":42}}},"provider":"alpha"}"#, to: "snapshot-alpha.json")
        #expect(store.snapshot(for: .alpha) == snapshot(.alpha, at: Date(timeIntervalSince1970: 1_791_661_800)))
    }

    @Test("SPEC 12 a snapshot in the flat shape of before the refactor reads as no cache, never a crash")
    func flatSnapshotReadsAsNoCache() throws {
        try write(#"{"fetchedAt":1791661800,"meters":[],"plan":"PRO","provider":"alpha","today":{"tokens":{"_0":42}}}"#, to: "snapshot-alpha.json")
        #expect(store.snapshot(for: .alpha) == nil)
    }

    @Test("SPEC 12 a history.json that doesn't decode reads as no history, never a crash")
    func undecodableHistoryIsNil() throws {
        try write("not a history", to: "history.json")
        #expect(store.history() == nil)
    }

    @Test func missingFilesAreNil() {
        #expect(store.snapshot(for: .beta) == nil)
        #expect(store.history() == nil)
    }

    @Test("B-42 the history is saved as history.json and read back")
    func historyRoundTrips() {
        var history = UsageHistory()
        history.record([.day("2026-10-10"): Tokens(7)], for: .alpha, today: .day("2026-10-10"))
        store.save(history)
        #expect(store.history() == history)
    }

    @Test("X-4 files are private, written atomically, without leftovers")
    func writesPrivateFilesWithoutLeftovers() throws {
        store.save(UsageHistory())
        store.save(UsageHistory())
        let files = FileManager.default
        #expect(try files.attributesOfItem(atPath: directory.appending(path: "history.json").path)[.posixPermissions] as? Int == 0o600)
        #expect(try files.attributesOfItem(atPath: directory.path)[.posixPermissions] as? Int == 0o700)
        #expect(try files.contentsOfDirectory(atPath: directory.path) == ["history.json"])
    }

    @Test("SPEC 12 a provider's private files are named <provider id>-<name>.json")
    func providerStorageIsPrefixedWithItsID() throws {
        let storage = store.storage(for: .alpha)
        storage.save(["offset": 4_096], named: "log-index")
        #expect(storage.load([String: Int].self, named: "log-index") == ["offset": 4_096])
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path) == ["alpha-log-index.json"])
        #expect(store.storage(for: .beta).load([String: Int].self, named: "log-index") == nil)
    }

    @Test("B-46 a provider's file that doesn't decode loads as nil")
    func undecodableProviderFileIsNil() throws {
        try write("not json", to: "alpha-log-index.json")
        #expect(store.storage(for: .alpha).load([String: Int].self, named: "log-index") == nil)
    }

    @Test("B-73 a store whose folder can't be written ignores the save and keeps running")
    func unwritableFolderIgnoresSaves() throws {
        let file = directory.deletingLastPathComponent().appending(path: "file")
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: file)
        let blocked = JSONFileStore(directory: file.appending(path: "Burnie"))
        blocked.save(UsageHistory())
        #expect(blocked.history() == nil)
    }
}
