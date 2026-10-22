import BurnieInterface
import Foundation

/// A `DiagnosticsLog` that keeps every record, so tests check what reached the log.
/// `lock` serializes `entries`, so tasks can share it.
public final class RecordingDiagnosticsLog: DiagnosticsLog, @unchecked Sendable {
    public struct Record: Sendable {
        public let event: String
        public let measures: [Measure]
    }

    private let lock = NSLock()
    private var entries: [Record] = []

    public var records: [Record] { lock.withLock { entries } }

    public init() {}

    public func record(_ event: StaticString, _ measures: [Measure]) {
        lock.withLock { entries.append(Record(event: "\(event)", measures: measures)) }
    }
}
