import Foundation

/// Incremental index of Claude Code's logs, persisted in `claude-log-index.json`.
///
/// Each file keeps how far it was read, its tokens per day, and the message keys it counted.
/// The global set of counted messages is the union of those keys: that way, when a truncated file
/// is reset, its messages are free to be recounted without duplicating or losing any.
public struct ClaudeLogIndex: Codable, Sendable, Equatable {
    struct FileProgress: Codable, Sendable, Equatable {
        var offset: UInt64 = 0
        var size: UInt64 = 0
        var mtime: Date = .distantPast
        var days: [LocalDay: Int] = [:]
        var messages: [String: LocalDay] = [:]

        /// Removes days and messages before `firstDay` and returns the message keys it removed.
        mutating func dropDays(before firstDay: LocalDay) -> [String] {
            let expired = messages.filter { $0.value < firstDay }.map(\.key)
            messages = messages.filter { $0.value >= firstDay }
            days = days.filter { $0.key >= firstDay }
            return expired
        }
    }

    static let currentVersion = 1

    private(set) var files: [String: FileProgress] = [:]
    private var countedMessages: Set<String> = []

    public init() {}

    func progress(of path: String) -> FileProgress? {
        files[path]
    }

    /// Adds `entry` to `path`, unless its message was already counted in any file.
    /// Returns false if it was a duplicate.
    @discardableResult
    mutating func count(_ entry: ClaudeUsageEntry, in path: String) -> Bool {
        if let key = entry.messageKey {
            guard countedMessages.insert(key).inserted else { return false }
            files[path, default: FileProgress()].messages[key] = entry.day
        }
        files[path, default: FileProgress()].days[entry.day, default: 0] += entry.tokens
        return true
    }

    mutating func markRead(_ path: String, upTo offset: UInt64, size: UInt64, modified: Date) {
        var progress = files[path] ?? FileProgress()
        progress.offset = offset
        progress.size = size
        progress.mtime = modified
        files[path] = progress
    }

    /// Forgets everything counted from `path`, so it can be reread from scratch.
    mutating func forget(_ path: String) {
        guard let progress = files.removeValue(forKey: path) else { return }
        countedMessages.subtract(progress.messages.keys)
    }

    /// Removes files that no longer exist or haven't been touched since before the window,
    /// and the days and messages before `firstDay`.
    mutating func prune(keeping existingPaths: Set<String>, from firstDay: LocalDay, windowStart: Date) {
        for (path, progress) in files where !existingPaths.contains(path) || progress.mtime < windowStart {
            forget(path)
        }
        for path in files.keys {
            // `path` comes from `files.keys`, so the entry exists.
            countedMessages.subtract(files[path]!.dropDays(before: firstDay))
        }
    }

    /// Tokens per day within `days`, summed across files. Days without data are omitted.
    func dailyTokens(in days: ClosedRange<LocalDay>) -> [LocalDay: Int] {
        var totals: [LocalDay: Int] = [:]
        for progress in files.values {
            for (day, tokens) in progress.days where days.contains(day) {
                totals[day, default: 0] += tokens
            }
        }
        return totals
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case version, files
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .version)
        guard version == Self.currentVersion else {
            throw DecodingError.dataCorruptedError(forKey: .version, in: container, debugDescription: "Unsupported index version \(version)")
        }
        files = try container.decode([String: FileProgress].self, forKey: .files)
        countedMessages = Set(files.values.flatMap(\.messages.keys))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.currentVersion, forKey: .version)
        try container.encode(files, forKey: .files)
    }
}
