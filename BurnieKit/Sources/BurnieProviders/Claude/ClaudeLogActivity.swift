import BurnieDomain
import BurnieInterface
import Foundation

/// Claude's activity: tokens per day from the local logs, scanned incrementally (B-44). The log index is a memo
/// (P-5): losing it only costs a full rescan of the window (B-46).
actor ClaudeLogActivity {
    /// Saved as `claude-log-index.json` (SPEC section 12).
    static let indexName = "log-index"

    private let scanner: ClaudeLogScanner
    private let storage: any ProviderStorage
    private let clock: any Clock
    private let log: any DiagnosticsLog
    private var index: ClaudeLogIndex?

    init(roots: [URL], files: any FileReading, storage: any ProviderStorage, clock: any Clock, log: any DiagnosticsLog) {
        scanner = ClaudeLogScanner(files: files, roots: roots)
        self.storage = storage
        self.clock = clock
        self.log = log
    }

    func activity() throws(ProviderIssue) -> ActivityPart {
        let calendar = Calendar.gregorian(in: clock.timeZone)
        let window = ActivityWindow.days(endingAt: LocalDay(clock.now, in: calendar))
        let previous = index ?? savedIndex()
        var updated = previous
        let report = try scanner.scan(&updated, window: window, calendar: calendar)
        index = updated
        report.record(to: log)
        if updated != previous {
            storage.save(updated, named: Self.indexName)
        }
        // The logs carry no prices, so Claude's activity never has spend.
        return ActivityPart(tokens: updated.dailyTokens(in: window).mapValues(Tokens.init))
    }

    /// An unreadable index, or one from another version, is discarded and rebuilt from the logs.
    private func savedIndex() -> ClaudeLogIndex {
        storage.load(ClaudeLogIndex.self, named: Self.indexName) ?? ClaudeLogIndex()
    }
}
