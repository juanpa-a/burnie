import BurnieDomain
import BurnieInterface
import Foundation

/// Something that happened that may change the state, stamped with the moment it was sent and that moment's local day.
/// The reducer never reads a clock (A-5).
struct Event: Equatable, Sendable {
    let kind: Kind
    let now: Date
    let today: LocalDay

    enum Kind: Equatable, Sendable {
        case launched(settings: AppSettings, cached: [ProviderID: UsageSnapshot], history: UsageHistory)
        case popoverOpened(RequestID)
        case refreshRequested(RequestID)
        /// `jitter` is a sample in -1…1 for the timer it arms.
        case taskFinished(JobKey, RunID, Result<Part, ProviderIssue>, jitter: Double)
        case timerFired(JobKey, TimerID)
        case trigger(RefreshTrigger)
        case woke
        /// `jitter` is a sample in -1…1 for the timers it arms.
        case networkChanged(isOnline: Bool, jitter: Double)
        case activityChanged(ProviderID)
        case providerToggled(ProviderID, isOn: Bool)
        case favoriteTapped(ProviderID)
        case ringShownSet(Bool)
        case weekChartShownSet(Bool)
        case featureShownSet(FeatureToggle, Bool)
        case renewRequested(ProviderID, RequestID)
        case renewFinished(ProviderID, succeeded: Bool, RequestID)
        case launchAtLoginSet(Bool)
        case launchAtLoginReadRequested
        case launchAtLoginChanged(LoginItemStatus)
        case launchAtLoginRead(LoginItemStatus)
        case updateFound(String?)
        case installUpdateRequested
        case dashboardRequested(ProviderID)
        case quitRequested
    }
}
