import Foundation
import Testing
@testable import BurnieInfra

final class DirectoryWatcherTests {
    let root = FileManager.default.temporaryDirectory.appending(path: "burnie-watch-\(UUID().uuidString)")

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    @Test("B-72 changes under a directory that exists when the watcher starts are reported", .timeLimit(.minutes(1)))
    func reportsChangesUnderAnExistingRoot() async throws {
        try FileManager.default.createDirectory(at: root.appending(path: "project"), withIntermediateDirectories: true)
        let watcher = DirectoryWatcher(directories: [root.appending(path: "missing"), root], latency: 0.1)
        defer { watcher.stop() }
        await expectChange(from: watcher, writing: root.appending(path: "project/session.jsonl"))
    }

    @Test("B-72 a directory created after the watcher started is watched from its next start", .timeLimit(.minutes(1)))
    func watchesALaterRootFromTheNextStart() async throws {
        let laterRoot = root.appending(path: "later")
        let watcher = DirectoryWatcher(directories: [laterRoot], latency: 0.1)
        defer { watcher.stop() }
        watcher.start {} // nothing exists yet, so this start watches nothing
        try FileManager.default.createDirectory(at: laterRoot, withIntermediateDirectories: true)
        watcher.stop()
        await expectChange(from: watcher, writing: laterRoot.appending(path: "session.jsonl"))
    }

    @Test("starting with no existing directory watches nothing, and stopping it is safe")
    func withoutExistingRootsItWatchesNothing() {
        let watcher = DirectoryWatcher(directories: [root.appending(path: "missing")])
        watcher.start { Issue.record("Should not report a change") }
        watcher.stop()
    }

    /// Starts `watcher`, writes `file` and confirms the watcher reports a change. Without one it waits for the test's
    /// time limit, so every caller sets one.
    private func expectChange(from watcher: DirectoryWatcher, writing file: URL) async {
        await confirmation { changed in
            let (changes, continuation) = AsyncStream<Void>.makeStream()
            watcher.start { continuation.yield() }
            try? Data("{}\n".utf8).write(to: file)
            for await _ in changes {
                changed()
                break
            }
        }
    }
}
