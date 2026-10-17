import Foundation

/// Where a provider or the runtime records what happened, for debugging. Bound to its category (a provider's id, or
/// the app's) when built. It takes no `String`, so nothing but a compile-time event name and numbers can reach the log
/// (B-64).
public protocol DiagnosticsLog: Sendable {
    func record(_ event: StaticString, _ measures: [Measure])
}
