import Foundation
import Observation
import BurnieCore
import BurnieSystem

/// The app's single state: what the views read and the only thing that changes when a refresh arrives.
@MainActor @Observable
final class UsageStore {
    private(set) var states: [ProviderID: ProviderState] = [:]
    /// Always 7 points per provider, ending today.
    private(set) var history: [ProviderID: [DailyPoint]] = [:]
    private(set) var enabled: Set<ProviderID>
    /// The heart the user marked, remembered even while that provider is off.
    private(set) var favorite: ProviderID?
    /// The Ring in menu bar switch, kept even while it's disabled.
    private(set) var showRing: Bool
    /// The Last 7 days switch: whether the popover shows the week chart.
    private(set) var showWeekChart: Bool
    /// The On-demand switch: whether sections show the on-demand meter.
    private(set) var showOnDemand: Bool
    /// Where each provider reads from, for the providers screen ("~/.claude").
    private(set) var sourceLocations: [ProviderID: String]

    var isRefreshing: Bool { runningRefreshes > 0 }

    /// The provider the ring follows: the marked one if it's on, or the only one on.
    var effectiveFavorite: ProviderID? {
        Favorite.effective(stored: favorite, enabled: enabled)
    }

    var ring: RingState {
        Favorite.ring(stored: favorite, enabled: enabled, showRing: showRing, states: states)
    }

    /// Whether any enabled provider has on-demand enabled, which is when the On-demand switch appears.
    var hasOnDemand: Bool {
        enabled.contains { snapshot(for: $0)?.hasOnDemand == true }
    }

    /// The most recent data among the enabled providers.
    var lastUpdated: Date? {
        enabled.compactMap { snapshot(for: $0)?.fetchedAt }.max()
    }

    private var runningRefreshes = 0
    @ObservationIgnored private let providers: [ProviderID: ProviderAssembly]
    @ObservationIgnored private let cache: SnapshotStore
    /// Views take `now` from here, so previews with a fixed clock are deterministic.
    @ObservationIgnored let clock: Clock
    @ObservationIgnored private let sleeper: Sleeper
    @ObservationIgnored private let systemEvents: SystemEvents
    @ObservationIgnored private let enabledSetting: Setting<Set<ProviderID>>
    @ObservationIgnored private let favoriteSetting: Setting<ProviderID?>
    @ObservationIgnored private let showRingSetting: Setting<Bool>
    @ObservationIgnored private let showWeekChartSetting: Setting<Bool>
    @ObservationIgnored private let showOnDemandSetting: Setting<Bool>
    @ObservationIgnored private var usageHistory: UsageHistory
    @ObservationIgnored private var signInRenewers: [ProviderID: any SignInRenewer]
    @ObservationIgnored private var lastPopoverOpen: Date?
    @ObservationIgnored private var schedulerUpdate: Task<Void, Never>?
    @ObservationIgnored private lazy var scheduler = RefreshScheduler(clock: clock, sleeper: sleeper) { [weak self] job in
        await self?.refresh(job)
    }

    init(
        providers: [ProviderAssembly],
        cache: SnapshotStore,
        clock: Clock,
        sleeper: Sleeper,
        systemEvents: SystemEvents,
        enabledSetting: Setting<Set<ProviderID>>,
        favoriteSetting: Setting<ProviderID?>,
        showRingSetting: Setting<Bool>,
        showWeekChartSetting: Setting<Bool>,
        showOnDemandSetting: Setting<Bool>
    ) {
        self.providers = Dictionary(uniqueKeysWithValues: providers.map { ($0.id, $0) })
        sourceLocations = self.providers.compactMapValues(\.sourceLocation)
        signInRenewers = self.providers.compactMapValues(\.signInRenewer)
        self.cache = cache
        self.clock = clock
        self.sleeper = sleeper
        self.systemEvents = systemEvents
        self.enabledSetting = enabledSetting
        self.favoriteSetting = favoriteSetting
        self.showRingSetting = showRingSetting
        self.showWeekChartSetting = showWeekChartSetting
        self.showOnDemandSetting = showOnDemandSetting
        enabled = enabledSetting.load()
        favorite = favoriteSetting.load()
        showRing = showRingSetting.load()
        showWeekChart = showWeekChartSetting.load()
        showOnDemand = showOnDemandSetting.load()
        usageHistory = ((try? cache.load(CacheFile.history)) as UsageHistory?) ?? UsageHistory()
        for id in ProviderID.allCases {
            let cached: UsageSnapshot? = try? cache.load(CacheFile.snapshot(id))
            states[id] = cached.map(ProviderState.ready) ?? .loading
        }
        publishHistory()
    }

