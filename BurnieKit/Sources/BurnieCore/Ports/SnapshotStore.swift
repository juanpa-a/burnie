import Foundation

/// Burnie's small JSON files in `~/Library/Application Support/Burnie/`.
public protocol SnapshotStore: Sendable {
    /// nil if the file doesn't exist.
    func load<T: Codable>(_ name: String) throws -> T?
    func save<T: Codable>(_ value: T, as name: String) throws
}
