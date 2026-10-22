import BurnieInterface
import Foundation

/// A `KeyValueDatabase` with the rows the test sets, or a failure for every read.
public struct FakeKeyValueDatabase: KeyValueDatabase {
    public var rows: [String: String]
    public var failure: (any Error & Sendable)?

    public init(rows: [String: String] = [:], failure: (any Error & Sendable)? = nil) {
        self.rows = rows
        self.failure = failure
    }

    public func value(forKey key: String, table: String, at url: URL) throws -> String? {
        if let failure { throw failure }
        return rows[key]
    }
}
