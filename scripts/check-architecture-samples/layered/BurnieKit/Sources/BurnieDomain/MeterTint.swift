// expect: G-3
import SwiftUI

/// A meter's color, which Domain can't know about.
public struct MeterTint: Equatable, Sendable {
    public let fraction: Double
}
