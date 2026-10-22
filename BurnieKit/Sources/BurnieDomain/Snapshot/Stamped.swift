import Foundation

/// A value and the moment it arrived.
public struct Stamped<Value> {
    public var value: Value
    public var at: Date

    public init(_ value: Value, at date: Date) {
        self.value = value
        at = date
    }

    /// The same moment with the value transformed.
    public func map<Transformed>(_ transform: (Value) -> Transformed) -> Stamped<Transformed> {
        Stamped<Transformed>(transform(value), at: at)
    }
}

extension Stamped: Equatable where Value: Equatable {}
extension Stamped: Hashable where Value: Hashable {}
extension Stamped: Sendable where Value: Sendable {}
extension Stamped: Codable where Value: Codable {}
