import BurnieApplication
import BurnieComponents
import BurnieInterface
import SwiftUI

/// The "Check for updates" row on the providers screen: a check right now, reported in place (B-82); when there's a
/// newer Burnie, the Update row takes over (B-57).
struct CheckForUpdatesRow: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.rowItems) {
            Text(Copy.checkForUpdates)
                .font(DesignTokens.Typography.title)
                .foregroundStyle(DesignTokens.Palette.fg)
                .frame(maxWidth: .infinity, alignment: .leading)
            action
        }
        .padding(DesignTokens.Insets.settingRow)
    }

    @ViewBuilder
    private var action: some View {
        switch model.state.updateCheck {
        case .idle:
            ChipButton(title: Copy.checkNow, action: { model.useCases.checkUpdates() })
        case .checking:
            ChipButton(title: Copy.checkNow, isBusy: true, action: {})
        case .upToDate:
            Text(Copy.upToDate)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Palette.fg2)
        }
    }
}
