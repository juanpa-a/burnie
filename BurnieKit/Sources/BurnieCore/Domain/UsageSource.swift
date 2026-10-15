import Foundation

/// Each provider's two sources, each with its own refresh pace.
public enum UsageSource: Sendable, Hashable, CaseIterable {
    /// Meters and plan: Claude's OAuth, Cursor's usage-summary.
    case limits
    /// Usage per day: Claude's local logs, Cursor's events.
    case activity
}
