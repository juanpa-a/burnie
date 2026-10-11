import Foundation

/// A source's pace and which triggers refresh it.
public struct RefreshPolicy: Sendable, Equatable {
    public let interval: TimeInterval
    /// Randomly added to or subtracted from each interval so the server isn't always hit on the same second.
    public let jitter: TimeInterval
    /// Age after which opening the popover refreshes; nil = opening the popover doesn't refresh this source.
    public let staleOnOpen: TimeInterval?
    public let needsNetwork: Bool

    public static func standard(for job: RefreshJob) -> RefreshPolicy {
        switch (job.provider, job.source) {
        case (.claude, .limits): RefreshPolicy(interval: 5 * 60, jitter: 30, staleOnOpen: 60, needsNetwork: true)
        // Logs notify through FSEvents; the timer is only a fallback and they don't need the network.
        case (.claude, .activity): RefreshPolicy(interval: 5 * 60, jitter: 0, staleOnOpen: nil, needsNetwork: false)
        case (.cursor, .limits): RefreshPolicy(interval: 10 * 60, jitter: 30, staleOnOpen: 60, needsNetwork: true)
        case (.cursor, .activity): RefreshPolicy(interval: 30 * 60, jitter: 0, staleOnOpen: 10 * 60, needsNetwork: true)
        }
    }

    /// Whether `trigger` should refresh this source, given when its last attempt finished.
    public func shouldRun(for trigger: RefreshTrigger, lastRun: Date?, now: Date) -> Bool {
        let age = lastRun.map { now.timeIntervalSince($0) } ?? .infinity
        return switch trigger {
        case .timer, .manual, .wake, .activityChanged: true
        case .popoverOpened: staleOnOpen.map { age > $0 } ?? false
        case .networkRestored: age > interval
        }
    }
}
