import BurnieDomain
import Foundation

/// Every fixed text the views and components show. English, sentence case. A provider's own text comes from its
/// descriptor, never from here.
public enum Copy {
    // MARK: Usage screen

    public static let usage = "Usage"
    public static let refresh = "Refresh"
    /// The gear that opens the providers screen.
    public static let providers = "Providers"
    public static let providersWithUpdate = "Providers, update available"
    /// What a meter reads before its first data arrives.
    public static let noValue = "—"
    public static let renewSignIn = "Refresh sign-in"
    public static let noProvidersOn = "No providers on"
    public static let chooseProviders = "Choose providers"

    // MARK: Week chart

    /// Over the chart, whose bars are the last 7 days and whose legend is each provider's cycle.
    public static let activity = "Activity"
    public static let weekChartAccessibilityLabel = "Daily usage, last 7 days"
    /// Before the cycle totals VoiceOver reads (B-76).
    public static let thisCycle = "This cycle"

    /// One provider's cycle or day for VoiceOver: "Claude 1.8M tokens".
    public static func providerUsage(provider shortName: String, tokens: String) -> String {
        "\(shortName) \(tokens) tokens"
    }

    // MARK: Providers screen

    public static let backToUsage = "Back to usage"

    /// "1 of 2 tracking" (B-56).
    public static func tracking(enabled: Int, total: Int) -> String {
        "\(enabled) of \(total) tracking"
    }

    /// The label of a provider's switch.
    public static func track(_ displayName: String) -> String {
        "Track \(displayName)"
    }

    public static func markFavorite(_ displayName: String) -> String {
        "Mark \(displayName) as favorite"
    }

    public static func removeFavorite(_ displayName: String) -> String {
        "Remove \(displayName) as favorite"
    }

    public static let ringInMenuBar = "Ring in menu bar"
    /// Without a favorite, the words around the heart symbol: "Mark a provider with ♡ to show its ring" (B-74).
    public static let ringWithoutFavorite = (beforeHeart: "Mark a provider with", afterHeart: "to show its ring")

    /// Whose ring it is (B-74).
    public static func ringShows(_ displayName: String) -> String {
        "Shows \(displayName) usage"
    }

    /// The switch of the week chart, named like its title.
    public static let activityChart = "Activity chart"
    public static let activityChartSubtitle = "Shows daily tokens and cycle totals per provider"

    public static func title(of toggle: FeatureToggle) -> String {
        switch toggle {
        case .onDemand: "On-demand"
        }
    }

    public static func subtitle(of toggle: FeatureToggle) -> String {
        switch toggle {
        case .onDemand: "Show on-demand spend"
        }
    }

    public static let launchAtLogin = "Launch at login"
    public static let launchAtLoginSubtitle = "Open Burnie when you log in to your Mac"
    public static let updateAvailable = "Update available"
    public static let update = "Update"

    /// "Burnie 0.3.0"
    public static func appVersion(_ version: String) -> String {
        "Burnie \(version)"
    }

    // MARK: Footer

    public static let quit = "Quit"
    public static let quitShortcut = "⌘Q"
}
