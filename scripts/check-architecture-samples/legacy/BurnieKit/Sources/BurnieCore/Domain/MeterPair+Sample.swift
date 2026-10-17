// expect: G-4
import Foundation

extension MeterPair {
    static let sample = MeterPair(left: MeterReading(fraction: 0.2), right: MeterReading(fraction: 0.8))
}

/// A type declared in an extension file.
struct MeterPairSample {}
