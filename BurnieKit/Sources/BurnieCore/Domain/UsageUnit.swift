import Foundation

/// How a plan measures usage, which decides how the header reads today's usage.
public enum UsageUnit: Sendable, Equatable {
    /// Subscriptions with percentage windows: Claude, Cursor's individual pools.
    case tokens
    /// Plans with a dollar budget: Cursor's team and enterprise plans.
    case money
}
