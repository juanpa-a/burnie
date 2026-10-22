import Foundation

/// The meters of one snapshot, in display order and never empty: the primary meter, which represents the provider at a
/// glance and drives the menu bar ring, then the others.
public struct MeterSet: Hashable, Codable, Sendable {
    public let primary: Meter
    public let others: [Meter]

    public init(primary: Meter, others: [Meter] = []) {
        self.primary = primary
        self.others = others
    }

    /// The meters in display order, the first one primary; nil for none, the one value a meter set can't hold.
    public init?(_ meters: [Meter]) {
        guard let primary = meters.first else { return nil }
        self.init(primary: primary, others: Array(meters.dropFirst()))
    }

    /// Every meter in display order, the primary one first.
    public var all: [Meter] {
        [primary] + others
    }

    /// The longest period among the meters, which the provider's usage is counted over (B-79); nil when no meter has
    /// one.
    public var cycle: DateInterval? {
        all.compactMap(\.period).max { $0.duration < $1.duration }
    }
}
