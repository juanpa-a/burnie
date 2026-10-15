import Foundation
import os
import BurnieCore

/// Cursor: meters from usage-summary, tokens from the events CSV and today's spend from the usage events,
/// using the desktop app's session.
public enum CursorProvider {
    public static func assemble(in environment: ProviderEnvironment) -> ProviderAssembly {
        let dashboard = CursorDashboardClient(
            credentials: CursorCredentialsReader(database: SQLiteKeyValueReader(), paths: CursorPaths(home: environment.home)),
            http: URLSessionHTTPClient(allowedHosts: ["cursor.com"], logger: Logger(subsystem: "dev.juanpa.burnie", category: "cursor")),
            clock: environment.clock,
            userAgent: environment.userAgent
        )
        return ProviderAssembly(provider: CompositeUsageProvider(
            id: .cursor,
            limits: CursorSummaryFetcher(dashboard: dashboard),
            activity: CursorActivity(dashboard: dashboard, clock: environment.clock),
            clock: environment.clock
        ))
    }
}
