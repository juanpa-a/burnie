import Foundation

/// Turns a Claude Code JSONL line into a `ClaudeUsageEntry`, if it counts.
struct ClaudeLogLineParser {
    enum Outcome: Equatable {
        case usage(ClaudeUsageEntry)
        /// User, tool or synthetic line, or one without `message.usage`.
        case irrelevant
        /// Looks like a usage line but couldn't be read; counts toward diagnostics and never breaks the scan.
        case unreadable
    }

    let calendar: Calendar
    private let decoder = JSONDecoder()

    init(calendar: Calendar) {
        self.calendar = calendar
    }

    func parse(_ line: UnsafeRawBufferPointer) -> Outcome {
        // Fast path: most lines (prompts, tool results) are never even decoded.
        guard contains(Self.usageMarker, in: line) else { return .irrelevant }
        guard let dto = try? decoder.decode(ClaudeLogLineDTO.self, from: Data(line)) else { return .unreadable }
        guard dto.type == "assistant", let message = dto.message, let usage = message.usage,
              message.model != "<synthetic>" else { return .irrelevant }
        guard let timestamp = dto.timestamp.flatMap(ISO8601DateParser.date(from:)) else { return .unreadable }
        return .usage(ClaudeUsageEntry(
            messageKey: messageKey(messageID: message.id, requestID: dto.requestId),
            day: LocalDay(timestamp, in: calendar),
            tokens: tokens(in: usage)
        ))
    }

    private func messageKey(messageID: String?, requestID: String?) -> String? {
        guard let messageID, let requestID else { return nil }
        return messageID + ":" + requestID
    }

    private func tokens(in usage: ClaudeLogLineDTO.Usage) -> Int {
        (usage.inputTokens ?? 0) + (usage.outputTokens ?? 0)
            + (usage.cacheCreationInputTokens ?? 0) + (usage.cacheReadInputTokens ?? 0)
    }

    private func contains(_ marker: [UInt8], in line: UnsafeRawBufferPointer) -> Bool {
        guard let base = line.baseAddress else { return false }
        return marker.withUnsafeBytes { memmem(base, line.count, $0.baseAddress, $0.count) != nil }
    }

    private static let usageMarker = Array(#""usage""#.utf8)
}
