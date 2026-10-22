import BurnieInterface
import Foundation
import SQLite3

/// Reads one row of a key-value table in SQLite without ever writing to the database or copying it (X-6).
///
/// Opens read-only with a timeout; a lock still held when it runs out is `busy`, and the next refresh tries again.
public struct SQLiteKeyValueReader: KeyValueDatabase {
    private let busyTimeoutMilliseconds: Int32

    public init(busyTimeout: Duration = .seconds(2)) {
        busyTimeoutMilliseconds = Int32(busyTimeout / .milliseconds(1))
    }

    public func value(forKey key: String, table: String, at url: URL) throws(KeyValueDatabaseFailure) -> String? {
        // The table name can't be passed as an SQL parameter: only plain identifiers are accepted.
        guard !table.isEmpty, table.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }) else {
            throw .unreadable
        }
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { throw .missing }

        var connection: OpaquePointer?
        defer { sqlite3_close_v2(connection) }
        try check(sqlite3_open_v2(url.absoluteString + "?mode=ro", &connection, SQLITE_OPEN_READONLY | SQLITE_OPEN_URI, nil))
        sqlite3_busy_timeout(connection, busyTimeoutMilliseconds)

        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        try check(sqlite3_prepare_v2(connection, "SELECT value FROM \(table) WHERE key = ?", -1, &statement, nil))
        try check(sqlite3_bind_text(statement, 1, key, -1, Self.transient))

        switch sqlite3_step(statement) {
        case SQLITE_ROW: return sqlite3_column_text(statement, 0).map { String(cString: $0) }
        case SQLITE_DONE: return nil
        case let code: throw Self.failure(code)
        }
    }

    private func check(_ code: Int32) throws(KeyValueDatabaseFailure) {
        guard code == SQLITE_OK else { throw Self.failure(code) }
    }

    private static func failure(_ code: Int32) -> KeyValueDatabaseFailure {
        switch code & 0xFF {
        case SQLITE_BUSY, SQLITE_LOCKED: .busy
        default: .unreadable
        }
    }

    /// Asks SQLite to copy the bound text, because the Swift string doesn't outlive the call.
    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
}
