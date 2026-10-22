import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct AppStateTests {
    @Test("B-75 the enabled providers keep the registry order")
    func enabledProvidersKeepTheRegistryOrder() {
        let state = AppState(
            providers: [PanelSamples.panel(.alpha, isEnabled: false), PanelSamples.panel(.beta)],
            ring: .hidden,
            weekChart: nil,
            lastUpdated: nil,
            isRefreshing: false,
            settings: .defaults(enabled: [.beta]),
            visibleToggles: [],
            launchAtLogin: false,
            availableUpdate: nil
        )
        #expect(state.enabledProviders.map(\.id) == [.beta])
    }
}
