// expect: G-4
import Foundation

/// Two meters shown side by side.
public struct MeterPair: Equatable, Sendable {
    public let left: MeterReading
    public let right: MeterReading
}

/// A second top-level type in the same file.
public struct MeterReading: Equatable, Sendable {
    public let fraction: Double
}
