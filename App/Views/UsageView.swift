import BurnieApplication
import BurnieComponents
import BurnieInterface
import SwiftUI

/// The popover's main screen: header, one section per enabled provider, the week chart unless its switch is off, and
/// the footer.
struct UsageView: View {
    @Environment(AppModel.self) private var model
    let onOpenProviders: () -> Void

    var body: some View {
        // Draws the ages and the countdowns again even when no refresh arrives.
        TimelineView(.periodic(from: .now, by: DesignTokens.Motion.clockTick)) { _ in
            content(now: model.clock.now)
        }
    }

    private func content(now: Date) -> some View {
        VStack(spacing: 0) {
            UsageHeader(now: now, onOpenProviders: onOpenProviders)
            BurnieDivider()
            if model.state.enabledProviders.isEmpty {
                EmptyProvidersView(onChooseProviders: onOpenProviders)
                BurnieDivider()
            } else {
                ForEach(model.state.enabledProviders, id: \.id) { panel in
                    ProviderSection(panel: panel, now: now, timeZone: model.clock.timeZone, renewSignIn: renewal(for: panel))
                    BurnieDivider()
                }
                if let chart = model.state.weekChart {
                    WeekChartView(chart: chart, descriptors: model.state.providers.map(\.descriptor))
                    BurnieDivider()
                }
            }
            FooterMenu()
        }
    }

    /// Only a provider that can renew its sign-in offers the button (B-22).
    private func renewal(for panel: ProviderPanel) -> (() async -> Bool)? {
        guard panel.renewalFailedCopy != nil else { return nil }
        return { await model.useCases.renewSignIn(panel.id) }
    }
}
