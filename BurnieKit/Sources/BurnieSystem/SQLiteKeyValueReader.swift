import Foundation
import BurnieCore
import SQLite3

/// Reads one row of a key-value table in SQLite without ever writing to the original database.
///
/// Opens read-only with a timeout; if the database is busy or won't open, copies the database
/// and its WAL to a private temporary directory (0700), reads the copy and deletes it.
public struct SQLiteKeyValueReader: KeyValueDatabase {
    public enum Failure: Error, Equatable {
        case invalidTable(String)
        case busy
        case cannotOpen
        case sqlite(code: Int32)
    }

    private let busyTimeoutMilliseconds: Int32

    public init(busyTimeout: Duration = .seconds(2)) {
        busyTimeoutMilliseconds = Int32(busyTimeout / .milliseconds(1))
    }

    public func value(forKey key: String, table: String, at url: URL) throws -> String? {
        // The table name can't be passed as an SQL parameter: only plain identifiers are accepted.
        guard !table.isEmpty, table.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }) else {
            throw Failure.invalidTable(table)
        }
        do {
            return try query(key, table: table, at: url.absoluteString + "?mode=ro", flags: SQLITE_OPEN_READONLY)
        } catch Failure.busy, Failure.cannotOpen {
            return try valueFromCopy(forKey: key, table: table, of: url)
        }
    }

    func valueFromCopy(forKey key: String, table: String, of url: URL) throws -> String? {
        let files = FileManager.default
        let directory = try files.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: url, create: true)
        defer { try? files.removeItem(at: directory) }
        try files.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)

        let copy = directory.appending(path: url.lastPathComponent)
        try files.copyItem(at: url, to: copy)
        let wal = URL(filePath: url.path + "-wal")
        if files.fileExists(atPath: wal.path) {
            try files.copyItem(at: wal, to: URL(filePath: copy.path + "-wal"))
        }
        // The copy is ours: it's opened read-write so SQLite can apply the WAL.
        return try query(key, table: table, at: copy.absoluteString, flags: SQLITE_OPEN_READWRITE)
    }

    private func query(_ key: String, table: String, at uri: String, flags: Int32) throws -> String? {
        var connection: OpaquePointer?
        defer { sqlite3_close_v2(connection) }
        try check(sqlite3_open_v2(uri, &connection, flags | SQLITE_OPEN_URI, nil))
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

    private func check(_ code: Int32) throws {
        guard code == SQLITE_OK else { throw Self.failure(code) }
    }

    private static func failure(_ code: Int32) -> Failure {
        switch code & 0xFF {
        case SQLITE_BUSY, SQLITE_LOCKED: .busy
        case SQLITE_CANTOPEN: .cannotOpen
        default: .sqlite(code: code)
        }
    }

    /// Asks SQLite to copy the bound text, because the Swift string doesn't outlive the call.
    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
}
