import Foundation

/// Where Claude Code keeps its credentials and logs. Paths live only here.
public struct ClaudePaths: Sendable {
    public let home: URL

    public init(home: URL) {
        self.home = home
    }

    /// Fallback when there's no Keychain item.
    public var credentialsFile: URL {
        home.appending(path: ".claude/.credentials.json")
    }

    /// Both are scanned if they exist; the XDG one first.
    public var logRoots: [URL] {
        [home.appending(path: ".config/claude/projects"), defaultLogRoot]
    }

    /// The usual root, shown when neither exists yet.
    public var defaultLogRoot: URL {
        home.appending(path: ".claude/projects")
    }

    /// The Claude Code folder containing `logRoot`, as shown to the user: "~/.claude".
    public func displayName(ofLogRoot logRoot: URL) -> String {
        let folder = logRoot.deletingLastPathComponent().path(percentEncoded: false)
        let homePath = home.path(percentEncoded: false)
        guard folder.hasPrefix(homePath) else { return folder }
        return "~/" + folder.dropFirst(homePath.count).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}
