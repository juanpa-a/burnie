import BurnieInterface
import Foundation

/// What Cursor's entry point takes: the ports it uses, its log already bound to its id, the values it needs, and the
/// factory for the HTTP client built from its own hosts (P-3).
public struct CursorPorts: Sendable {
    public let clock: any Clock
    public let database: any KeyValueDatabase
    public let log: any DiagnosticsLog
    public let home: URL
    public let userAgent: String
    public let makeHTTPClient: @Sendable (_ allowedHosts: Set<String>) -> any HTTPClient

    public init(
        clock: any Clock,
        database: any KeyValueDatabase,
        log: any DiagnosticsLog,
        home: URL,
        userAgent: String,
        makeHTTPClient: @escaping @Sendable (_ allowedHosts: Set<String>) -> any HTTPClient
    ) {
        self.clock = clock
        self.database = database
        self.log = log
        self.home = home
        self.userAgent = userAgent
        self.makeHTTPClient = makeHTTPClient
    }
}
