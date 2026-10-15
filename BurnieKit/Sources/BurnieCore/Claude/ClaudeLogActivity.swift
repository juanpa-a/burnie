import Foundation

/// Claude's activity source: tokens per day from the local logs, with incremental scans.
public actor ClaudeLogActivity: ActivitySource {
    static let indexName = "claude-log-index"

    private let scanner: ClaudeLogScanner
    private let store: SnapshotStore
    private let clock: Clock
    private let onScan: @Sendable (ClaudeLogScanReport) -> Void
    private var index: ClaudeLogIndex?

    public init(
        roots: [URL],
        files: FileReading,
        store: SnapshotStore,
        clock: Clock,
        onScan: @escaping @Sendable (ClaudeLogScanReport) -> Void = { _ in }
    ) {
        scanner = ClaudeLogScanner(files: files, roots: roots)
        self.store = store
        self.clock = clock
        self.onScan = onScan
    }

    public func activity() throws(ProviderIssue) -> ActivityReading {
        let calendar = Calendar.gregorian(in: clock.timeZone)
        let window = ActivityWindow.days(endingAt: LocalDay(clock.now, in: calendar))
        let previous = index ?? savedIndex()
        var updated = previous
        let report = try scanner.scan(&updated, window: window, calendar: calendar)
        index = updated
        onScan(report)
        if updated != previous {
            // If it can't be saved, the next launch just rescans the window.
            try? store.save(updated, as: Self.indexName)
        }
        // The logs carry no prices, so Claude's reading never has spend.
        return ActivityReading(tokens: updated.dailyTokens(in: window))
    }

    /// An unreadable index, or one from another version, is discarded and rebuilt from the logs.
    private func savedIndex() -> ClaudeLogIndex {
        ((try? store.load(Self.indexName)) as ClaudeLogIndex?) ?? ClaudeLogIndex()
    }
}
