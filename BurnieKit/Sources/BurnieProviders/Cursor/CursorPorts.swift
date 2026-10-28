import BurnieInterface
import Foundation

/// What Cursor's entry point takes: the ports it uses, its log already bound to its id, the values it needs, and the
/// factory for the HTTP client built from its own hosts (P-3).
public struct CursorPorts: Sendable {
    public let clock: any Clock
    public let database: any KeyValueDatabase
    /// Reads Cursor's Keychain item, only for a session Cursor encrypted at rest.
    public let secrets: any SecretReader
    /// Opens that session with the item's password.
    public let decryptor: any SafeStorageDecryptor
    public let log: any DiagnosticsLog
    public let home: URL
    public let userAgent: String
    public let makeHTTPClient: @Sendable (_ allowedHosts: Set<String>) -> any HTTPClient

    public init(
        clock: any Clock,
        database: any KeyValueDatabase,
        secrets: any SecretReader,
        decryptor: any SafeStorageDecryptor,
        log: any DiagnosticsLog,
        home: URL,
        userAgent: String,
        makeHTTPClient: @escaping @Sendable (_ allowedHosts: Set<String>) -> any HTTPClient
    ) {
        self.clock = clock
        self.database = database
        self.secrets = secrets
        self.decryptor = decryptor
        self.log = log
        self.home = home
        self.userAgent = userAgent
        self.makeHTTPClient = makeHTTPClient
    }
}
