import BurnieComponents
import BurnieInterface
import SwiftUI

/// What takes the place of the sections when every provider is off.
struct EmptyProvidersView: View {
    let onChooseProviders: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.related) {
            Text(Copy.noProvidersOn)
                .font(DesignTokens.Typography.title)
                .foregroundStyle(DesignTokens.Palette.fg)
            ChipButton(title: Copy.chooseProviders, action: onChooseProviders)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Insets.emptyState)
    }
}
