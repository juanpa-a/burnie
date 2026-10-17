import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct ClaudeLogIndexTests {
    static let sessionFile = "/Users/dev/.claude/projects/-Users-dev-burnie/session.jsonl"
    static let agentFile = "/Users/dev/.config/claude/projects/-Users-dev-burnie/session-2/subagents/agent.jsonl"

    /// What `Fixtures/Persistence/claude-log-index.json` holds: a file read to its end, and one whose last line was
    /// still being written.
    static let persisted: ClaudeLogIndex = {
        var index = ClaudeLogIndex()
        index.count(ClaudeUsageEntry(messageKey: "msg_A:req_A", day: .day("2026-10-10"), tokens: 75_502), in: sessionFile)
        index.count(ClaudeUsageEntry(messageKey: "msg_B:req_B", day: .day("2026-10-09"), tokens: 1_500), in: sessionFile)
        index.count(ClaudeUsageEntry(messageKey: nil, day: .day("2026-10-10"), tokens: 115), in: sessionFile)
        index.markRead(sessionFile, upTo: 4_096, size: 4_096, modified: .iso("2026-10-10T19:30:00Z"))
        index.count(ClaudeUsageEntry(messageKey: "msg_C:req_C", day: .day("2026-10-10"), tokens: 1_300), in: agentFile)
        index.markRead(agentFile, upTo: 812, size: 900, modified: .iso("2026-10-10T19:45:00Z"))
        return index
    }()

    @Test("claude-log-index.json decodes in today's shape")
    func logIndexFileDecodesInTodaysShape() throws {
        #expect(try Fixture.persisted(ClaudeLogIndex.self, from: "claude-log-index.json") == Self.persisted)
    }
}
