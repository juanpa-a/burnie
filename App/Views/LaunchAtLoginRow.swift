import BurnieApplication
import BurnieComponents
import BurnieInterface
import SwiftUI

/// The Launch at login switch on the providers screen, read again every time the screen appears, since System Settings
/// can change it (B-58).
struct LaunchAtLoginRow: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        SwitchRow(title: Copy.launchAtLogin, subtitle: Text(Copy.launchAtLoginSubtitle), isOn: isOn)
            .padding(.horizontal, DesignTokens.Insets.control)
            .frame(height: DesignTokens.Metrics.providerRowHeight)
            .onAppear { model.useCases.readLaunchAtLogin() }
    }

    private var isOn: Binding<Bool> {
        Binding(get: { model.state.launchAtLogin }, set: { model.useCases.setLaunchAtLogin($0) })
    }
}
