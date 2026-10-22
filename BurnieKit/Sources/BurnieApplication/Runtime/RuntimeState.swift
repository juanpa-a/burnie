import BurnieDomain
import Foundation

/// Everything the runtime knows. Only the reducer changes it.
struct RuntimeState: Equatable, Sendable {
    /// Registry order, built once from the bundles.
    let registry: [RegisteredProvider]
    /// The latest event's local day: what compose, the history and the week chart count as today.
    var today: LocalDay
    /// The latest event's time zone: what turns a cycle's start into a local day (B-79).
    var timeZone: TimeZone
    var settings: AppSettings
    var parts: [ProviderID: ProviderParts] = [:]
    /// After compose and merge, or failing; the cache keeps it only after a success.
    var shown: [ProviderID: ProviderState] = [:]
    var history = UsageHistory()
    /// One per refresh task of each enabled provider.
    var jobs: [JobKey: JobState] = [:]
    var nextRun = RunID(value: 0)
    var nextTimer = TimerID(value: 0)
    /// The open refresh requests; the spinner shows while there's any.
    var requests: [RequestID: PendingRequest] = [:]
    /// The last popover open that wasn't debounced (B-39).
    var lastPopoverOpen: Date?
    /// True until the system reports otherwise (B-34).
    var isOnline = true
    var launchAtLogin = false
    var availableUpdate: String?

    /// Before launch: every provider of the registry enabled and nothing shown, until `launched` brings what was saved.
    init(registry: [RegisteredProvider], today: LocalDay, timeZone: TimeZone) {
        self.registry = registry
        self.today = today
        self.timeZone = timeZone
        settings = .defaults(enabled: Set(registry.map(\.id)))
    }

    func provider(_ id: ProviderID) -> RegisteredProvider? {
        registry.first { $0.id == id }
    }

    /// The job keys of the enabled providers, in registry and task order.
    var enabledJobKeys: [JobKey] {
        registry.filter { settings.enabled.contains($0.id) }.flatMap(\.jobKeys).filter { jobs[$0] != nil }
    }
}
