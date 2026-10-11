import Foundation

public protocol FileReading: Sendable {
    /// Files with extension `ext` under `dir`, recursively. Throws if `dir` doesn't exist.
    func list(_ dir: URL, ext: String) throws -> [URL]
    func attributes(_ url: URL) throws -> (size: UInt64, modified: Date)
    /// From `offset` to the end of the file.
    func read(_ url: URL, from offset: UInt64) throws -> Data
}
