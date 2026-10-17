import BurnieCore
import Foundation

/// `KeyValueDatabase` with the rows the test sets, or a failure for every read.
public struct FakeKeyValueDatabase: KeyValueDatabase {
    public var rows: [String: String]
    public var failure: Error?

    public init(rows: [String: String] = [:], failure: Error? = nil) {
        self.rows = rows
        self.failure = failure
    }

    public func value(forKey key: String, table: String, at url: URL) throws -> String? {
        if let failure { throw failure }
        return rows[key]
    }
}
