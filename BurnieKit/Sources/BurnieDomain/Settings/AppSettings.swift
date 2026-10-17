import Foundation

/// What Burnie remembers between launches.
public struct AppSettings: Hashable, Sendable {
    /// The providers the user tracks. Turning one off deletes nothing.
    public var enabled: Set<ProviderID>
    /// The heart the user marked, remembered even while that provider is off.
    public var favorite: ProviderID?
    /// The "Ring in menu bar" switch, kept even while it's disabled (B-74).
    public var showRing: Bool
    /// The "Last 7 days" switch.
    public var showWeekChart: Bool
    /// The feature switches turned off.
    public var hiddenFeatures: Set<FeatureToggle>

    public init(
        enabled: Set<ProviderID>,
        favorite: ProviderID?,
        showRing: Bool,
        showWeekChart: Bool,
        hiddenFeatures: Set<FeatureToggle>
    ) {
        self.enabled = enabled
        self.favorite = favorite
        self.showRing = showRing
        self.showWeekChart = showWeekChart
        self.hiddenFeatures = hiddenFeatures
    }

    /// First launch: every provider in `enabled` tracked, no favorite, the ring and the week chart shown, no feature
    /// hidden (B-50).
    public static func defaults(enabled: Set<ProviderID>) -> AppSettings {
        AppSettings(enabled: enabled, favorite: nil, showRing: true, showWeekChart: true, hiddenFeatures: [])
    }
}
