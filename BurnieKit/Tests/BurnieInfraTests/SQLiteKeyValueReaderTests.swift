import BurnieInterface
import Foundation
import SQLite3
import Testing
@testable import BurnieInfra

final class SQLiteKeyValueReaderTests {
    let directory = FileManager.default.temporaryDirectory.appending(path: "burnie-sqlite-\(UUID().uuidString)")
    let database: URL
    let reader = SQLiteKeyValueReader(busyTimeout: .milliseconds(50))

    init() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        database = directory.appending(path: "state.vscdb")
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    /// Opens the test's own write connection, as Cursor would.
    func open(journalMode: String) throws -> OpaquePointer {
        var connection: OpaquePointer?
        guard sqlite3_open(database.path, &connection) == SQLITE_OK, let connection else { throw KeyValueDatabaseFailure.unreadable }
        try execute("PRAGMA journal_mode=\(journalMode)", on: connection)
        try execute("CREATE TABLE IF NOT EXISTS ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB)", on: connection)
        return connection
    }

    func execute(_ sql: String, on connection: OpaquePointer) throws {
        guard sqlite3_exec(connection, sql, nil, nil, nil) == SQLITE_OK else { throw KeyValueDatabaseFailure.unreadable }
    }

    /// The bytes of the database and of its write-ahead log, which only the app that owns them may change.
    func databaseAndLog() throws -> [Data] {
        try [database, URL(filePath: database.path + "-wal")].map { try Data(contentsOf: $0) }
    }

    /// The names of the files next to the database.
    func filesInFolder() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
    }

    @Test func readsAValueAndNilForAMissingKey() throws {
        let writer = try open(journalMode: "WAL")
        defer { sqlite3_close(writer) }
        try execute("INSERT INTO ItemTable VALUES ('cursorAuth/accessToken', 'header.payload.signature')", on: writer)

        #expect(try reader.value(forKey: "cursorAuth/accessToken", table: "ItemTable", at: database) == "header.payload.signature")
        #expect(try reader.value(forKey: "cursorAuth/refreshToken", table: "ItemTable", at: database) == nil)
    }

    @Test("B-26 B-62 a database still locked when the timeout runs out is busy, and nothing is copied")
    func lockedDatabaseIsBusyAndNeverCopied() throws {
        let writer = try open(journalMode: "DELETE")
        defer { sqlite3_close(writer) }
        try execute("INSERT INTO ItemTable VALUES ('cursorAuth/accessToken', 'committed')", on: writer)
        try execute("BEGIN EXCLUSIVE", on: writer)
        defer { try? execute("ROLLBACK", on: writer) }
        let before = try filesInFolder()

        #expect(throws: KeyValueDatabaseFailure.busy) {
            try self.reader.value(forKey: "cursorAuth/accessToken", table: "ItemTable", at: self.database)
        }
        #expect(try filesInFolder() == before)
    }

    @Test func readsRowsStillInTheWriteAheadLog() throws {
        let writer = try open(journalMode: "WAL")
        defer { sqlite3_close(writer) }
        try execute("PRAGMA wal_autocheckpoint=0", on: writer)
        try execute("INSERT INTO ItemTable VALUES ('cursorAuth/accessToken', 'only-in-wal')", on: writer)

        #expect(try reader.value(forKey: "cursorAuth/accessToken", table: "ItemTable", at: database) == "only-in-wal")
    }

    @Test("B-62 reading state.vscdb while its app writes never changes it")
    func readingLeavesTheDatabaseAsItWas() throws {
        let writer = try open(journalMode: "WAL")
        defer { sqlite3_close(writer) }
        try execute("PRAGMA wal_autocheckpoint=0", on: writer)
        try execute("INSERT INTO ItemTable VALUES ('cursorAuth/accessToken', 'only-in-wal')", on: writer)
        let before = try databaseAndLog()

        _ = try reader.value(forKey: "cursorAuth/accessToken", table: "ItemTable", at: database)
        #expect(try databaseAndLog() == before)
    }

    @Test("B-62 reading state.vscdb while its app is closed leaves its folder as it was")
    func readingWithTheAppClosedLeavesTheFolderAsItWas() throws {
        let writer = try open(journalMode: "WAL")
        try execute("INSERT INTO ItemTable VALUES ('cursorAuth/accessToken', 'committed')", on: writer)
        sqlite3_close(writer)
        let before = try filesInFolder()
        let bytes = try Data(contentsOf: database)

        #expect(try reader.value(forKey: "cursorAuth/accessToken", table: "ItemTable", at: database) == "committed")
        #expect(try filesInFolder() == before)
        #expect(try Data(contentsOf: database) == bytes)
    }

    @Test("B-26 a database that isn't there is missing")
    func missingDatabaseIsMissing() {
        #expect(throws: KeyValueDatabaseFailure.missing) {
            try self.reader.value(forKey: "cursorAuth/accessToken", table: "ItemTable", at: self.directory.appending(path: "missing.vscdb"))
        }
    }

    @Test("B-26 a file that isn't a database is unreadable")
    func fileThatIsNotADatabaseIsUnreadable() throws {
        try Data("not a database".utf8).write(to: database)
        #expect(throws: KeyValueDatabaseFailure.unreadable) {
            try self.reader.value(forKey: "cursorAuth/accessToken", table: "ItemTable", at: self.database)
        }
    }

    @Test func rejectsTableNamesThatAreNotPlainIdentifiers() {
        #expect(throws: KeyValueDatabaseFailure.unreadable) {
            try self.reader.value(forKey: "k", table: "ItemTable; DROP TABLE x", at: self.database)
        }
    }
}
