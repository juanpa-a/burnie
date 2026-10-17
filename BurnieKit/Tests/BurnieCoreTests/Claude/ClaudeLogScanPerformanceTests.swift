import Foundation
import Testing
import LegacyTestSupport
@testable import BurnieCore

/// 200 MB of synthetic JSONL: < 3 s cold and < 50 ms incremental.
/// Runs only in release: `make perf`.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["BURNIE_PERF"] != nil))
struct ClaudeLogScanPerformanceTests {
    static let fileCount = 40
    static let bytesPerFile = 5_000_000

    @Test func scansTwoHundredMegabytesQuickly() throws {
        let files = InMemoryFiles()
        let modified = Date.iso("2026-10-10T19:00:00Z")
        for file in 0..<Self.fileCount {
            files.write(syntheticLog(file: file), to: url(file), modified: modified)
        }
        let calendar = Calendar.gregorian(in: .mexicoCity)
        let window = ActivityWindow.days(endingAt: .day("2026-10-10"))
        let scanner = ClaudeLogScanner(files: files, roots: [ClaudeLogScannerTests.root])
        var index = ClaudeLogIndex()

        let cold = try ContinuousClock().measure {
            _ = try scanner.scan(&index, window: window, calendar: calendar)
        }
        files.append(syntheticLog(file: Self.fileCount, lines: 50), to: url(0), modified: modified)
        let incremental = try ContinuousClock().measure {
            _ = try scanner.scan(&index, window: window, calendar: calendar)
        }

        print("cold \(cold), incremental \(incremental)")
        #expect(cold < .seconds(3))
        #expect(incremental < .milliseconds(50))
    }

    private func url(_ file: Int) -> URL {
        ClaudeLogScannerTests.root.appending(path: "-Users-dev-project-\(file)/session-\(file).jsonl")
    }

    /// Half large prompts and tool results, half responses with usage, like a real log.
    private func syntheticLog(file: Int, lines: Int? = nil) -> Data {
        let toolOutput = String(repeating: "x", count: 1_800)
        let text = String(repeating: "y", count: 900)
        var log = Data()
        var line = 0
        while log.count < Self.bytesPerFile, lines.map({ line < $0 }) ?? true {
            let minute = line % 600
            let timestamp = String(format: "2026-10-10T%02d:%02d:00.000Z", 8 + minute / 60, minute % 60)
            log.append(contentsOf: (#"{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"\#(toolOutput)"}]},"timestamp":"\#(timestamp)","sessionId":"s"}"# + "\n").utf8)
            log.append(contentsOf: (#"{"parentUuid":"p","isSidechain":false,"type":"assistant","timestamp":"\#(timestamp)","requestId":"req_\#(file)_\#(line)","message":{"id":"msg_\#(file)_\#(line)","model":"claude-opus-5-5","role":"assistant","content":[{"type":"text","text":"\#(text)"}],"usage":{"input_tokens":2,"cache_creation_input_tokens":5107,"cache_read_input_tokens":25000,"output_tokens":500,"service_tier":"standard"}},"uuid":"u","sessionId":"s"}"# + "\n").utf8)
            line += 1
        }
        return log
    }
}
