import Foundation
import Testing
@testable import BurnieCore

struct ClaudeLogActivityTests {
    let files = InMemoryFiles()
    let store = InMemorySnapshotStore()
    let clock = FixedClock(now: .iso("2026-10-10T20:00:00Z"))

    func activity(onScan: @escaping @Sendable (ClaudeLogScanReport) -> Void = { _ in }) -> ClaudeLogActivity {
        ClaudeLogActivity(roots: [ClaudeLogScannerTests.root], files: files, store: store, clock: clock, onScan: onScan)
    }

    @Test func resumesFromTheSavedIndexAfterARestart() async throws {
        files.write(Fixture.data("claude-log-basic.jsonl"), to: ClaudeLogScannerTests.sessionFile, modified: ClaudeLogScannerTests.recently)
        _ = try await activity().dailyTokens()

        files.write(Fixture.data("claude-log-dupes.jsonl"), to: ClaudeLogScannerTests.otherFile, modified: ClaudeLogScannerTests.recently)
        let reports = Reports()
        let afterRestart = try await activity(onScan: reports.append).dailyTokens()

        #expect(afterRestart == [.day("2026-10-10"): 76_917, .day("2026-10-09"): 1_500])
        #expect(reports.all.map(\.filesRead) == [1])
    }
}

private final class Reports: @unchecked Sendable {
    private let lock = NSLock()
    private var reports: [ClaudeLogScanReport] = []

    var all: [ClaudeLogScanReport] { lock.withLock { reports } }

    func append(_ report: ClaudeLogScanReport) {
        lock.withLock { reports.append(report) }
    }
}
