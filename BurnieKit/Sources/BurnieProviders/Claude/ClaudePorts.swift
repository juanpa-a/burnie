import BurnieInterface
import Foundation

/// What Claude's entry point takes: the ports it uses, already bound to its id where they keep state or log, the
/// values it needs, and the factories for ports built from its own data (P-3).
public struct ClaudePorts: Sendable {
    public let clock: any Clock
    public let files: any FileReading
    public let secrets: any SecretReader
    public let storage: any ProviderStorage
    public let log: any DiagnosticsLog
    public let home: URL
    /// The macOS user, the account of Claude Code's Keychain item.
    public let userName: String
    public let userAgent: String
    public let makeHTTPClient: @Sendable (_ allowedHosts: Set<String>) -> any HTTPClient
    public let makeWatcher: @Sendable (_ directories: [URL]) -> any ActivityWatcher
    public let makeProcessRunner: @Sendable (_ allowedExecutables: [URL]) -> any ProcessRunner

    public init(
        clock: any Clock,
        files: any FileReading,
        secrets: any SecretReader,
        storage: any ProviderStorage,
        log: any DiagnosticsLog,
        home: URL,
        userName: String,
        userAgent: String,
        makeHTTPClient: @escaping @Sendable (_ allowedHosts: Set<String>) -> any HTTPClient,
        makeWatcher: @escaping @Sendable (_ directories: [URL]) -> any ActivityWatcher,
        makeProcessRunner: @escaping @Sendable (_ allowedExecutables: [URL]) -> any ProcessRunner
    ) {
        self.clock = clock
        self.files = files
        self.secrets = secrets
        self.storage = storage
        self.log = log
        self.home = home
        self.userName = userName
        self.userAgent = userAgent
        self.makeHTTPClient = makeHTTPClient
        self.makeWatcher = makeWatcher
        self.makeProcessRunner = makeProcessRunner
    }
}
