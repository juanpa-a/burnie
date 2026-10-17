import Foundation

extension RuntimeState {
    /// The transition of one event; each topic lives in its own extension.
    mutating func apply(_ kind: Event.Kind, now: Date) -> [Effect] {
        switch kind {
        case .launched(let settings, let cached, let history):
            launch(settings: settings, cached: cached, history: history, now: now)
        case .popoverOpened(let request):
            openPopover(request, now: now)
        case .refreshRequested(let request):
            refresh(for: request, now: now)
        case .taskFinished(let key, let run, let outcome, let jitter):
            finish(key, run: run, outcome: outcome, jitter: jitter, now: now)
        case .timerFired(let key, let timer):
            fire(timer, of: key, now: now)
        case .trigger(let trigger):
            startRuns(of: enabledJobKeys, for: trigger, now: now)
        case .woke:
            [.wait(Self.wakeDelay, then: .trigger(.wake))]
        case .networkChanged(let isOnline, let jitter):
            changeNetwork(isOnline: isOnline, jitter: jitter, now: now)
        case .activityChanged(let id):
            startRuns(of: enabledJobKeys(of: id, yielding: .activity), for: .activityChanged, now: now)
        case .providerToggled(let id, let isOn):
            toggle(id, isOn: isOn, now: now)
        case .favoriteTapped(let id):
            tapFavorite(id)
        case .ringShownSet(let isShown):
            showRing(isShown)
        case .weekChartShownSet(let isShown):
            showWeekChart(isShown)
        case .featureShownSet(let toggle, let isShown):
            show(toggle, isShown)
        case .renewRequested(let id, let request):
            renewSignIn(of: id, for: request)
        case .renewFinished(let id, let succeeded, let request):
            finishRenewal(of: id, succeeded: succeeded, for: request, now: now)
        case .launchAtLoginSet(let isEnabled):
            [.setLaunchAtLogin(isEnabled)]
        case .launchAtLoginReadRequested:
            [.readLaunchAtLogin]
        case .launchAtLoginChanged(let status):
            changeLaunchAtLogin(to: status)
        case .launchAtLoginRead(let status):
            readLaunchAtLogin(status)
        case .updateFound(let version):
            findUpdate(version)
        case .installUpdateRequested:
            [.installUpdate]
        case .dashboardRequested(let id):
            provider(id).map { [.openURL($0.descriptor.dashboard.url)] } ?? []
        case .quitRequested:
            [.quit]
        }
    }

    /// How long after waking a refresh waits, so the network is back (B-38).
    static let wakeDelay: TimeInterval = 3
}
