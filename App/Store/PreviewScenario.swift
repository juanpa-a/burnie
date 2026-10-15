#if DEBUG
import Foundation
import BurnieCore

/// Each state the app can show, as a preview store.
enum PreviewScenario: String, CaseIterable {
    case ready
    case firstLaunch
    case claudeNotFound
    case claudeSignInExpired
    case claudeMissingScope
    case claudeLogsUnreadable
    case cursorNotFound
    case cursorSessionExpired
    case cursorEnterprise
    case rateLimited
    case offline
    case unexpectedResponse
    case allOff
    case weekChartHidden

    @MainActor
    var store: UsageStore {
        switch self {
        case .ready:
            .preview()
        case .firstLaunch:
            .preview(claude: .loading, cursor: .loading, history: PreviewData.emptyHistory)
        case .claudeNotFound:
            .preview(claude: .failed(.notFound))
        case .claudeSignInExpired:
            .preview(claude: .ready(PreviewData.claude.cached(minutesAgo: 40).with(issue: .signInExpired)))
        case .claudeMissingScope:
            .preview(claude: .ready(UsageSnapshot(provider: .claude, fetchedAt: PreviewData.now, today: .tokens(1_250_000), issue: .missingScope)))
        case .claudeLogsUnreadable:
            .preview(claude: .ready(PreviewData.claude.withoutToday))
        case .cursorNotFound:
            .preview(cursor: .failed(.notFound))
        case .cursorSessionExpired:
            .preview(cursor: .ready(PreviewData.cursor.cached(minutesAgo: 40).with(issue: .signInExpired)))
        case .cursorEnterprise:
            .preview(cursor: .ready(PreviewData.cursorEnterprise))
        case .rateLimited:
            .preview(
                claude: .ready(PreviewData.claude.cached(minutesAgo: 8).with(issue: .rateLimited(retryAt: nil))),
                cursor: .ready(PreviewData.cursor.cached(minutesAgo: 8))
            )
        case .offline:
            .preview(
                claude: .ready(PreviewData.claude.cached(minutesAgo: 45).with(issue: .offline)),
                cursor: .ready(PreviewData.cursor.cached(minutesAgo: 45).with(issue: .offline))
            )
        case .unexpectedResponse:
            .preview(cursor: .ready(PreviewData.cursor.with(issue: .unexpectedResponse("HTTP 404"))))
        case .allOff:
            .preview(enabled: [])
        case .weekChartHidden:
            .preview(showWeekChart: false)
        }
    }
}

private extension UsageSnapshot {
    func cached(minutesAgo: Double) -> UsageSnapshot {
        var snapshot = self
        snapshot.fetchedAt = PreviewData.now.addingTimeInterval(-minutesAgo * 60)
        return snapshot
    }

    var withoutToday: UsageSnapshot {
        var snapshot = self
        snapshot.today = nil
        return snapshot
    }
}
#endif
