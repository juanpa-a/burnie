#if DEBUG
import Foundation
import BurnieCore

extension UsageStore {
    /// Store for previews with the canvas's sample data; each argument changes one part.
    static func preview(
        claude: ProviderState = .ready(PreviewData.claude),
        cursor: ProviderState = .ready(PreviewData.cursor),
        enabled: Set<ProviderID> = Set(ProviderID.allCases),
        favorite: ProviderID? = nil,
        showRing: Bool = true,
        showWeekChart: Bool = true,
        showOnDemand: Bool = true,
        history: [ProviderID: [DailyPoint]] = PreviewData.history
    ) -> UsageStore {
        UsageStore(
            previewing: [.claude: claude, .cursor: cursor],
            history: history,
            enabled: enabled,
            favorite: favorite,
            showRing: showRing,
            showWeekChart: showWeekChart,
            showOnDemand: showOnDemand,
            sourceLocations: [.claude: "~/.claude"],
            signInRenewers: [.claude: PreviewSignInRenewer()],
            clock: PreviewData.clock
        )
    }

    /// Takes a second, like `claude` answering, and always renews.
    private struct PreviewSignInRenewer: SignInRenewer {
        func renewSignIn() async throws {
            try await Task.sleep(for: .seconds(1))
        }
    }
}
#endif
