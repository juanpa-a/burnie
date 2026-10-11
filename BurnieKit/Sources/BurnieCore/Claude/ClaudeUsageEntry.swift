import Foundation

/// What one Claude log line contributes to a day's count.
struct ClaudeUsageEntry: Equatable {
    /// `message.id:requestId`; nil if either is missing, in which case the line isn't deduplicated.
    let messageKey: String?
    let day: LocalDay
    /// input + output + cache creation + cache read, the same definition as ccusage's total.
    let tokens: Int
}
