import BurnieApplication
import BurnieComponents
import BurnieDomain
import BurnieInterface
import SwiftUI

/// Offers a new Burnie when there is one, turns each provider on or off (turning one off keeps its history), picks the
/// favorite for the menu bar ring, shows or hides the week chart and each feature, and Launch at login.
struct ProvidersView: View {
    @Environment(AppModel.self) private var model
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            BurnieDivider()
            if let version = model.state.availableUpdate {
                UpdateRow(version: version, onUpdate: { model.useCases.installUpdate() })
                BurnieDivider()
            }
            VStack(spacing: 0) {
                ForEach(model.state.providers, id: \.id) { panel in
                    ProviderRow(
                        displayName: panel.descriptor.displayName,
                        status: StatusLine.text(for: panel),
                        accent: panel.descriptor.color,
                        isFavorite: panel.isFavorite,
                        onToggleFavorite: { model.useCases.toggleFavorite(panel.id) },
                        isOn: isEnabled(panel.id)
                    )
                }
            }
            .padding(DesignTokens.Insets.list)
            BurnieDivider()
            RingInMenuBarRow(favorite: model.state.providers.first(where: \.isFavorite)?.descriptor, isOn: showRing)
            BurnieDivider()
            SwitchRow(title: Copy.lastSevenDays, subtitle: Text(Copy.weekChartSubtitle), isOn: showWeekChart)
                .padding(DesignTokens.Insets.settingRow)
            BurnieDivider()
            // Each feature's switch shows only while an enabled snapshot has the feature (B-40).
            ForEach(model.state.visibleToggles, id: \.self) { toggle in
                SwitchRow(title: Copy.title(of: toggle), subtitle: Text(Copy.subtitle(of: toggle)), isOn: isShown(toggle))
                    .padding(DesignTokens.Insets.settingRow)
                BurnieDivider()
            }
            LaunchAtLoginRow()
                .padding(DesignTokens.Insets.list)
        }
    }

    private var header: some View {
        HStack(spacing: DesignTokens.Spacing.backButton) {
            IconButton(systemName: "chevron.left", accessibilityLabel: Copy.backToUsage, weight: .semibold, action: onBack)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.textLines) {
                Text(Copy.providers)
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Palette.fg)
                Text(Copy.tracking(enabled: model.state.enabledProviders.count, total: model.state.providers.count))
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Palette.fg2)
            }
            Spacer()
        }
        .padding(DesignTokens.Insets.providersHeader)
    }

    private func isEnabled(_ id: ProviderID) -> Binding<Bool> {
        Binding(get: { model.state.settings.enabled.contains(id) }, set: { model.useCases.setProviderEnabled(id, $0) })
    }

    private var showRing: Binding<Bool> {
        Binding(get: { model.state.settings.showRing }, set: { model.useCases.setRingShown($0) })
    }

    private var showWeekChart: Binding<Bool> {
        Binding(get: { model.state.settings.showWeekChart }, set: { model.useCases.setWeekChartShown($0) })
    }

    private func isShown(_ toggle: FeatureToggle) -> Binding<Bool> {
        Binding(get: { !model.state.settings.hiddenFeatures.contains(toggle) }, set: { model.useCases.setFeatureShown(toggle, $0) })
    }
}
