import BurnieInterface
import Foundation

/// An in-memory `FileReading`: files with contents and modification dates the test controls, and the executables it
/// marks.
/// `lock` serializes `files`, `directories` and `executables`, so tasks can share it.
public final class InMemoryFiles: FileReading, @unchecked Sendable {
    private struct File {
        var contents: Data
        var modified: Date
    }

    private let lock = NSLock()
    private var files: [URL: File] = [:]
    private var executables: Set<URL> = []

    public init() {}

    public func write(_ contents: Data, to url: URL, modified: Date) {
        lock.withLock { files[url] = File(contents: contents, modified: modified) }
    }

    public func append(_ contents: Data, to url: URL, modified: Date) {
        lock.withLock {
            files[url]?.contents.append(contents)
            files[url]?.modified = modified
        }
    }

    public func remove(_ url: URL) {
        lock.withLock { _ = files.removeValue(forKey: url) }
    }

    /// Makes `url` an executable that `isExecutable` reports.
    public func installExecutable(_ url: URL) {
        lock.withLock { _ = executables.insert(url) }
    }

    public func list(_ directory: URL, ext: String) throws -> [URL] {
        try lock.withLock {
            let matches = files.keys.filter { isInside($0, directory) && $0.pathExtension == ext }
            guard !matches.isEmpty else { throw CocoaError(.fileNoSuchFile) }
            return matches.sorted { $0.path < $1.path }
        }
    }

    public func attributes(_ url: URL) throws -> (size: UInt64, modified: Date) {
        try lock.withLock {
            guard let file = files[url] else { throw CocoaError(.fileNoSuchFile) }
            return (UInt64(file.contents.count), file.modified)
        }
    }

    public func read(_ url: URL, from offset: UInt64) throws -> Data {
        try lock.withLock {
            guard let file = files[url] else { throw CocoaError(.fileNoSuchFile) }
            return file.contents.subdata(in: Int(offset)..<file.contents.count)
        }
    }

    /// A file, or a directory that holds one.
    public func exists(_ url: URL) -> Bool {
        lock.withLock { files[url] != nil || files.keys.contains { isInside($0, url) } }
    }

    public func isExecutable(_ url: URL) -> Bool {
        lock.withLock { executables.contains(url) }
    }

    private func isInside(_ file: URL, _ directory: URL) -> Bool {
        file.path.hasPrefix(directory.path + "/")
    }
}
