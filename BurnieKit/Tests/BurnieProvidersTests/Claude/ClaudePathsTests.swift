import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieProviders

struct ClaudePathsTests {
    let paths = ClaudePaths(home: URL(filePath: "/Users/dev"))

    @Test func showsLogRootsRelativeToHome() {
        #expect(paths.logRoots.map { paths.displayName(ofLogRoot: $0) } == ["~/.config/claude", "~/.claude"])
    }

    @Test("B-45 Claude's log roots are the XDG one first, then ~/.claude")
    func logRootsPutTheXDGOneFirst() {
        #expect(paths.logRoots.map(\.path) == ["/Users/dev/.config/claude/projects", "/Users/dev/.claude/projects"])
    }

    @Test("B-45 the status line shows the first log root that exists, else ~/.claude")
    func sourceLocationIsTheFirstExistingRoot() {
        let files = InMemoryFiles()
        #expect(paths.sourceLocation(in: files) == "~/.claude")
        files.write(Data(), to: paths.logRoots[0].appending(path: "project/session.jsonl"), modified: .iso("2026-10-10T20:00:00Z"))
        #expect(paths.sourceLocation(in: files) == "~/.config/claude")
    }
}
