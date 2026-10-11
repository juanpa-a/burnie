import SwiftUI

/// The Launch at login switch on the providers screen, read fresh every time the screen appears.
struct LaunchAtLoginRow: View {
    @Environment(LaunchAtLogin.self) private var launchAtLogin

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Launch at login")
                    .font(Tokens.Typography.title)
                    .foregroundStyle(Tokens.Palette.fg)
                Text("Open Burnie when you log in to your Mac")
                    .font(Tokens.Typography.caption)
                    .foregroundStyle(Tokens.Palette.fg2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Toggle("Launch at login", isOn: isOn)
                .toggleStyle(BurnieSwitchStyle(onColor: Tokens.Palette.switchOn))
                .labelsHidden()
        }
        .padding(.horizontal, 10)
        .frame(height: Tokens.Metrics.providerRowHeight)
        .onAppear(perform: launchAtLogin.refresh)
    }

    private var isOn: Binding<Bool> {
        Binding(get: { launchAtLogin.isEnabled }, set: { launchAtLogin.setEnabled($0) })
    }
}
