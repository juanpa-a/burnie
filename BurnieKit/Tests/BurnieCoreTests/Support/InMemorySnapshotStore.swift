import Foundation
@testable import BurnieCore

/// In-memory `SnapshotStore` that does go through JSON, so tests exercise the real Codable.
final class InMemorySnapshotStore: SnapshotStore, @unchecked Sendable {
    private let lock = NSLock()
    private var files: [String: Data] = [:]

    func load<T: Codable>(_ name: String) throws -> T? {
        guard let data = lock.withLock({ files[name] }) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func save<T: Codable>(_ value: T, as name: String) throws {
        let data = try JSONEncoder().encode(value)
        lock.withLock { files[name] = data }
    }
}
