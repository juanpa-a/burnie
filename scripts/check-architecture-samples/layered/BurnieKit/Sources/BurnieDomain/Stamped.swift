// expect: G-6
import Foundation

/// A value and the moment it arrived, stamped with the system clock.
public struct Stamped<Value: Sendable & Equatable>: Sendable, Equatable {
    public let value: Value
    public let at: Date

    public static func now(_ value: Value) -> Stamped { Stamped(value: value, at: .now) }
}
