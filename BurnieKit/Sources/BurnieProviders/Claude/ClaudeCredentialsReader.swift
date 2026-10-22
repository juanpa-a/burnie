import BurnieDomain
import BurnieInterface
import Foundation

/// Reads Claude Code's OAuth right before each request: first the Keychain, then the file (B-27). Never writes.
struct ClaudeCredentialsReader: Sendable {
    static let keychainService = "Claude Code-credentials"

    let secrets: any SecretReader
    let files: any FileReading
    let paths: ClaudePaths
    /// The macOS user, the account of the Keychain item.
    let account: String

    func oauth() throws(ProviderIssue) -> ClaudeCredentialsDTO.OAuth {
        guard hasClaudeCodeFolder, let payload = keychainItem() ?? credentialsFileContents() else { throw .notFound }
        guard let credentials = try? JSONDecoder().decode(ClaudeCredentialsDTO.self, from: payload) else {
            throw .unexpectedResponse("Unreadable Claude Code credentials")
        }
        guard let oauth = credentials.claudeAiOauth else { throw .notFound }
        return oauth
    }

    /// Without one, Claude Code isn't installed and nothing is read: a Mac without it never runs `security` (B-27).
    private var hasClaudeCodeFolder: Bool {
        paths.claudeCodeFolders.contains(where: files.exists)
    }

    private func keychainItem() -> Data? {
        (try? secrets.genericPassword(service: Self.keychainService, account: account)) ?? nil
    }

    private func credentialsFileContents() -> Data? {
        try? files.read(paths.credentialsFile, from: 0)
    }
}
