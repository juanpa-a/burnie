import BurnieDomain
import BurnieInterface
import Foundation

/// Claude Code: limits from its OAuth usage endpoint, tokens from the local logs (SPEC 6.2).
public enum ClaudeProvider {
    public static let descriptor = ProviderDescriptor(
        id: .claude,
        displayName: "Claude Code",
        shortName: "Claude",
        color: ColorPair(light: orange, dark: orange),
        // A literal URL, so it always parses.
        dashboard: DashboardLink(title: "Open Claude usage page", url: URL(string: "https://claude.ai/settings/usage")!),
        meters: [MeterDescriptor(id: .session, label: "Session · 5h"), MeterDescriptor(id: .weekly, label: "Weekly")],
        placeholderMeters: [.session, .weekly],
        copy: ProviderCopy(
            notFound: "Claude Code not found. Install it and sign in.",
            signInExpired: "Limits paused. Open Claude Code to refresh sign-in.",
            specific: [.missingScope: "This sign-in can't read limits. Run `claude` and log in again."],
            status: { "Reading local logs · \($0.sourceLocation ?? "~/.claude")" }
        )
    )

    public static func bundle(_ ports: ClaudePorts) -> ProviderBundle {
        let paths = ClaudePaths(home: ports.home)
        let limits = ClaudeLimitsFetcher(
            credentials: ClaudeCredentialsReader(secrets: ports.secrets, files: ports.files, paths: paths, account: ports.userName),
            http: ports.makeHTTPClient(hosts),
            clock: ports.clock,
            userAgent: ports.userAgent
        )
        let activity = ClaudeLogActivity(roots: paths.logRoots, files: ports.files, storage: ports.storage, clock: ports.clock, log: ports.log)
        return ProviderBundle(
            descriptor: descriptor,
            capabilities: ProviderCapabilities(
                signInRenewal: ClaudeSignInRenewal.make(home: ports.home, files: ports.files, makeProcessRunner: ports.makeProcessRunner),
                sourceLocation: paths.sourceLocation(in: ports.files)
            ),
            tasks: [
                RefreshTask(name: "limits", part: .limits, policy: limitsPolicy) {
                    await .outcome { () async throws(ProviderIssue) in .limits(try await limits.limits()) }
                },
                RefreshTask(name: "activity", part: .activity, policy: activityPolicy, watcher: ports.makeWatcher(paths.logRoots)) {
                    await .outcome { () async throws(ProviderIssue) in .activity(try await activity.activity()) }
                },
            ]
        )
    }

    /// The only host Claude's HTTP client may reach (B-60).
    static let hosts: Set<String> = ["api.anthropic.com"]

    /// 5 min ± 30 s; refreshed on open after 60 s (B-30).
    static let limitsPolicy = RefreshPolicy(interval: 5 * 60, jitter: 30, staleOnOpen: 60, needsNetwork: true)

    /// The logs notify through the watcher, so the timer is only a fallback, and they need no network (B-30).
    static let activityPolicy = RefreshPolicy(interval: 5 * 60, jitter: 0, staleOnOpen: nil, needsNetwork: false)

    /// Claude's accent, the same in light and dark appearance.
    private static let orange = RGB(red: 0xF0 / 255, green: 0x88 / 255, blue: 0x3E / 255)
}
