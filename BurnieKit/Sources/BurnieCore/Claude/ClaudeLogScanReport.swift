import Foundation

/// Counts from a log scan, for the diagnostic log.
public struct ClaudeLogScanReport: Sendable, Equatable {
    public var filesRead = 0
    public var bytesRead = 0
    public var countedLines = 0
    public var duplicateLines = 0
    public var unreadableLines = 0
    public var unreadableFiles = 0
}
