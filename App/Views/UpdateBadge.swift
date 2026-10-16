import SwiftUI

/// The small blue dot on the gear while a new Burnie is available.
struct UpdateBadge: View {
    var body: some View {
        Circle()
            .fill(Tokens.Palette.updateBadge)
            .frame(width: Tokens.Metrics.updateBadge, height: Tokens.Metrics.updateBadge)
            .padding(Tokens.Metrics.updateBadgeInset)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
