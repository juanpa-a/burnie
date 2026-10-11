import Foundation
@testable import BurnieCore

/// In-memory `FileReading`: files with contents and modification dates the test controls.
final class InMemoryFiles: FileReading, @unchecked Sendable {
    private struct File {
        var contents: Data
        var modified: Date
    }

    private let lock = NSLock()
    private var files: [URL: File] = [:]
    private(set) var reads: [URL] = []

    func write(_ contents: Data, to url: URL, modified: Date) {
        lock.withLock { files[url] = File(contents: contents, modified: modified) }
    }

    func append(_ contents: Data, to url: URL, modified: Date) {
        lock.withLock {
            files[url]!.contents.append(contents)
            files[url]!.modified = modified
        }
    }

    func remove(_ url: URL) {
        lock.withLock { _ = files.removeValue(forKey: url) }
    }

    func list(_ dir: URL, ext: String) throws -> [URL] {
        try lock.withLock {
            let prefix = dir.path + "/"
            let matches = files.keys.filter { $0.path.hasPrefix(prefix) && $0.pathExtension == ext }
            guard !matches.isEmpty else { throw CocoaError(.fileNoSuchFile) }
            return matches.sorted { $0.path < $1.path }
        }
    }

    func attributes(_ url: URL) throws -> (size: UInt64, modified: Date) {
        try lock.withLock {
            guard let file = files[url] else { throw CocoaError(.fileNoSuchFile) }
            return (UInt64(file.contents.count), file.modified)
        }
    }

    func read(_ url: URL, from offset: UInt64) throws -> Data {
        try lock.withLock {
            guard let file = files[url] else { throw CocoaError(.fileNoSuchFile) }
            reads.append(url)
            return file.contents.subdata(in: Int(offset)..<file.contents.count)
        }
    }
}
