import Foundation

/// What a `LimitsSource` delivers: the plan and the meters in render order.
public struct LimitsReading: Sendable, Equatable {
    public var plan: String?
    public var meters: [Meter]

    public init(plan: String?, meters: [Meter]) {
        self.plan = plan
        self.meters = meters
    }
}
