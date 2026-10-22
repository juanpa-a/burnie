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

    public static let lastSevenDays = "Last 7 days"
    public static let weekChartAccessibilityLabel = "Daily usage, last 7 days"

    /// One provider's week or day for VoiceOver: "Claude 1.8M tokens", or with the day's spend
    /// "Cursor 2.6M tokens ($4.12)".
    public static func providerUsage(provider shortName: String, tokens: String, spent: String? = nil) -> String {
        guard let spent else { return "\(shortName) \(tokens) tokens" }
        return "\(shortName) \(tokens) tokens (\(spent))"
    }

    /// A day's spend after its tokens in the week chart's tooltip: "· $6.55" (B-78).
    public static func weekChartSpend(_ amount: String) -> String {
        "· \(amount)"
    }

    /// Over the cycle totals, under the hovered legend (B-80).
    public static let thisCycle = "This cycle"

    /// The day a cycle total counts from, after its tokens: "since Oct 3" (B-80).
    public static func since(_ day: String) -> String {
        "since \(day)"
    }

    /// One provider's cycle total for VoiceOver: "Claude 48M tokens since Oct 3" (B-80).
    public static func cycleUsage(provider shortName: String, tokens: String, since day: String) -> String {
        "\(providerUsage(provider: shortName, tokens: tokens)) \(since(day))"
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

    public static let weekChartSubtitle = "Shows daily tokens per provider"

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
