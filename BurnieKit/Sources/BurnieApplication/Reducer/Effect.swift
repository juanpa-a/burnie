import BurnieDomain
import BurnieInterface
import Foundation

/// Something the reducer asks the interpreter to perform.
enum Effect: Equatable, Sendable {
    case runTask(JobKey, RunID)
    /// Replaces any live timer of the job.
    case scheduleTimer(JobKey, TimerID, after: TimeInterval)
    case cancelTimer(JobKey)
    case wait(TimeInterval, then: Event.Kind)
    case startWatcher(ProviderID)
    case stopWatcher(ProviderID)
    case startSystemEvents
    case startUpdater
    case saveSnapshot(UsageSnapshot)
    case saveHistory(UsageHistory)
    case saveSetting(SettingChange)
    case renewSignIn(ProviderID, RequestID)
    case finishRequest(RequestID, result: Bool)
    case setLaunchAtLogin(Bool)
    case readLaunchAtLogin
    case openLoginItemsSettings
    case installUpdate
    case openURL(URL)
    case quit
}
