import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieProviders

struct ClaudeLogActivityTests {
    /// What `claude-log-basic.jsonl` adds up to when it's read from scratch.
    static let basicLogTokens: [LocalDay: Tokens] = [.day("2026-10-10"): Tokens(75_617), .day("2026-10-09"): Tokens(1_500)]

    let files = InMemoryFiles()
    let storage = InMemoryProviderStorage()
    let log = RecordingDiagnosticsLog()
    let clock = FixedClock(now: .iso("2026-10-10T20:00:00Z"))

    func activity(saving storage: any ProviderStorage) -> ClaudeLogActivity {
        ClaudeLogActivity(roots: [ClaudeLogScannerTests.root], files: files, storage: storage, clock: clock, log: log)
    }

    func activity() -> ClaudeLogActivity {
        activity(saving: storage)
    }

    func writeBasicLog() {
        files.write(Fixture.data("claude-log-basic.jsonl"), to: ClaudeLogScannerTests.sessionFile, modified: ClaudeLogScannerTests.recently)
    }

    /// How many files each scan recorded in the diagnostics log that it read.
    func filesReadPerScan() -> [Int] {
        log.records.filter { $0.event == "logScan" }.compactMap { record in
            record.measures.lazy.compactMap { measure -> Int? in
                guard case .count(let name, let count) = measure, "\(name)" == "filesRead" else { return nil }
                return count
            }.first
        }
    }

    @Test("B-44 after a restart the scan resumes from the saved index and reads only what's new")
    func resumesFromTheSavedIndexAfterARestart() async throws {
        writeBasicLog()
        _ = try await activity().activity()

        files.write(Fixture.data("claude-log-dupes.jsonl"), to: ClaudeLogScannerTests.otherFile, modified: ClaudeLogScannerTests.recently)
        let afterRestart = try await activity().activity().tokens

        #expect(afterRestart == [.day("2026-10-10"): Tokens(76_917), .day("2026-10-09"): Tokens(1_500)])
        #expect(filesReadPerScan() == [1, 1])
    }

    @Test("B-64 a scan records only counts in the diagnostics log")
    func aScanRecordsOnlyCounts() async throws {
        writeBasicLog()
        _ = try await activity().activity()
        let record = try #require(log.records.first)
        #expect(record.event == "logScan")
        #expect(record.measures.count == 6)
    }

    @Test("B-46 an unreadable log index is discarded and rebuilt from the logs")
    func unreadableIndexIsRebuiltFromTheLogs() async throws {
        writeBasicLog()
        storage.write(Data("not an index".utf8), named: ClaudeLogActivity.indexName)

        #expect(try await activity().activity().tokens == Self.basicLogTokens)
        let saved = storage.load(ClaudeLogIndex.self, named: ClaudeLogActivity.indexName)
        #expect(saved?.dailyTokens(in: ActivityWindow.days(endingAt: .day("2026-10-10"))) == Self.basicLogTokens.mapValues(\.count))
    }

    @Test("B-46 a log index is resumed only if it's this version's; another version's is rebuilt from the logs", arguments: [
        (ClaudeLogIndex.currentVersion, [.day("2026-10-10"): Tokens(1)]),
        (0, basicLogTokens),
        (ClaudeLogIndex.currentVersion + 1, basicLogTokens),
    ] as [(Int, [LocalDay: Tokens])])
    func resumesOnlyAnIndexOfThisVersion(version: Int, tokens: [LocalDay: Tokens]) async throws {
        writeBasicLog()
        // It claims the whole log was read and that it held 1 token, so resuming from it reads nothing and shows 1.
        let size = UInt64(Fixture.data("claude-log-basic.jsonl").count)
        let progress = ClaudeLogIndex.FileProgress(offset: size, size: size, mtime: ClaudeLogScannerTests.recently, days: [.day("2026-10-10"): 1])
        storage.save(SavedIndex(version: version, files: [ClaudeLogScannerTests.sessionFile.path: progress]), named: ClaudeLogActivity.indexName)

        #expect(try await activity().activity().tokens == tokens)
    }

    @Test("B-46 a failed index save still returns the activity")
    func failedIndexSaveStillReturnsTheActivity() async throws {
        writeBasicLog()
        #expect(try await activity(saving: UnwritableStorage()).activity().tokens == Self.basicLogTokens)
    }

    @Test("B-45 without any log root, Claude's activity is not found")
    func withoutLogsIsNotFound() async {
        await #expect(throws: ProviderIssue.notFound) { try await activity().activity() }
    }

    /// The index file as any version of Burnie writes it: a version and each file's progress.
    private struct SavedIndex: Codable {
        let version: Int
        let files: [String: ClaudeLogIndex.FileProgress]
    }

    /// Storage with nothing saved whose every save is lost, like a full or read-only disk.
    private struct UnwritableStorage: ProviderStorage {
        func load<Value: Decodable>(_ type: Value.Type, named name: String) -> Value? {
            nil
        }

        func save<Value: Encodable>(_ value: Value, named name: String) {}
    }
}
