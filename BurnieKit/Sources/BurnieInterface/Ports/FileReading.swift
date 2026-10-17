import Foundation

/// Reads files. Never writes.
public protocol FileReading: Sendable {
    /// Files with extension `ext` under `directory`, recursively. Throws if `directory` doesn't exist.
    func list(_ directory: URL, ext: String) throws -> [URL]
    func attributes(_ url: URL) throws -> (size: UInt64, modified: Date)
    /// From `offset` to the end of the file.
    func read(_ url: URL, from offset: UInt64) throws -> Data
    func exists(_ url: URL) -> Bool
    func isExecutable(_ url: URL) -> Bool
}
