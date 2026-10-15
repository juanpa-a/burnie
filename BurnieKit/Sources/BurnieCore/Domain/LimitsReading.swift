import Foundation

/// What a `LimitsSource` delivers: the plan, the meters in render order, and how the plan measures usage.
public struct LimitsReading: Sendable, Equatable {
    public var plan: String?
    public var meters: [Meter]
    public var unit: UsageUnit

    public init(plan: String?, meters: [Meter], unit: UsageUnit = .tokens) {
        self.plan = plan
        self.meters = meters
        self.unit = unit
    }
}
