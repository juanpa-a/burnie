import SwiftUI

@main
struct BurnieApp: App {
    @State private var store = UsageStore.live()
    @State private var launchAtLogin = LaunchAtLogin()

    var body: some Scene {
        MenuBarExtra {
            RootView()
                .environment(store)
                .environment(launchAtLogin)
        } label: {
            MenuBarLabel(ring: store.ring)
        }
        .menuBarExtraStyle(.window)
    }
}
