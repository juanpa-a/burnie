import Foundation
@testable import BurnieCore

struct FakeKeyValueDatabase: KeyValueDatabase {
    var rows: [String: String] = [:]
    var failure: Error?

    func value(forKey key: String, table: String, at url: URL) throws -> String? {
        if let failure { throw failure }
        return rows[key]
    }
}
