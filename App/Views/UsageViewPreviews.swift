#if DEBUG
import SwiftUI

// One preview per `PreviewScenario`, each in light and dark.

@MainActor
private func usage(_ scenario: PreviewScenario, availableUpdate: String? = nil) -> some View {
    PreviewFrame(availableUpdate: availableUpdate) { UsageView(onOpenProviders: {}) }
        .environment(scenario.store)
}

#Preview("Ready") { usage(.ready) }
#Preview("First launch") { usage(.firstLaunch) }
#Preview("Claude Code not found") { usage(.claudeNotFound) }
#Preview("Claude sign-in expired") { usage(.claudeSignInExpired) }
#Preview("Claude missing scope") { usage(.claudeMissingScope) }
#Preview("Claude logs unreadable") { usage(.claudeLogsUnreadable) }
#Preview("Cursor not found") { usage(.cursorNotFound) }
#Preview("Cursor session expired") { usage(.cursorSessionExpired) }
#Preview("Cursor enterprise") { usage(.cursorEnterprise) }
#Preview("Rate limited") { usage(.rateLimited) }
#Preview("Offline") { usage(.offline) }
#Preview("Unexpected response") { usage(.unexpectedResponse) }
#Preview("All providers off") { usage(.allOff) }
#Preview("Last 7 days hidden") { usage(.weekChartHidden) }
#Preview("On-demand hidden") { usage(.onDemandHidden) }
#Preview("Update available") { usage(.ready, availableUpdate: "0.3.0") }
#endif
