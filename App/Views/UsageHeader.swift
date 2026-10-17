import BurnieApplication
import BurnieComponents
import BurnieInterface
import SwiftUI

/// "Usage", the age of the data, and the Refresh and Providers buttons. The gear carries a dot while an update is
/// available (B-57).
struct UsageHeader: View {
    @Environment(AppModel.self) private var model
    let now: Date
    let onOpenProviders: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.textLines) {
                Text(Copy.usage)
                    .font(DesignTokens.Typography.title)
                    .tracking(DesignTokens.Typography.screenTitleTracking)
                    .foregroundStyle(DesignTokens.Palette.fg)
                // With every provider off, nothing is updating (B-55).
                if !model.state.enabledProviders.isEmpty {
                    Text(LastUpdatedFormatter().string(lastUpdated: model.state.lastUpdated, now: now))
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Palette.fg2)
                        .monospacedDigit()
                }
            }
            Spacer()
            HStack(spacing: DesignTokens.Spacing.headerButtons) {
                // Spins, and can't be pressed, while any refresh is open (B-59).
                IconButton(systemName: "arrow.clockwise", accessibilityLabel: Copy.refresh, isSpinning: model.state.isRefreshing) {
                    Task { await model.useCases.refreshUsage() }
                }
                .disabled(model.state.isRefreshing)
                IconButton(systemName: "gearshape", accessibilityLabel: providersLabel, action: onOpenProviders)
                    .overlay(alignment: .topTrailing) {
                        if model.state.availableUpdate != nil {
                            UpdateBadge()
                        }
                    }
            }
        }
        .padding(DesignTokens.Insets.usageHeader)
    }

    private var providersLabel: String {
        model.state.availableUpdate == nil ? Copy.providers : Copy.providersWithUpdate
    }
}
