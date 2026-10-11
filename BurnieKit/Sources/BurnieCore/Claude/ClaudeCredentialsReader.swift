import Foundation

/// Reads Claude Code's OAuth right before each request: first the Keychain, then the file. Never writes.
public struct ClaudeCredentialsReader: Sendable {
    static let keychainService = "Claude Code-credentials"

    private let secrets: SecretReader
    private let files: FileReading
    private let credentialsFile: URL
    private let account: String

    /// `account` is the macOS user (`NSUserName()`), the account of the Keychain item.
    public init(secrets: SecretReader, files: FileReading, paths: ClaudePaths, account: String) {
        self.secrets = secrets
        self.files = files
        self.credentialsFile = paths.credentialsFile
        self.account = account
    }

    func oauth() throws(ProviderIssue) -> ClaudeCredentialsDTO.OAuth {
        guard let payload = keychainItem() ?? credentialsFileContents() else { throw .notFound }
        guard let credentials = try? JSONDecoder().decode(ClaudeCredentialsDTO.self, from: payload) else {
            throw .unexpectedResponse("Unreadable Claude Code credentials")
        }
        guard let oauth = credentials.claudeAiOauth else { throw .notFound }
        return oauth
    }

    private func keychainItem() -> Data? {
        (try? secrets.genericPassword(service: Self.keychainService, account: account)) ?? nil
    }

    private func credentialsFileContents() -> Data? {
        try? files.read(credentialsFile, from: 0)
    }
}
