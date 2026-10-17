import BurnieDomain
import BurnieInterface
import Foundation

/// Burnie's own JSON files: the snapshots and the history (`SnapshotCache`), and each provider's private files
/// (`storage(for:)`). Atomic writes, 0600 files in a 0700 folder; dates as seconds since 1970, readable and exact when
/// read back (SPEC section 12).
public struct JSONFileStore: SnapshotCache {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// `~/Library/Application Support/Burnie/`, the only place Burnie writes to (X-4).
    public static func applicationSupport() throws -> JSONFileStore {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return JSONFileStore(directory: base.appending(path: "Burnie"))
    }

    /// One provider's private files, saved as `<provider id>-<name>.json`.
    public func storage(for provider: ProviderID) -> some ProviderStorage {
        ProviderFiles(store: self, prefix: provider.rawValue + "-")
    }

    public func snapshot(for provider: ProviderID) -> UsageSnapshot? {
        load(UsageSnapshot.self, named: "snapshot-" + provider.rawValue)
    }

    public func save(_ snapshot: UsageSnapshot) {
        save(snapshot, named: "snapshot-" + snapshot.provider.rawValue)
    }

    public func history() -> UsageHistory? {
        load(UsageHistory.self, named: "history")
    }

    public func save(_ history: UsageHistory) {
        save(history, named: "history")
    }

    /// nil when the file is missing or doesn't decode, like a snapshot saved in an older shape.
    func load<Value: Decodable>(_ type: Value.Type, named name: String) -> Value? {
        guard let data = try? Data(contentsOf: fileURL(name)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(type, from: data)
    }

    /// A failed save is ignored: the next one retries.
    func save<Value: Encodable>(_ value: Value, named name: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .sortedKeys
        let files = FileManager.default
        guard let data = try? encoder.encode(value),
              (try? files.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])) != nil,
              (try? data.write(to: fileURL(name), options: .atomic)) != nil
        else { return }
        try? files.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL(name).path)
    }

    private func fileURL(_ name: String) -> URL {
        directory.appending(path: name + ".json")
    }

    /// A provider's files, every name under its prefix.
    private struct ProviderFiles: ProviderStorage {
        let store: JSONFileStore
        let prefix: String

        func load<Value: Decodable>(_ type: Value.Type, named name: String) -> Value? {
            store.load(type, named: prefix + name)
        }

        func save<Value: Encodable>(_ value: Value, named name: String) {
            store.save(value, named: prefix + name)
        }
    }
}
