import Foundation

/// Why the key-value database port read nothing (B-26).
public enum KeyValueDatabaseFailure: Error, Hashable, Sendable {
    /// There's no database file.
    case missing
    /// Its app still held the lock when the timeout ran out.
    case busy
    /// Anything else: a file that isn't a database, a table that isn't there, a name that isn't a plain identifier.
    case unreadable
}
