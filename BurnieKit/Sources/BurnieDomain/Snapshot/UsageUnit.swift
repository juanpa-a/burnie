import Foundation

/// How a plan measures usage, which decides how the header reads today's usage.
public enum UsageUnit: Hashable, Sendable {
    /// Subscriptions with percentage windows.
    case tokens
    /// Plans with a dollar budget.
    case money
}
