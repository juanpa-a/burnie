import Foundation
import Testing
@testable import BurnieCore

struct ClaudePathsTests {
    let paths = ClaudePaths(home: URL(filePath: "/Users/dev"))

    @Test func showsLogRootsRelativeToHome() {
        #expect(paths.logRoots.map { paths.displayName(ofLogRoot: $0) } == ["~/.config/claude", "~/.claude"])
    }

    @Test("B-45 Claude's log roots are the XDG one first, then ~/.claude")
    func logRootsPutTheXDGOneFirst() {
        #expect(paths.logRoots.map(\.path) == ["/Users/dev/.config/claude/projects", "/Users/dev/.claude/projects"])
    }
}
