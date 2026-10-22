import BurnieDomain
import BurnieInterface
import Foundation

/// The one piece that performs effects (A-3): it calls the ports, holds the live timers and the continuations of the
/// use cases that await, and feeds what happens back as events.
@MainActor
final class Interpreter {
    /// Where the events go: the app model, which stamps and reduces them.
    var deliver: (Event.Kind) -> Void = { _ in }

    private let environment: AppEnvironment
    private let tasks: [JobKey: RefreshTask]
    private let renewals: [ProviderID: SignInRenewal]
    private let watchers: [ProviderID: any ActivityWatcher]
    private var timers: [JobKey: Task<Void, Never>] = [:]
    private var continuations: [RequestID: CheckedContinuation<Bool, Never>] = [:]
    private var nextRequest = RequestID(value: 0)

    init(environment: AppEnvironment) {
        self.environment = environment
        let bundles = environment.providers
        tasks = Dictionary(bundles.flatMap { bundle in
            bundle.tasks.map { (JobKey(provider: bundle.descriptor.id, task: $0.name), $0) }
        }, uniquingKeysWith: { first, _ in first })
        renewals = Dictionary(bundles.compactMap { bundle in
            bundle.capabilities.signInRenewal.map { (bundle.descriptor.id, $0) }
        }, uniquingKeysWith: { first, _ in first })
        watchers = Dictionary(bundles.compactMap { bundle in
            bundle.tasks.lazy.compactMap(\.watcher).first.map { (bundle.descriptor.id, $0) }
        }, uniquingKeysWith: { first, _ in first })
    }

    // MARK: Requests

    /// Draws a request for `event` and sends it, for a use case that doesn't wait (opening the popover).
    func send(_ event: (RequestID) -> Event.Kind) {
        deliver(event(drawRequest()))
    }

    /// Draws a request for `event`, sends it, and returns its result once every run it started finished.
    func request(_ event: (RequestID) -> Event.Kind) async -> Bool {
        let request = drawRequest()
        return await withCheckedContinuation { continuation in
            continuations[request] = continuation
            deliver(event(request))
        }
    }

    private func drawRequest() -> RequestID {
        defer { nextRequest = nextRequest.successor }
        return nextRequest
    }

    // MARK: Effects

    func perform(_ effect: Effect) {
        switch effect {
        case .runTask(let key, let run): runTask(key, run)
        case .scheduleTimer(let key, let timer, let delay): scheduleTimer(key, timer, after: delay)
        case .cancelTimer(let key): timers.removeValue(forKey: key)?.cancel()
        case .wait(let delay, let event): wait(delay, then: event)
        case .startWatcher(let id): startWatcher(id)
        case .stopWatcher(let id): watchers[id]?.stop()
        case .startSystemEvents: startSystemEvents()
        case .startUpdater: environment.updater.start { [weak self] version in self?.deliverOnMain(.updateFound(version)) }
        case .saveSnapshot(let snapshot): environment.snapshotCache.save(snapshot)
        case .saveHistory(let history): environment.snapshotCache.save(history)
        case .saveSetting(let change): environment.settingsStore.save(change)
        case .renewSignIn(let id, let request): renewSignIn(id, for: request)
        case .finishRequest(let request, let result): continuations.removeValue(forKey: request)?.resume(returning: result)
        case .setLaunchAtLogin(let isEnabled): setLaunchAtLogin(isEnabled)
        case .readLaunchAtLogin: deliver(.launchAtLoginRead(environment.loginItem.status()))
        case .openLoginItemsSettings: environment.loginItem.openSystemSettings()
        case .installUpdate: environment.updater.install()
        case .openURL(let url): environment.urlOpener.open(url)
        case .quit: environment.lifecycle.quit()
        }
    }

    /// Runs in a task of its own, apart from the timer that may have started it, so cancelling a timer never cancels a
    /// run in flight (B-36).
    private func runTask(_ key: JobKey, _ run: RunID) {
        guard let task = tasks[key] else { return }
        let jitter = environment.jitter
        Task { [weak self] in
            let outcome = await task.run()
            self?.deliver(.taskFinished(key, run, outcome, jitter: jitter()))
        }
    }

    /// Replaces any live timer of the job; its event names the timer, so a late one is recognized and dropped.
    private func scheduleTimer(_ key: JobKey, _ timer: TimerID, after delay: TimeInterval) {
        timers[key]?.cancel()
        let sleeper = environment.sleeper
        timers[key] = Task { [weak self] in
            guard (try? await sleeper.sleep(for: delay)) != nil else { return }
            self?.deliver(.timerFired(key, timer))
        }
    }

    private func wait(_ delay: TimeInterval, then event: Event.Kind) {
        let sleeper = environment.sleeper
        Task { [weak self] in
            guard (try? await sleeper.sleep(for: delay)) != nil else { return }
            self?.deliver(event)
        }
    }

    private func startWatcher(_ id: ProviderID) {
        watchers[id]?.start { [weak self] in self?.deliverOnMain(.activityChanged(id)) }
    }

    private func startSystemEvents() {
        let jitter = environment.jitter
        environment.systemEvents.start(
            onWake: { [weak self] in self?.deliverOnMain(.woke) },
            onNetworkChange: { [weak self] isOnline in self?.deliverOnMain(.networkChanged(isOnline: isOnline, jitter: jitter())) }
        )
    }

    private func renewSignIn(_ id: ProviderID, for request: RequestID) {
        guard let renewal = renewals[id] else {
            deliver(.renewFinished(id, succeeded: false, request))
            return
        }
        Task { [weak self] in
            let succeeded = await renewal.run()
            self?.deliver(.renewFinished(id, succeeded: succeeded, request))
        }
    }

    /// Reads the status back after setting it: macOS may want the user's approval (B-58).
    private func setLaunchAtLogin(_ isEnabled: Bool) {
        environment.loginItem.set(isEnabled)
        deliver(.launchAtLoginChanged(environment.loginItem.status()))
    }

    /// For the callbacks of watchers, system events and the updater, which may arrive on any thread.
    nonisolated private func deliverOnMain(_ event: Event.Kind) {
        Task { @MainActor [weak self] in self?.deliver(event) }
    }
}
