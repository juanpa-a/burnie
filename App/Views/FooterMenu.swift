import AppKit
import BurnieCore
import SwiftUI

/// Actions at the bottom of the popover: each enabled provider's usage page and Quit.
struct FooterMenu: View {
    @Environment(UsageStore.self) private var store
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            ForEach(ProviderID.allCases.filter(store.enabled.contains), id: \.self) { provider in
                FooterItem(title: provider.dashboardTitle, accessory: .external) {
                    openURL(provider.dashboardURL)
                }
            }
            FooterItem(title: "Quit", accessory: .shortcut("⌘Q")) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(6)
    }
}
