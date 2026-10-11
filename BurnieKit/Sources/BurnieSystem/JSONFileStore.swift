import Foundation
import BurnieCore

/// Burnie's JSON files: atomic writes, 0600 permissions and a 0700 folder.
public struct JSONFileStore: SnapshotStore {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// `~/Library/Application Support/Burnie/`, the only place Burnie writes to.
    public static func applicationSupport() throws -> JSONFileStore {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return JSONFileStore(directory: base.appending(path: "Burnie"))
    }

    public func load<T: Codable>(_ name: String) throws -> T? {
        let url = fileURL(name)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try decoder.decode(T.self, from: Data(contentsOf: url))
    }

    public func save<T: Codable>(_ value: T, as name: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let url = fileURL(name)
        try encoder.encode(value).write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    private func fileURL(_ name: String) -> URL {
        directory.appending(path: name + ".json")
    }

    // Dates as seconds since 1970: readable and exact when read back.
    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .sortedKeys
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}
