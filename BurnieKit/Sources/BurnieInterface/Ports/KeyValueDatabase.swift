import Foundation

/// Reads a row of a key-value table in SQLite, read-only, and never copies the database.
public protocol KeyValueDatabase: Sendable {
    /// nil if the row doesn't exist.
    func value(forKey key: String, table: String, at url: URL) throws(KeyValueDatabaseFailure) -> String?
}
