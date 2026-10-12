import SwiftUI

/// The Launch at login switch on the providers screen, read fresh every time the screen appears.
struct LaunchAtLoginRow: View {
    @Environment(LaunchAtLogin.self) private var launchAtLogin

    var body: some View {
        SwitchRow(title: "Launch at login", subtitle: Text("Open Burnie when you log in to your Mac"), isOn: isOn)
            .padding(.horizontal, 10)
            .frame(height: Tokens.Metrics.providerRowHeight)
            .onAppear(perform: launchAtLogin.refresh)
    }

    private var isOn: Binding<Bool> {
        Binding(get: { launchAtLogin.isEnabled }, set: { launchAtLogin.setEnabled($0) })
    }
}
