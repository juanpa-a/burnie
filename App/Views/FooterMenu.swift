import BurnieApplication
import BurnieComponents
import BurnieInterface
import SwiftUI

/// Actions at the bottom of the popover: each enabled provider's usage page, in registry order, then Quit (B-75).
struct FooterMenu: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 0) {
            ForEach(model.state.enabledProviders, id: \.id) { panel in
                FooterItem(title: panel.descriptor.dashboard.title, accessory: .external) {
                    model.useCases.openDashboard(panel.id)
                }
            }
            FooterItem(title: Copy.quit, accessory: .shortcut(Copy.quitShortcut)) {
                model.useCases.quit()
            }
            .keyboardShortcut("q")
        }
        .padding(DesignTokens.Insets.list)
    }
}
