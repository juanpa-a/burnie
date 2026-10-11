import Foundation
import Testing
@testable import BurnieSystem

final class ClaudeLogDirectoryWatcherTests {
    let root = FileManager.default.temporaryDirectory.appending(path: "burnie-watch-\(UUID().uuidString)")

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    @Test(.timeLimit(.minutes(1))) func reportsChangesUnderAnExistingRoot() async throws {
        try FileManager.default.createDirectory(at: root.appending(path: "project"), withIntermediateDirectories: true)
        let watcher = ClaudeLogDirectoryWatcher(roots: [root.appending(path: "missing"), root], latency: 0.1)
        defer { watcher.stop() }

        await confirmation { changed in
            let (changes, continuation) = AsyncStream<Void>.makeStream()
            watcher.start { continuation.yield() }
            try? Data("{}\n".utf8).write(to: root.appending(path: "project/session.jsonl"))
            for await _ in changes {
                changed()
                break
            }
        }
    }

    @Test func withoutExistingRootsItDoesNothing() {
        let watcher = ClaudeLogDirectoryWatcher(roots: [root.appending(path: "missing")])
        watcher.start { Issue.record("Should not report a change") }
        watcher.stop()
    }
}
