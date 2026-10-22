#if DEBUG
import BurnieComponents
import SwiftUI

@MainActor
private func providers(_ scenario: PreviewScenario) -> some View {
    PreviewFrame { ProvidersView(onBack: {}) }
        .environment(scenario.model)
}

#Preview("Both on, no favorite") { providers(.ready) }
#Preview("Favorite marked") { providers(.favoriteMarked) }
#Preview("Only one on") { providers(.onlyOneOn) }
#Preview("Ring off") { providers(.ringOff) }
#Preview("Last 7 days off") { providers(.weekChartHidden) }
#Preview("On-demand off") { providers(.onDemandHidden) }
#Preview("Claude not found") { providers(.claudeNotFound) }
#Preview("Cursor session expired") { providers(.cursorSessionExpired) }
#Preview("All off") { providers(.allOff) }
#Preview("Update available") { providers(.updateAvailable) }
#endif
