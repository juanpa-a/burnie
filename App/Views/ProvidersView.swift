import BurnieCore
import SwiftUI

/// Offers a new Burnie when there is one, turns each provider on or off (turning one off keeps its history),
/// picks the favorite for the menu bar ring, shows or hides the week chart and the on-demand meter, and Launch at login.
struct ProvidersView: View {
    @Environment(UsageStore.self) private var store
    @Environment(AppUpdater.self) private var updater
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            BurnieDivider()
            if let version = updater.availableVersion {
                UpdateRow(version: version, onUpdate: updater.installUpdate)
                BurnieDivider()
            }
            VStack(spacing: 0) {
                ForEach(ProviderID.allCases, id: \.self) { provider in
                    ProviderRow(
                        provider: provider,
                        status: status(of: provider),
                        isFavorite: store.effectiveFavorite == provider,
                        onToggleFavorite: { store.toggleFavorite(provider) },
                        isOn: isOn(provider)
                    )
                }
            }
            .padding(6)
            BurnieDivider()
            RingInMenuBarRow(favorite: store.effectiveFavorite, isOn: showRing)
            BurnieDivider()
            SwitchRow(title: "Last 7 days", subtitle: Text("Shows daily tokens per provider"), isOn: showWeekChart)
                .padding(Tokens.Metrics.settingRowInsets)
            BurnieDivider()
            if store.hasOnDemand {
                SwitchRow(title: "On-demand", subtitle: Text("Show on-demand spend"), isOn: showOnDemand)
                    .padding(Tokens.Metrics.settingRowInsets)
                BurnieDivider()
            }
            LaunchAtLoginRow()
                .padding(6)
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            IconButton(systemName: "chevron.left", accessibilityLabel: "Back to usage", weight: .semibold, action: onBack)
            VStack(alignment: .leading, spacing: 2) {
                Text("Providers")
                    .font(Tokens.Typography.title)
                    .foregroundStyle(Tokens.Palette.fg)
                Text("\(store.enabled.count) of \(ProviderID.allCases.count) tracking")
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(Tokens.Palette.fg2)
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 12, leading: 8, bottom: 10, trailing: 16))
    }

    private func status(of provider: ProviderID) -> String {
        provider.statusText(isEnabled: store.enabled.contains(provider), state: store.states[provider], sourceLocation: store.sourceLocations[provider])
    }

    private func isOn(_ provider: ProviderID) -> Binding<Bool> {
        Binding(get: { store.enabled.contains(provider) }, set: { store.setEnabled(provider, $0) })
    }

    private var showRing: Binding<Bool> {
        Binding(get: { store.showRing }, set: { store.setShowRing($0) })
    }

    private var showWeekChart: Binding<Bool> {
        Binding(get: { store.showWeekChart }, set: { store.setShowWeekChart($0) })
    }

    private var showOnDemand: Binding<Bool> {
        Binding(get: { store.showOnDemand }, set: { store.setShowOnDemand($0) })
    }
}

