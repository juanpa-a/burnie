import BurnieDomain
import BurnieInterface
import Foundation

/// Cursor: meters from usage-summary, tokens from the events CSV and each day's spend from the usage events, all with the
/// desktop app's session (SPEC 6.3).
public enum CursorProvider {
    public static let descriptor = ProviderDescriptor(
        id: .cursor,
        displayName: "Cursor",
        shortName: "Cursor",
        color: ColorPair(light: blue, dark: blue),
        // A literal URL, so it always parses.
        dashboard: DashboardLink(title: "Open Cursor dashboard", url: URL(string: "https://cursor.com/dashboard/spending")!),
        meters: [
            MeterDescriptor(id: .cursorModels, label: "Cursor Models"),
            MeterDescriptor(id: .otherModels, label: "Other Models"),
            MeterDescriptor(id: .included, label: "Included usage"),
            MeterDescriptor(id: .onDemand, label: "On-demand"),
        ],
        placeholderMeters: [.cursorModels, .otherModels],
        copy: ProviderCopy(
            notFound: "Cursor not found. Sign in to the Cursor app.",
            signInExpired: "Session expired. Open Cursor to sign in again.",
            // The chip is uppercase ("PRO+"); here it reads as a name: "Pro+ plan".
            status: { context in context.plan.map { "Signed in · \($0.rawValue.capitalized) plan" } ?? "Signed in" }
        )
    )

    public static func bundle(_ ports: CursorPorts) -> ProviderBundle {
        let dashboard = CursorDashboardClient(
            credentials: CursorCredentialsReader(database: ports.database, paths: CursorPaths(home: ports.home)),
            http: ports.makeHTTPClient(hosts),
            clock: ports.clock,
            userAgent: ports.userAgent
        )
        let limits = CursorSummaryFetcher(dashboard: dashboard)
        let activity = CursorActivity(
            tokens: CursorEventsFetcher(dashboard: dashboard, clock: ports.clock),
            spend: CursorSpendFetcher(dashboard: dashboard, clock: ports.clock)
        )
        return ProviderBundle(
            descriptor: descriptor,
            capabilities: ProviderCapabilities(),
            tasks: [
                RefreshTask(name: "limits", part: .limits, policy: limitsPolicy) {
                    await .outcome { () async throws(ProviderIssue) in .limits(try await limits.limits()) }
                },
                RefreshTask(name: "activity", part: .activity, policy: activityPolicy) {
                    await .outcome { () async throws(ProviderIssue) in .activity(try await activity.activity()) }
                },
            ]
        )
    }

    /// The only host Cursor's HTTP client may reach (B-60).
    static let hosts: Set<String> = ["cursor.com"]

    /// 10 min ± 30 s; refreshed on open after 60 s (B-30).
    static let limitsPolicy = RefreshPolicy(interval: 10 * 60, jitter: 30, staleOnOpen: 60, needsNetwork: true)

    /// 30 min; refreshed on open after 10 min (B-30).
    static let activityPolicy = RefreshPolicy(interval: 30 * 60, jitter: 0, staleOnOpen: 10 * 60, needsNetwork: true)

    /// Cursor's accent, the same in light and dark appearance.
    private static let blue = RGB(red: 0x4C / 255, green: 0x8D / 255, blue: 0xF6 / 255)
}
