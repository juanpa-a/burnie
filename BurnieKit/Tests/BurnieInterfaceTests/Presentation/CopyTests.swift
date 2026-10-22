import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct CopyTests {
    @Test("B-56 the providers screen says how many providers are tracked")
    func trackingCount() {
        #expect(Copy.tracking(enabled: 1, total: 2) == "1 of 2 tracking")
    }

    @Test("B-74 the ring switch says how to mark a favorite, or whose ring it shows")
    func ringSubtitle() {
        #expect(Copy.ringWithoutFavorite.beforeHeart == "Mark a provider with")
        #expect(Copy.ringWithoutFavorite.afterHeart == "to show its ring")
        #expect(Copy.ringShows("Alpha Code") == "Shows Alpha Code usage")
    }

    @Test("B-22 the expired sign-in's button")
    func renewSignInButton() {
        #expect(Copy.renewSignIn == "Refresh sign-in")
    }

    @Test("C-7 icon-only controls and switches are labeled for VoiceOver")
    func accessibilityLabels() {
        #expect(Copy.refresh == "Refresh")
        #expect(Copy.providers == "Providers")
        #expect(Copy.providersWithUpdate == "Providers, update available")
        #expect(Copy.backToUsage == "Back to usage")
        #expect(Copy.track("Beta") == "Track Beta")
        #expect(Copy.markFavorite("Beta") == "Mark Beta as favorite")
        #expect(Copy.removeFavorite("Beta") == "Remove Beta as favorite")
        #expect(Copy.weekChartAccessibilityLabel == "Daily usage, last 7 days")
        #expect(Copy.providerUsage(provider: "Alpha", tokens: "1.8M") == "Alpha 1.8M tokens")
        #expect(Copy.providerUsage(provider: "Beta", tokens: "2.6M", spent: "$4.12") == "Beta 2.6M tokens ($4.12)")
        #expect(Copy.weekChartSpend("$6.55") == "· $6.55")
        #expect(Copy.cycleUsage(provider: "Alpha", tokens: "48M", since: "Oct 3") == "Alpha 48M tokens since Oct 3")
    }

    @Test("B-80 the cycle totals' tooltip names the cycle and the day each total counts from")
    func cycleTotals() {
        #expect(Copy.thisCycle == "This cycle")
        #expect(Copy.since("Oct 3") == "since Oct 3")
    }

    @Test func screensAndSwitches() {
        #expect(Copy.usage == "Usage")
        #expect(Copy.lastSevenDays == "Last 7 days")
        #expect(Copy.activityChart == "Activity chart")
        #expect(Copy.activityChartSubtitle == "Shows daily tokens and cycle totals per provider")
        #expect(Copy.title(of: .onDemand) == "On-demand")
        #expect(Copy.subtitle(of: .onDemand) == "Show on-demand spend")
        #expect(Copy.ringInMenuBar == "Ring in menu bar")
        #expect(Copy.launchAtLogin == "Launch at login")
        #expect(Copy.launchAtLoginSubtitle == "Open Burnie when you log in to your Mac")
        #expect(Copy.noProvidersOn == "No providers on")
        #expect(Copy.chooseProviders == "Choose providers")
    }

    @Test("B-57 an update shows its row with the version")
    func updateRow() {
        #expect(Copy.updateAvailable == "Update available")
        #expect(Copy.appVersion("0.3.0") == "Burnie 0.3.0")
        #expect(Copy.update == "Update")
    }

    @Test("B-75 the footer ends with Quit and its shortcut")
    func footer() {
        #expect(Copy.quit == "Quit")
        #expect(Copy.quitShortcut == "⌘Q")
    }
}
