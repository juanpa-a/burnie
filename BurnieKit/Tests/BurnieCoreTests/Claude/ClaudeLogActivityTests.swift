import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct ClaudeLogActivityTests {
    /// What `claude-log-basic.jsonl` adds up to when it's read from scratch.
    static let basicLogTokens: [LocalDay: Int] = [.day("2026-10-10"): 75_617, .day("2026-10-09"): 1_500]

    let files = InMemoryFiles()
    let store = InMemorySnapshotStore()
    let clock = FixedClock(now: .iso("2026-10-10T20:00:00Z"))

    func activity(onScan: @escaping @Sendable (ClaudeLogScanReport) -> Void = { _ in }) -> ClaudeLogActivity {
        activity(saving: store, onScan: onScan)
    }

    func activity(saving store: any SnapshotStore, onScan: @escaping @Sendable (ClaudeLogScanReport) -> Void = { _ in }) -> ClaudeLogActivity {
        ClaudeLogActivity(roots: [ClaudeLogScannerTests.root], files: files, store: store, clock: clock, onScan: onScan)
    }

    func writeBasicLog() {
        files.write(Fixture.data("claude-log-basic.jsonl"), to: ClaudeLogScannerTests.sessionFile, modified: ClaudeLogScannerTests.recently)
    }

    @Test("B-44 after a restart the scan resumes from the saved index and reads only what's new")
    func resumesFromTheSavedIndexAfterARestart() async throws {
        files.write(Fixture.data("claude-log-basic.jsonl"), to: ClaudeLogScannerTests.sessionFile, modified: ClaudeLogScannerTests.recently)
        _ = try await activity().activity()

        files.write(Fixture.data("claude-log-dupes.jsonl"), to: ClaudeLogScannerTests.otherFile, modified: ClaudeLogScannerTests.recently)
        let reports = Reports()
        let afterRestart = try await activity(onScan: reports.append).activity().tokens

        #expect(afterRestart == [.day("2026-10-10"): 76_917, .day("2026-10-09"): 1_500])
        #expect(reports.all.map(\.filesRead) == [1])
    }

    @Test("B-46 an unreadable log index is discarded and rebuilt from the logs")
    func unreadableIndexIsRebuiltFromTheLogs() async throws {
        writeBasicLog()
        try store.save("not an index", as: ClaudeLogActivity.indexName)

        #expect(try await activity().activity().tokens == Self.basicLogTokens)
        let saved: ClaudeLogIndex? = try store.load(ClaudeLogActivity.indexName)
        #expect(saved?.dailyTokens(in: ActivityWindow.days(endingAt: .day("2026-10-10"))) == Self.basicLogTokens)
    }

    @Test("B-46 a log index is resumed only if it's this version's; another version's is rebuilt from the logs", arguments: [
        (ClaudeLogIndex.currentVersion, [.day("2026-10-10"): 1]),
        (0, basicLogTokens),
        (ClaudeLogIndex.currentVersion + 1, basicLogTokens),
    ] as [(Int, [LocalDay: Int])])
    func resumesOnlyAnIndexOfThisVersion(version: Int, tokens: [LocalDay: Int]) async throws {
        writeBasicLog()
        // It claims the whole log was read and that it held 1 token, so resuming from it reads nothing and shows 1.
        let size = UInt64(Fixture.data("claude-log-basic.jsonl").count)
        let progress = ClaudeLogIndex.FileProgress(offset: size, size: size, mtime: ClaudeLogScannerTests.recently, days: [.day("2026-10-10"): 1])
        try store.save(SavedIndex(version: version, files: [ClaudeLogScannerTests.sessionFile.path: progress]), as: ClaudeLogActivity.indexName)

        #expect(try await activity().activity().tokens == tokens)
    }

    @Test("B-46 a failed index save still returns the activity")
    func failedIndexSaveStillReturnsTheActivity() async throws {
        writeBasicLog()
        #expect(try await activity(saving: UnwritableStore()).activity().tokens == Self.basicLogTokens)
    }

    /// The index file as any version of Burnie writes it: a version and each file's progress.
    private struct SavedIndex: Codable {
        let version: Int
        let files: [String: ClaudeLogIndex.FileProgress]
    }

    /// A store with nothing saved whose every save fails, like a full or read-only disk.
    private struct UnwritableStore: SnapshotStore {
        func load<T: Codable>(_ name: String) throws -> T? {
            nil
        }

        func save<T: Codable>(_ value: T, as name: String) throws {
            throw CocoaError(.fileWriteNoPermission)
        }
    }

    // `lock` serializes `reports`, which the scanner's callback appends to from any task.
    private final class Reports: @unchecked Sendable {
        private let lock = NSLock()
        private var reports: [ClaudeLogScanReport] = []

        var all: [ClaudeLogScanReport] { lock.withLock { reports } }

        func append(_ report: ClaudeLogScanReport) {
            lock.withLock { reports.append(report) }
        }
    }
}
