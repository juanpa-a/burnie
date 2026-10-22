#if DEBUG
import BurnieComponents
import BurnieDomain
import SwiftUI

// The icon on a light and a dark menu bar.

@MainActor
private func label(_ scenario: PreviewScenario) -> some View {
    HStack(spacing: DesignTokens.Spacing.previews) {
        ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
            MenuBarLabel(ring: scenario.state.ring, providers: scenario.state.providers)
                .padding(DesignTokens.Spacing.related)
                .background(.bar)
                .environment(\.colorScheme, scheme)
        }
    }
    .padding(DesignTokens.Insets.preview)
}

#Preview("Flame") { label(.ready) }
#Preview("Ring at 64%") { label(.favoriteMarked) }
#Preview("Implicit favorite") { label(.onlyOneOn) }
#Preview("Ring off") { label(.ringOff) }
#endif
