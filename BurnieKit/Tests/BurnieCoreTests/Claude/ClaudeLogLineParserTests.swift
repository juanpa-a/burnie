import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct ClaudeLogLineParserTests {
    let parser = ClaudeLogLineParser(calendar: .gregorian(in: .mexicoCity))

    func outcomes(_ fixture: String) -> [ClaudeLogLineParser.Outcome] {
        var outcomes: [ClaudeLogLineParser.Outcome] = []
        _ = ClaudeLogScanner.forEachCompleteLine(in: Fixture.data(fixture)) { outcomes.append(parser.parse($0)) }
        return outcomes
    }

    @Test func countsOnlyAssistantLinesWithUsage() {
        #expect(outcomes("claude-log-basic.jsonl") == [
            .irrelevant, // user prompt
            .usage(ClaudeUsageEntry(messageKey: "msg_A:req_A", day: .day("2026-10-10"), tokens: 75_502)),
            .irrelevant, // tool result with its own "usage" key
            .irrelevant, // <synthetic>
            .usage(ClaudeUsageEntry(messageKey: "msg_B:req_B", day: .day("2026-10-09"), tokens: 1_500)),
            .irrelevant, // summary
            .usage(ClaudeUsageEntry(messageKey: nil, day: .day("2026-10-10"), tokens: 115)),
        ])
    }

    @Test("B-44 an unreadable line is flagged and never stops the scan")
    func flagsCorruptLinesWithoutStopping() {
        #expect(outcomes("claude-log-partial.jsonl") == [
            .usage(ClaudeUsageEntry(messageKey: "msg_P1:req_P1", day: .day("2026-10-10"), tokens: 500)),
            .unreadable,
            .usage(ClaudeUsageEntry(messageKey: "msg_P2:req_P2", day: .day("2026-10-10"), tokens: 100)),
        ])
    }

    @Test("B-44 a last line without a newline is left for the next scan")
    func consumesOnlyUpToTheLastNewline() {
        let data = Fixture.data("claude-log-partial.jsonl")
        let consumed = ClaudeLogScanner.forEachCompleteLine(in: data) { _ in }
        #expect(consumed == data.lastIndex(of: UInt8(ascii: "\n"))! + 1)
        #expect(consumed < data.count)
    }
}
