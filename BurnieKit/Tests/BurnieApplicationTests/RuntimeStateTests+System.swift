import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieApplication

/// Launch at login, updates, the dashboard links and Quit.
extension RuntimeStateTests {
    @Test("B-58 turning launch at login on asks macOS, and opens System Settings when it needs approval")
    func launchAtLoginNeedingApprovalOpensSettings() {
        var harness = ReducerHarness.launched()
        #expect(harness.send(.launchAtLoginSet(true)) == [.setLaunchAtLogin(true)])
        #expect(harness.send(.launchAtLoginChanged(.requiresApproval)) == [.openLoginItemsSettings])
        #expect(!harness.state.launchAtLogin)
        #expect(harness.send(.launchAtLoginChanged(.enabled)).isEmpty)
        #expect(harness.state.launchAtLogin)
    }

    @Test("B-58 launch at login is read again on request, and a read never opens System Settings")
    func launchAtLoginIsReadAgain() {
        var harness = ReducerHarness.launched()
        #expect(harness.send(.launchAtLoginReadRequested) == [.readLaunchAtLogin])
        #expect(harness.send(.launchAtLoginRead(.requiresApproval)).isEmpty)
        #expect(harness.send(.launchAtLoginRead(.enabled)).isEmpty)
        #expect(harness.state.launchAtLogin)
    }

    @Test("B-57 an update found is kept, and a check without one clears it")
    func updatesAreKeptUntilACheckClearsThem() {
        var harness = ReducerHarness.launched()
        harness.send(.updateFound("0.3.0"))
        #expect(harness.state.availableUpdate == "0.3.0")
        #expect(harness.send(.installUpdateRequested) == [.installUpdate])
        harness.send(.updateFound(nil))
        #expect(harness.state.availableUpdate == nil)
    }

    @Test("B-75 a dashboard link opens that provider's page, and Quit quits")
    func dashboardsAndQuit() {
        var harness = ReducerHarness.launched()
        #expect(harness.send(.dashboardRequested(.beta)) == [.openURL(ProviderDescriptor.beta.dashboard.url)])
        #expect(harness.send(.quitRequested) == [.quit])
    }
}
