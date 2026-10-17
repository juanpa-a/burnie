import Foundation

/// What the line under a meter means.
public enum MeterCaption: Hashable, Sendable {
    /// "Resets in 2h 14m"
    case resetsIn(Date)
    /// "Resets Thu, 9:00 AM"
    case resetsAt(Date)
    /// "Resets Nov 1 · 21 days left"
    case cycleEnds(Date)
    /// "No active session"
    case noActiveSession
    /// "Kicks in after included usage runs out"
    case onDemandIdle
}
