import Foundation
import BurnieCore

public struct LocalFileReader: FileReading {
    public init() {}

    public func list(_ dir: URL, ext: String) throws -> [URL] {
        _ = try dir.checkResourceIsReachable()
        let contents = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        return (contents?.allObjects ?? []).compactMap { $0 as? URL }.filter { $0.pathExtension == ext }
    }

    public func attributes(_ url: URL) throws -> (size: UInt64, modified: Date) {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return ((attributes[.size] as? NSNumber)?.uint64Value ?? 0, attributes[.modificationDate] as? Date ?? .distantPast)
    }

    /// The pool releases `FileHandle`'s temporary buffers on every read; without it they pile up
    /// until the first log scan finishes (330 MB peak versus 224 MB with 500 MB of logs).
    public func read(_ url: URL, from offset: UInt64) throws -> Data {
        try autoreleasepool {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            try handle.seek(toOffset: offset)
            return try handle.readToEnd() ?? Data()
        }
    }
}
