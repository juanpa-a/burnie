// expect: none
import Foundation

/// A number clamped to 0...1, with an attribute on the declaration line.
@frozen public struct Fraction: Hashable, Sendable {
    public let value: Double
}
