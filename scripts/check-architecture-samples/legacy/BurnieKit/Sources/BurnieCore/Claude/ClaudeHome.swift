// expect: D-3
import Foundation

/// Where Claude keeps its files, found by asking the disk from inside BurnieCore.
public enum ClaudeHome {
    public static func folder() -> URL {
        FileManager.default.homeDirectoryForCurrentUser.appending(path: ".claude")
    }
}
