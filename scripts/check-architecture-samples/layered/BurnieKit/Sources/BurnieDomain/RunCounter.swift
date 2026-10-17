// expect: D-2
import Foundation

/// A counter shared through a static var.
public struct RunCounter: Sendable {
    nonisolated(unsafe) static var next = 0
}
