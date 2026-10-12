import BurnieCore
import SwiftUI

/// The popover's main screen: header, one section per enabled provider, the week chart unless its switch is off, and footer.
struct UsageView: View {
    @Environment(UsageStore.self) private var store
    let onOpenProviders: () -> Void

    var body: some View {
        // Recomputes "Updated…" and the countdowns even when no refresh arrives.
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            content(now: store.clock.now)
        }
    }

    private func content(now: Date) -> some View {
        VStack(spacing: 0) {
            UsageHeader(now: now, onOpenProviders: onOpenProviders)
            BurnieDivider()
            if enabledProviders.isEmpty {
                EmptyProvidersView(onChooseProviders: onOpenProviders)
                BurnieDivider()
            } else {
                ForEach(enabledProviders, id: \.self) { provider in
                    ProviderSection(provider: provider, state: store.states[provider] ?? .loading, now: now, timeZone: store.clock.timeZone)
                    BurnieDivider()
                }
                if store.showWeekChart {
                    WeekChart(providers: enabledProviders, history: store.history)
                    BurnieDivider()
                }
            }
            FooterMenu()
        }
    }

    private var enabledProviders: [ProviderID] {
        ProviderID.allCases.filter(store.enabled.contains)
    }
}

