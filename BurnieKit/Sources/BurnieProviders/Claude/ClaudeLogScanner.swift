import BurnieDomain
import BurnieInterface
import Foundation

/// Reads only what's new in each `*.jsonl` under Claude's log roots and adds it to the index.
struct ClaudeLogScanner: Sendable {
    let files: any FileReading
    let roots: [URL]

    /// What stays fixed during a scan.
    private struct Pass {
        let window: ClosedRange<LocalDay>
        let windowStart: Date
        let parser: ClaudeLogLineParser
    }

    /// Throws `.notFound` if no root exists.
    func scan(_ index: inout ClaudeLogIndex, window: ClosedRange<LocalDay>, calendar: Calendar) throws(ProviderIssue) -> ClaudeLogScanReport {
        let logFiles = try listLogFiles()
        let pass = Pass(window: window, windowStart: window.lowerBound.start(in: calendar), parser: ClaudeLogLineParser(calendar: calendar))
        var report = ClaudeLogScanReport()
        for url in logFiles {
            scanFile(url, in: pass, into: &index, report: &report)
        }
        index.prune(keeping: Set(logFiles.map(\.path)), from: window.lowerBound, windowStart: pass.windowStart)
        return report
    }

    private func listLogFiles() throws(ProviderIssue) -> [URL] {
        let listings = roots.compactMap { try? files.list($0, ext: "jsonl") }
        guard !listings.isEmpty else { throw .notFound }
        return listings.flatMap { $0 }
    }

    private func scanFile(_ url: URL, in pass: Pass, into index: inout ClaudeLogIndex, report: inout ClaudeLogScanReport) {
        let path = url.path
        guard let attributes = try? files.attributes(url) else {
            report.unreadableFiles += 1
            return
        }
        let known = index.progress(of: path)
        // A new file untouched since before the window can't contain days inside the window.
        guard known != nil || attributes.modified >= pass.windowStart else { return }
        if let known, attributes.size < known.offset {
            index.forget(path) // truncated or replaced: recounted from scratch
        }
        let offset = index.progress(of: path)?.offset ?? 0
        guard attributes.size > offset else {
            index.markRead(path, upTo: offset, size: attributes.size, modified: attributes.modified)
            return
        }
        guard let data = try? files.read(url, from: offset) else {
            report.unreadableFiles += 1
            return
        }

        let consumed = Self.forEachCompleteLine(in: data) { line in
            switch pass.parser.parse(line) {
            case .usage(let entry) where pass.window.contains(entry.day):
                if index.count(entry, in: path) { report.countedLines += 1 } else { report.duplicateLines += 1 }
            case .unreadable:
                report.unreadableLines += 1
            case .usage, .irrelevant:
                break
            }
        }
        index.markRead(path, upTo: offset + UInt64(consumed), size: attributes.size, modified: attributes.modified)
        report.filesRead += 1
        report.bytesRead += consumed
    }

    /// Calls `body` with each line ending in "\n" and returns the bytes consumed.
    /// A last line without "\n" is still being written: it's left for the next scan.
    static func forEachCompleteLine(in data: Data, _ body: (UnsafeRawBufferPointer) -> Void) -> Int {
        data.withUnsafeBytes { buffer in
            guard let base = buffer.baseAddress else { return 0 }
            var start = 0
            while start < buffer.count, let newline = memchr(base + start, 0x0A, buffer.count - start) {
                let end = UnsafeRawPointer(newline) - base
                body(UnsafeRawBufferPointer(rebasing: buffer[start..<end]))
                start = end + 1
            }
            return start
        }
    }
}
