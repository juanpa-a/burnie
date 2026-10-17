import BurnieDomain
import BurnieInterface
import Foundation

/// Renews Claude Code's sign-in by running Claude Code itself: a one-word Haiku reply needs a valid token, so `claude`
/// refreshes and saves its own. Burnie never sees the refresh token or writes the Keychain item (B-61).
enum ClaudeSignInRenewal {
    static let failedCopy = "Couldn't refresh sign-in. Run `claude` in Terminal and log in again."

    /// No tools, no user settings (nor their hooks), no saved session: only what makes Claude Code need its token (B-63).
    static let arguments = [
        "-p", "Reply with the single word: ok",
        "--model", "haiku",
        "--tools", "",
        "--no-session-persistence",
        "--setting-sources", "project",
    ]

    /// Where Claude Code's installers leave `claude`, in the order they're tried.
    static func candidates(home: URL) -> [URL] {
        [
            home.appending(path: ".local/bin/claude"), // native installer
            URL(filePath: "/opt/homebrew/bin/claude"), // Homebrew on Apple silicon
            URL(filePath: "/usr/local/bin/claude"), // Homebrew on Intel, npm
        ]
    }

    /// The renewal over the first installed `claude`; nil when there's none to ask (B-22).
    static func make(
        home: URL,
        files: any FileReading,
        makeProcessRunner: (_ allowedExecutables: [URL]) -> any ProcessRunner
    ) -> SignInRenewal? {
        let candidates = candidates(home: home)
        guard let executable = candidates.first(where: files.isExecutable) else { return nil }
        let runner = makeProcessRunner(candidates)
        return SignInRenewal(failedCopy: failedCopy) {
            await runner.run(executable, arguments: arguments) == 0
        }
    }
}
