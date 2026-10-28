#if DEBUG
import BurnieApplication
import BurnieDomain
import BurnieInterface
import Foundation

/// Each state the app can show (SPEC 16.7), as the app state a preview renders.
enum PreviewScenario: CaseIterable {
    case ready
    case firstLaunch
    case claudeNotFound
    case claudeSignInExpired
    case claudeMissingScope
    case claudeLogsUnreadable
    case cursorNotFound
    case cursorSessionExpired
    case cursorMissingKeychainAccess
    case cursorEnterprise
    case rateLimited
    case offline
    case unexpectedResponse
    case allOff
    case weekChartHidden
    case onDemandHidden
    case favoriteMarked
    case onlyOneOn
    case ringOff
    case updateAvailable

    var state: AppState {
        let claude = PreviewData.claude.id
        let cursor = PreviewData.cursor.id
        return switch self {
        case .ready:
            PreviewData.state()
        case .firstLaunch:
            PreviewData.state(claude: .loading, cursor: .loading, history: UsageHistory())
        case .claudeNotFound:
            PreviewData.state(claude: .failed(.notFound))
        case .claudeSignInExpired:
            PreviewData.state(claude: .ready(stale(PreviewData.claudeSnapshot, minutesAgo: 40, issue: .signInExpired)))
        case .claudeMissingScope:
            PreviewData.state(claude: .ready(UsageSnapshot(
                provider: claude,
                content: .activityOnly(Stamped(TodayUsage(tokens: Tokens(1_250_000)), at: PreviewData.now)),
                issue: .specific(SpecificIssue(code: "missingScope"))
            )))
        case .claudeLogsUnreadable:
            PreviewData.state(claude: .ready(PreviewData.snapshot(claude, limits: PreviewData.claudeLimits, today: nil)))
        case .cursorNotFound:
            PreviewData.state(cursor: .failed(.notFound))
        case .cursorSessionExpired:
            PreviewData.state(cursor: .ready(stale(PreviewData.cursorSnapshot, minutesAgo: 40, issue: .signInExpired)))
        case .cursorMissingKeychainAccess:
            PreviewData.state(cursor: .ready(stale(
                PreviewData.cursorSnapshot,
                minutesAgo: 40,
                issue: .specific(SpecificIssue(code: "missingKeychainAccess"))
            )))
        case .cursorEnterprise:
            PreviewData.state(cursor: .ready(PreviewData.cursorEnterprise))
        case .rateLimited:
            PreviewData.state(
                claude: .ready(stale(PreviewData.claudeSnapshot, minutesAgo: 8, issue: .rateLimited(retryAt: nil))),
                cursor: .ready(stale(PreviewData.cursorSnapshot, minutesAgo: 8, issue: nil))
            )
        case .offline:
            PreviewData.state(
                claude: .ready(stale(PreviewData.claudeSnapshot, minutesAgo: 45, issue: .offline)),
                cursor: .ready(stale(PreviewData.cursorSnapshot, minutesAgo: 45, issue: .offline))
            )
        case .unexpectedResponse:
            PreviewData.state(cursor: .ready(stale(PreviewData.cursorSnapshot, minutesAgo: 2, issue: .unexpectedResponse("HTTP 404"))))
        case .allOff:
            PreviewData.state(enabled: [])
        case .weekChartHidden:
            PreviewData.state(showWeekChart: false)
        case .onDemandHidden:
            PreviewData.state(hiddenFeatures: [.onDemand])
        case .favoriteMarked:
            PreviewData.state(favorite: claude)
        case .onlyOneOn:
            PreviewData.state(enabled: [cursor])
        case .ringOff:
            PreviewData.state(favorite: claude, showRing: false)
        case .updateAvailable:
            PreviewData.state(availableUpdate: "0.3.0")
        }
    }

    @MainActor
    var model: AppModel {
        .preview(state, clock: PreviewData.clock)
    }

    /// `snapshot` as it was `minutesAgo`, with `issue` on top.
    private func stale(_ snapshot: UsageSnapshot, minutesAgo: Double, issue: ProviderIssue?) -> UsageSnapshot {
        var shown = PreviewData.snapshot(snapshot.provider, limits: snapshot.limits ?? PreviewData.claudeLimits, today: snapshot.today, minutesAgo: minutesAgo)
        shown.issue = issue
        return shown
    }
}
#endif
