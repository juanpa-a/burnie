import Foundation
import Testing
@testable import BurnieCore

struct ClaudePathsTests {
    let paths = ClaudePaths(home: URL(filePath: "/Users/dev"))

    @Test func showsLogRootsRelativeToHome() {
        #expect(paths.logRoots.map { paths.displayName(ofLogRoot: $0) } == ["~/.config/claude", "~/.claude"])
    }
}
