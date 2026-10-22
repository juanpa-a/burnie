import BurnieInterface
import Foundation

/// Counts from a log scan, for the diagnostics log.
struct ClaudeLogScanReport: Sendable, Equatable {
    var filesRead = 0
    var bytesRead = 0
    var countedLines = 0
    var duplicateLines = 0
    var unreadableLines = 0
    var unreadableFiles = 0

    /// Numbers only, so nothing from the logs reaches the diagnostics log (B-64).
    func record(to log: any DiagnosticsLog) {
        log.record("logScan", [
            .count("filesRead", filesRead),
            .bytes("bytesRead", bytesRead),
            .count("countedLines", countedLines),
            .count("duplicateLines", duplicateLines),
            .count("unreadableLines", unreadableLines),
            .count("unreadableFiles", unreadableFiles),
        ])
    }
}
