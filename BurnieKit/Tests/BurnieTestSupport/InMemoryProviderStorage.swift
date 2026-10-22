import BurnieInterface
import Foundation

/// An in-memory `ProviderStorage` that does go through JSON, so tests exercise the real `Codable`.
/// `lock` serializes `files`, so tasks can share it.
public final class InMemoryProviderStorage: ProviderStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var files: [String: Data] = [:]

    public init() {}

    /// What's saved under `name`, or nil.
    public func contents(named name: String) -> Data? {
        lock.withLock { files[name] }
    }

    /// Puts raw bytes under `name`, like a file another version left.
    public func write(_ contents: Data, named name: String) {
        lock.withLock { files[name] = contents }
    }

    public func load<Value: Decodable>(_ type: Value.Type, named name: String) -> Value? {
        guard let data = contents(named: name) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    public func save<Value: Encodable>(_ value: Value, named name: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        write(data, named: name)
    }
}
