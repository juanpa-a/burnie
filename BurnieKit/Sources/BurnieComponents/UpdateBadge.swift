import SwiftUI

/// The small blue dot on the gear while a new Burnie is available (B-57).
public struct UpdateBadge: View {
    public init() {}

    public var body: some View {
        Circle()
            .fill(DesignTokens.Palette.updateBadge)
            .frame(width: DesignTokens.Metrics.updateBadge, height: DesignTokens.Metrics.updateBadge)
            .padding(DesignTokens.Metrics.updateBadgeInset)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview {
    PreviewFrame {
        UpdateBadge()
    }
}
