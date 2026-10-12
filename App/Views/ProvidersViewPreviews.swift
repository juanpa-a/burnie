#if DEBUG
import SwiftUI

@MainActor
private func providers(_ store: UsageStore) -> some View {
    PreviewFrame { ProvidersView(onBack: {}) }
        .environment(store)
}

#Preview("Both on, no favorite") { providers(.preview()) }
#Preview("Favorite marked") { providers(.preview(favorite: .claude)) }
#Preview("Only one on") { providers(.preview(enabled: [.cursor])) }
#Preview("Ring off") { providers(.preview(favorite: .claude, showRing: false)) }
#Preview("Last 7 days off") { providers(.preview(showWeekChart: false)) }
#Preview("Claude not found") { providers(PreviewScenario.claudeNotFound.store) }
#Preview("Cursor session expired") { providers(PreviewScenario.cursorSessionExpired.store) }
#Preview("All off") { providers(PreviewScenario.allOff.store) }
#endif
