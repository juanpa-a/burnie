import SwiftUI

@main
struct BurnieApp: App {
    @State private var store = UsageStore.live()
    @State private var launchAtLogin = LaunchAtLogin()
    @State private var updater = AppUpdater.live()

    var body: some Scene {
        MenuBarExtra {
            RootView()
                .environment(store)
                .environment(launchAtLogin)
                .environment(updater)
        } label: {
            MenuBarLabel(ring: store.ring)
        }
        .menuBarExtraStyle(.window)
    }
}
