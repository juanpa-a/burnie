// expect: G-6
import Foundation

/// When the current session resets, checked against the system clock.
public struct SessionDeadline: Equatable, Sendable {
    public let resetsAt: Date

    public var hasPassed: Bool { resetsAt < Date() }
}
