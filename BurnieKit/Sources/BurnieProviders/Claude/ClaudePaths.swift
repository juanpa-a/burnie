import BurnieInterface
import Foundation

/// Where Claude Code keeps its credentials and logs. Paths live only here.
struct ClaudePaths: Sendable {
    let home: URL

    /// Fallback when there's no Keychain item (B-27).
    var credentialsFile: URL {
        home.appending(path: ".claude/.credentials.json")
    }

    /// Both are scanned if they exist; the XDG one first (B-45).
    var logRoots: [URL] {
        [home.appending(path: ".config/claude/projects"), defaultLogRoot]
    }

    /// The usual root, shown when neither exists yet.
    var defaultLogRoot: URL {
        home.appending(path: ".claude/projects")
    }

    /// Where the logs are read from, as the status line shows it: the first root that exists, else the default.
    func sourceLocation(in files: any FileReading) -> String {
        displayName(ofLogRoot: logRoots.first(where: files.exists) ?? defaultLogRoot)
    }

    /// The Claude Code folder containing `logRoot`, as shown to the user: "~/.claude".
    func displayName(ofLogRoot logRoot: URL) -> String {
        let folder = logRoot.deletingLastPathComponent().path(percentEncoded: false)
        let homePath = home.path(percentEncoded: false)
        guard folder.hasPrefix(homePath) else { return folder }
        return "~/" + folder.dropFirst(homePath.count).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}