    #if DEBUG
    /// For previews: shows `states` and `history` as given, without providers, network or disk.
    convenience init(
        previewing states: [ProviderID: ProviderState],
        history: [ProviderID: [DailyPoint]],
        enabled: Set<ProviderID>,
        favorite: ProviderID?,
        showRing: Bool,
        showWeekChart: Bool,
        showOnDemand: Bool,
        sourceLocations: [ProviderID: String],
        signInRenewers: [ProviderID: any SignInRenewer],
        clock: Clock
    ) {
        self.init(
            providers: [],
            cache: NoCache(),
            clock: clock,
            sleeper: TaskSleeper(),
            systemEvents: NoSystemEvents(),
            enabledSetting: .fixed(enabled),
            favoriteSetting: .fixed(favorite),
            showRingSetting: .fixed(showRing),
            showWeekChartSetting: .fixed(showWeekChart),
            showOnDemandSetting: .fixed(showOnDemand)
        )
        self.states = states
        self.history = history
        self.sourceLocations = sourceLocations
        self.signInRenewers = signInRenewers
    }
    #endif

    func snapshot(for id: ProviderID) -> UsageSnapshot? {
        guard case .ready(let snapshot) = states[id] else { return nil }
        return snapshot
    }

    /// What a section shows: the provider's state, without the on-demand meter while its switch is off.
    func shownState(for id: ProviderID) -> ProviderState {
        let state = states[id] ?? .loading
        guard !showOnDemand, case .ready(let snapshot) = state else { return state }
        return .ready(snapshot.hidingOnDemand())
    }

    /// Starts timers, watchers and system events. Previews never call it, so they touch neither network nor disk.
    func start() {
        systemEvents.start(
            onWake: { [scheduler, sleeper] in
                Task {
                    try? await sleeper.sleep(for: 3)
                    await scheduler.trigger(.wake)
                }
            },
            onNetworkChange: { [scheduler] isOnline in
                Task { await scheduler.setOnline(isOnline) }
            }
        )
        for id in enabled {
            startWatching(id)
        }
        updateScheduler()
    }

    /// Opening the popover refreshes whatever is stale; both open signals arrive together, hence the debounce.
    /// Returns the refresh it started, so tests can wait for it, or nil when the debounce dropped the open.
    @discardableResult
    func popoverOpened() -> Task<Void, Never>? {
        let now = clock.now
        if let lastPopoverOpen, now.timeIntervalSince(lastPopoverOpen) < 1 { return nil }
        lastPopoverOpen = now
        return Task { await refreshAll(force: false) }
    }

    /// `force` is the Refresh button: every enabled source regardless of age, except during an active `retryAt`.
    func refreshAll(force: Bool) async {
        runningRefreshes += 1
        defer { runningRefreshes -= 1 }
        await scheduler.trigger(force ? .manual : .popoverOpened, for: enabled)
    }

    /// Whether an expired sign-in's row can offer to renew it.
    func canRenewSignIn(_ id: ProviderID) -> Bool {
        signInRenewers[id] != nil
    }

    /// The expired sign-in's button: the provider's own app renews it, then its limits refresh.
    /// Returns false if the app couldn't renew it.
    func renewSignIn(_ id: ProviderID) async -> Bool {
        guard let renewer = signInRenewers[id] else { return false }
        runningRefreshes += 1
        defer { runningRefreshes -= 1 }
        do {
            try await renewer.renewSignIn()
        } catch {
            return false
        }
        await scheduler.trigger(.manual, for: [id], source: .limits)
        return true
    }

