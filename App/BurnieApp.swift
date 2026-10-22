import BurnieApplication
import SwiftUI

@main
struct BurnieApp: App {
    @State private var model = CompositionRoot.makeModel()

    var body: some Scene {
        MenuBarExtra {
            RootView()
                .environment(model)
        } label: {
            MenuBarLabel(ring: model.state.ring, providers: model.state.providers)
        }
        .menuBarExtraStyle(.window)
    }
}
