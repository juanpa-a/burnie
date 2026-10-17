import BurnieComponents
import BurnieInterface
import SwiftUI

/// The top of the providers screen while a new Burnie is available. Update hands over to the updater's window (B-57).
struct UpdateRow: View {
    let version: String
    let onUpdate: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.rowItems) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.textLines) {
                Text(Copy.updateAvailable)
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Palette.fg)
                Text(Copy.appVersion(version))
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Palette.fg2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ChipButton(title: Copy.update, action: onUpdate)
        }
        .padding(DesignTokens.Insets.settingRow)
    }
}
