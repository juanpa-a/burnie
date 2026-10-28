import BurnieDomain
import Foundation

/// The pure value the views render. Equatable, so SwiftUI only redraws on change; nothing in it depends on the time
/// except through the events that built it.
public struct AppState: Equatable, Sendable {
    /// Every known provider, in registry order.
    public var providers: [ProviderPanel]
    public var ring: RingState
    /// Ending the latest event's day; nil while its switch is off or nothing is enabled.
    public var weekChart: WeekChart?
    /// The most recent stamp among the enabled providers' snapshots.
    public var lastUpdated: Date?
    /// While any refresh request is open (B-59).
    public var isRefreshing: Bool
    public var settings: AppSettings
    /// The feature switches to show: those some enabled snapshot has a feature for, judged before hiding, so turning
    /// one off keeps its switch (B-40).
    public var visibleToggles: [FeatureToggle]
    public var launchAtLogin: Bool
    /// The version a newer Burnie on the release feed has (B-57).
    public var availableUpdate: String?
    /// The "Check for updates" row's phase (B-76).
    public var updateCheck: UpdateCheck

    public init(
        providers: [ProviderPanel],
        ring: RingState,
        weekChart: WeekChart?,
        lastUpdated: Date?,
        isRefreshing: Bool,
        settings: AppSettings,
        visibleToggles: [FeatureToggle],
        launchAtLogin: Bool,
        availableUpdate: String?,
        updateCheck: UpdateCheck
    ) {
        self.providers = providers
        self.ring = ring
        self.weekChart = weekChart
        self.lastUpdated = lastUpdated
        self.isRefreshing = isRefreshing
        self.settings = settings
        self.visibleToggles = visibleToggles
        self.launchAtLogin = launchAtLogin
        self.availableUpdate = availableUpdate
        self.updateCheck = updateCheck
    }

    /// The panels of the providers the user tracks, in registry order.
    public var enabledProviders: [ProviderPanel] {
        providers.filter(\.isEnabled)
    }
}