    /// Turning a provider off deletes nothing: its cache and history stay on disk and come back when it's turned on.
    func setEnabled(_ id: ProviderID, _ isOn: Bool) {
        guard isOn != enabled.contains(id) else { return }
        if isOn {
            enabled.insert(id)
            startWatching(id)
        } else {
            enabled.remove(id)
            providers[id]?.watcher?.stop()
        }
        enabledSetting.save(enabled)
        updateScheduler()
    }

    /// One favorite at a time: a heart replaces the previous favorite, or clears it if it already was.
    func toggleFavorite(_ id: ProviderID) {
        favorite = Favorite.toggling(id, stored: favorite, enabled: enabled)
        favoriteSetting.save(favorite)
    }

    func setShowRing(_ isOn: Bool) {
        showRing = isOn
        showRingSetting.save(isOn)
    }

    func setShowWeekChart(_ isOn: Bool) {
        showWeekChart = isOn
        showWeekChartSetting.save(isOn)
    }

    func setShowOnDemand(_ isOn: Bool) {
        showOnDemand = isOn
        showOnDemandSetting.save(isOn)
    }

    // MARK: Refresh

    /// Refreshes one source and returns its issue, so the scheduler can decide the backoff.
    private func refresh(_ job: RefreshJob) async -> ProviderIssue? {
        guard let provider = providers[job.provider]?.provider, enabled.contains(job.provider) else { return nil }
        let limitsIssue = await refreshSnapshot(of: provider, source: job.source)
        switch job.source {
        case .limits: return limitsIssue
        case .activity: return await refreshHistory(of: provider)
        }
    }

    private func refreshSnapshot(of provider: any UsageProvider, source: UsageSource) async -> ProviderIssue? {
        do {
            let snapshot = try await provider.snapshot(refreshing: [source])
            let shown = snapshot.keepingMeters(of: self.snapshot(for: provider.id))
            states[provider.id] = .ready(shown)
            try? cache.save(shown, as: CacheFile.snapshot(provider.id))
            return snapshot.issue
        } catch {
            states[provider.id] = snapshot(for: provider.id).map { .ready($0.with(issue: error)) } ?? .failed(error)
            return error
        }
    }

    private func refreshHistory(of provider: any UsageProvider) async -> ProviderIssue? {
        do {
            let points = try await provider.history(days: ActivityWindow.dayCount)
            usageHistory.record(points, for: provider.id, today: today)
            try? cache.save(usageHistory, as: CacheFile.history)
            publishHistory()
            return nil
        } catch {
            return error
        }
    }

    private func publishHistory() {
        history = Dictionary(uniqueKeysWithValues: ProviderID.allCases.map { ($0, usageHistory.points(for: $0, endingAt: today)) })
    }

    private var today: LocalDay {
        LocalDay(clock.now, in: clock.timeZone)
    }

    // MARK: Wiring

    private func startWatching(_ id: ProviderID) {
        providers[id]?.watcher?.start { [scheduler] in
            Task { await scheduler.trigger(.activityChanged, for: [id], source: .activity) }
        }
    }

    /// Scheduler updates are chained so a quick off/on doesn't arrive out of order.
    private func updateScheduler() {
        let active = enabled.filter { providers[$0] != nil }
        schedulerUpdate = Task { [previous = schedulerUpdate, scheduler] in
            await previous?.value
            await scheduler.setActive(active)
        }
    }

    #if DEBUG
    /// The previews' cache: it never has anything and never saves anything.
    private struct NoCache: SnapshotStore {
        func load<T: Codable>(_ name: String) throws -> T? { nil }
        func save<T: Codable>(_ value: T, as name: String) throws {}
    }

    /// The previews' system events: previews never start the store, so nothing ever reports.
    private struct NoSystemEvents: SystemEvents {
        func start(onWake: @escaping @Sendable () -> Void, onNetworkChange: @escaping @Sendable (_ isOnline: Bool) -> Void) {}
    }
    #endif

    /// Names of the cache files in `Application Support/Burnie/`.
    private enum CacheFile {
        static let history = "history"

        static func snapshot(_ id: ProviderID) -> String {
            "snapshot-\(id.rawValue)"
        }
    }
}
