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

    @Test("B-76 checking for updates starts one check at a time, and its result drives the row")
    func checkUpdatesAsksTheUpdater() {
        var harness = ReducerHarness.launched()
        #expect(harness.send(.checkUpdatesRequested) == [.checkUpdates])
        #expect(harness.state.updateCheck == .checking)
        #expect(harness.send(.checkUpdatesRequested).isEmpty)
        #expect(harness.state.updateCheck == .checking)
        #expect(harness.send(.checkFinished(.found("0.3.1"))).isEmpty)
        #expect(harness.state.updateCheck == .idle)
        #expect(harness.state.availableUpdate == "0.3.1")
        #expect(harness.send(.checkUpdatesRequested) == [.checkUpdates])
        #expect(harness.send(.checkFinished(.failed)).isEmpty)
        #expect(harness.state.updateCheck == .idle)
        #expect(harness.state.availableUpdate == "0.3.1")
    }

    @Test("B-76 an \"up to date\" asks again on the next visit, and clears the dot")
    func upToDateAsksAgainNextVisit() {
        var harness = ReducerHarness.launched()
        harness.send(.updateFound("0.3.0"))
        harness.send(.checkUpdatesRequested)
        harness.send(.checkFinished(.upToDate))
        #expect(harness.state.availableUpdate == nil)
        #expect(harness.state.updateCheck == .upToDate)
        harness.send(.popoverOpened(RequestID(value: 0)))
        #expect(harness.state.updateCheck == .idle)
    }

    @Test("B-75 a dashboard link opens that provider's page, and Quit quits")
    func dashboardsAndQuit() {
        var harness = ReducerHarness.launched()
        #expect(harness.send(.dashboardRequested(.beta)) == [.openURL(ProviderDescriptor.beta.dashboard.url)])
        #expect(harness.send(.quitRequested) == [.quit])
    }
}
