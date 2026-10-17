import Foundation
import SQLite3
import Testing
@testable import BurnieSystem

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
        guard sqlite3_open(database.path, &connection) == SQLITE_OK, let connection else { throw SQLiteKeyValueReader.Failure.cannotOpen }
        try execute("PRAGMA journal_mode=\(journalMode)", on: connection)
        try execute("CREATE TABLE IF NOT EXISTS ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB)", on: connection)
        return connection
    }

    func execute(_ sql: String, on connection: OpaquePointer) throws {
        guard sqlite3_exec(connection, sql, nil, nil, nil) == SQLITE_OK else {
            throw SQLiteKeyValueReader.Failure.sqlite(code: sqlite3_errcode(connection))
        }
    }

    /// The bytes of the database and of its write-ahead log, which only the app that owns them may change.
    func databaseAndLog() throws -> [Data] {
        try [database, URL(filePath: database.path + "-wal")].map { try Data(contentsOf: $0) }
    }

    @Test func readsAValueAndNilForAMissingKey() throws {
        let writer = try open(journalMode: "WAL")
        defer { sqlite3_close(writer) }
        try execute("INSERT INTO ItemTable VALUES ('cursorAuth/accessToken', 'header.payload.signature')", on: writer)

        #expect(try reader.value(forKey: "cursorAuth/accessToken", table: "ItemTable", at: database) == "header.payload.signature")
        #expect(try reader.value(forKey: "cursorAuth/refreshToken", table: "ItemTable", at: database) == nil)
    }

    @Test func fallsBackToACopyWhileTheDatabaseIsLocked() throws {
        let writer = try open(journalMode: "DELETE")
        defer { sqlite3_close(writer) }
        try execute("INSERT INTO ItemTable VALUES ('cursorAuth/accessToken', 'committed')", on: writer)
        try execute("BEGIN EXCLUSIVE", on: writer)
        defer { try? execute("ROLLBACK", on: writer) }

        #expect(try reader.value(forKey: "cursorAuth/accessToken", table: "ItemTable", at: database) == "committed")
    }

    @Test func copyIncludesRowsStillInTheWriteAheadLog() throws {
        let writer = try open(journalMode: "WAL")
        defer { sqlite3_close(writer) }
        try execute("PRAGMA wal_autocheckpoint=0", on: writer)
        try execute("INSERT INTO ItemTable VALUES ('cursorAuth/accessToken', 'only-in-wal')", on: writer)

        #expect(try reader.valueFromCopy(forKey: "cursorAuth/accessToken", table: "ItemTable", of: database) == "only-in-wal")
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: directory.path).filter { !$0.hasPrefix("state.vscdb") }
        #expect(leftovers.isEmpty)
    }

    @Test("B-62 reading state.vscdb never changes it, not even through the copy")
    func readingLeavesTheDatabaseAsItWas() throws {
        let writer = try open(journalMode: "WAL")
        defer { sqlite3_close(writer) }
        try execute("PRAGMA wal_autocheckpoint=0", on: writer)
        try execute("INSERT INTO ItemTable VALUES ('cursorAuth/accessToken', 'only-in-wal')", on: writer)
        let before = try databaseAndLog()

        _ = try reader.value(forKey: "cursorAuth/accessToken", table: "ItemTable", at: database)
        _ = try reader.valueFromCopy(forKey: "cursorAuth/accessToken", table: "ItemTable", of: database)
        #expect(try databaseAndLog() == before)
    }

    @Test func missingDatabaseThrows() {
        #expect(throws: (any Error).self) {
            try self.reader.value(forKey: "cursorAuth/accessToken", table: "ItemTable", at: self.directory.appending(path: "missing.vscdb"))
        }
    }

    @Test func rejectsTableNamesThatAreNotPlainIdentifiers() {
        #expect(throws: SQLiteKeyValueReader.Failure.invalidTable("ItemTable; DROP TABLE x")) {
            try self.reader.value(forKey: "k", table: "ItemTable; DROP TABLE x", at: self.database)
        }
    }
}
