import Foundation

/// A refresh task's pace and which triggers run it.
public struct RefreshPolicy: Hashable, Sendable {
    public let interval: TimeInterval
    /// Randomly added to or subtracted from each interval, so the server isn't always hit on the same second.
    public let jitter: TimeInterval
    /// Age after which opening the popover refreshes; nil: opening the popover never refreshes this task.
    public let staleOnOpen: TimeInterval?
    public let needsNetwork: Bool

    public init(interval: TimeInterval, jitter: TimeInterval, staleOnOpen: TimeInterval?, needsNetwork: Bool) {
        self.interval = interval
        self.jitter = jitter
        self.staleOnOpen = staleOnOpen
        self.needsNetwork = needsNetwork
    }

    /// Whether `trigger` runs this task, given when its last run finished: timer, manual, wake and activity changed
    /// always do; opening the popover once older than `staleOnOpen`; network restored once older than the interval
    /// (B-31).
    public func shouldRun(for trigger: RefreshTrigger, lastRun: Date?, now: Date) -> Bool {
        let age = lastRun.map { now.timeIntervalSince($0) } ?? .infinity
        return switch trigger {
        case .timer, .manual, .wake, .activityChanged: true
        case .popoverOpened: staleOnOpen.map { age > $0 } ?? false
        case .networkRestored: age > interval
        }
    }
}
