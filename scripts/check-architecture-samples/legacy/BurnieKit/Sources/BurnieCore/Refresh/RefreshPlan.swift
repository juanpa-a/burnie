// expect: G-8
import Foundation

/// How often each part refreshes.
public struct RefreshPlan: Equatable, Sendable {
    // FIXME: read the interval from the provider.
    public let interval: Duration
}
