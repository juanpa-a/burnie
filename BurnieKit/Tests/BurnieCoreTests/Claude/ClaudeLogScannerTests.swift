import Foundation
import Testing
import LegacyTestSupport
@testable import BurnieCore

struct ClaudeLogScannerTests {
    static let xdgRoot = URL(filePath: "/home/.config/claude/projects")
    static let root = URL(filePath: "/home/.claude/projects")
    static let sessionFile = root.appending(path: "-Users-dev-burnie/session.jsonl")
    static let otherFile = root.appending(path: "-Users-dev-burnie/session-2/subagents/agent.jsonl")
    static let recently = Date.iso("2026-10-10T19:30:00Z")

    let files = InMemoryFiles()
    var index = ClaudeLogIndex()
    var clock = FixedClock(now: .iso("2026-10-10T20:00:00Z")) // 14:00 in Mexico City

    @discardableResult
    mutating func scan() throws -> ClaudeLogScanReport {
        let calendar = Calendar.gregorian(in: clock.timeZone)
        let window = ActivityWindow.days(endingAt: LocalDay(clock.now, in: calendar))
        return try ClaudeLogScanner(files: files, roots: [Self.xdgRoot, Self.root])
            .scan(&index, window: window, calendar: calendar)
    }

    var totals: [LocalDay: Int] {
        index.dailyTokens(in: ActivityWindow.days(endingAt: LocalDay(clock.now, in: clock.timeZone)))
    }

    func lines(_ fixture: String, _ range: Range<Int>) -> Data {
        let all = Fixture.text(fixture).split(separator: "\n", omittingEmptySubsequences: false)
        return Data(all[range].map { $0 + "\n" }.joined().utf8)
    }

    @Test mutating func sumsAssistantTokensPerLocalDay() throws {
        files.write(Fixture.data("claude-log-basic.jsonl"), to: Self.sessionFile, modified: Self.recently)
        let report = try scan()
        #expect(totals == [.day("2026-10-10"): 75_617, .day("2026-10-09"): 1_500])
        #expect(report.countedLines == 3)
        #expect(report.unreadableLines == 0)
    }

    @Test mutating func bucketsByTheClockTimeZone() throws {
        clock.timeZone = .newYork
        files.write(Fixture.data("claude-log-basic.jsonl"), to: Self.sessionFile, modified: Self.recently)
        try scan()
        #expect(totals == [.day("2026-10-10"): 77_117]) // 05:30 UTC is 01:30 in New York
    }

    @Test("B-44 a duplicated message counts once within a file")
    mutating func countsEachMessageOnceWithinAFile() throws {
        files.write(Fixture.data("claude-log-dupes.jsonl"), to: Self.sessionFile, modified: Self.recently)
        let report = try scan()
        #expect(totals == [.day("2026-10-10"): 76_802])
        #expect(report.duplicateLines == 3)
    }

    @Test("B-44 a duplicated message counts once across files")
    mutating func countsEachMessageOnceAcrossFiles() throws {
        files.write(Fixture.data("claude-log-basic.jsonl"), to: Self.sessionFile, modified: Self.recently)
        files.write(Fixture.data("claude-log-dupes.jsonl"), to: Self.otherFile, modified: Self.recently)
        try scan()
        #expect(totals == [.day("2026-10-10"): 76_917, .day("2026-10-09"): 1_500])
    }

    @Test("B-44 an incremental scan reads only new bytes and matches a full scan")
    mutating func incrementalScanMatchesAFullScan() throws {
        files.write(lines("claude-log-basic.jsonl", 0..<3), to: Self.sessionFile, modified: Self.recently)
        try scan()
        files.append(lines("claude-log-basic.jsonl", 3..<7), to: Self.sessionFile, modified: Self.recently)
        let report = try scan()

        var fullScan = ClaudeLogScannerTests()
        fullScan.files.write(Fixture.data("claude-log-basic.jsonl"), to: Self.sessionFile, modified: Self.recently)
        try fullScan.scan()
        #expect(totals == fullScan.totals)
        #expect(report.bytesRead == lines("claude-log-basic.jsonl", 3..<7).count)
    }

    @Test("B-44 an unfinished last line waits for the next scan")
    mutating func leavesTheUnfinishedLastLineForTheNextScan() throws {
        files.write(Fixture.data("claude-log-partial.jsonl"), to: Self.sessionFile, modified: Self.recently)
        let report = try scan()
        #expect(totals == [.day("2026-10-10"): 600])
        #expect(report.unreadableLines == 1)

        files.append(Data("\n".utf8), to: Self.sessionFile, modified: Self.recently)
        try scan()
        #expect(totals == [.day("2026-10-10"): 602])
    }

    @Test("B-44 a truncated file is reread without double counting")
    mutating func recountsATruncatedFileFromScratch() throws {
        files.write(Fixture.data("claude-log-basic.jsonl"), to: Self.sessionFile, modified: Self.recently)
        try scan()
        files.write(lines("claude-log-basic.jsonl", 0..<2), to: Self.sessionFile, modified: Self.recently)
        try scan()
        #expect(totals == [.day("2026-10-10"): 75_502]) // msg_A counts again, exactly once
    }

    @Test("B-44 a new file untouched since before the window is skipped")
    mutating func skipsUnknownFilesNotTouchedSinceBeforeTheWindow() throws {
        files.write(Fixture.data("claude-log-basic.jsonl"), to: Self.sessionFile, modified: .iso("2026-10-02T12:00:00Z"))
        let report = try scan()
        #expect(report.filesRead == 0)
        #expect(totals.isEmpty)
    }

    @Test("B-44 days that leave the window and deleted or stale files are dropped")
    mutating func prunesDaysThatLeaveTheWindowAndDeletedFiles() throws {
        files.write(Fixture.data("claude-log-basic.jsonl"), to: Self.sessionFile, modified: Self.recently)
        files.write(Fixture.data("claude-log-partial.jsonl"), to: Self.otherFile, modified: .iso("2026-10-15T12:00:00Z"))
        try scan()

        clock.now = .iso("2026-10-17T20:00:00Z") // the window now starts on October 10
        files.remove(Self.otherFile)
        try scan()
        #expect(index.files.keys.sorted() == [Self.sessionFile.path])
        #expect(totals == [.day("2026-10-10"): 75_617])

        clock.now = .iso("2026-10-18T20:00:00Z")
        try scan()
        #expect(index.files.isEmpty)
    }

    @Test("B-45 the XDG log root is scanned before ~/.claude")
    mutating func scansTheXDGRootFirst() throws {
        let xdgFile = Self.xdgRoot.appending(path: "-Users-dev-burnie/session.jsonl")
        files.write(Fixture.data("claude-log-basic.jsonl"), to: xdgFile, modified: Self.recently)
        files.write(Fixture.data("claude-log-basic.jsonl"), to: Self.sessionFile, modified: Self.recently)
        let report = try scan()
        #expect(report.filesRead == 2)
        // Each keyed message counts in the first root that has it; the line without a key counts in both.
        #expect(index.progress(of: xdgFile.path)?.days == [.day("2026-10-10"): 75_617, .day("2026-10-09"): 1_500])
        #expect(index.progress(of: Self.sessionFile.path)?.days == [.day("2026-10-10"): 115])
    }

    @Test("B-45 without any log root Claude is not found")
    mutating func throwsNotFoundWithoutLogRoots() {
        #expect(throws: ProviderIssue.notFound) { try scan() }
    }
}
