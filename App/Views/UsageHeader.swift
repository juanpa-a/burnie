import BurnieCore
import SwiftUI

/// "Usage", the age of the data, and the Refresh and Providers buttons. The Providers gear carries a dot while an update is available.
struct UsageHeader: View {
    @Environment(UsageStore.self) private var store
    @Environment(AppUpdater.self) private var updater
    let now: Date
    let onOpenProviders: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Usage")
                    .font(Tokens.Typography.title)
                    .tracking(-0.1)
                    .foregroundStyle(Tokens.Palette.fg)
                // With every provider off, nothing is updating.
                if !store.enabled.isEmpty {
                    Text(LastUpdatedFormatter().string(lastUpdated: store.lastUpdated, now: now))
                        .font(Tokens.Typography.caption)
                        .foregroundStyle(Tokens.Palette.fg2)
                        .monospacedDigit()
                }
            }
            Spacer()
            HStack(spacing: 2) {
                IconButton(systemName: "arrow.clockwise", accessibilityLabel: "Refresh", isSpinning: store.isRefreshing) {
                    Task { await store.refreshAll(force: true) }
                }
                .disabled(store.isRefreshing)
                IconButton(systemName: "gearshape", accessibilityLabel: providersLabel, action: onOpenProviders)
                    .overlay(alignment: .topTrailing) {
                        if updater.availableVersion != nil {
                            UpdateBadge()
                        }
                    }
            }
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 10, trailing: 12))
    }

    private var providersLabel: String {
        updater.availableVersion == nil ? "Providers" : "Providers, update available"
    }
}
