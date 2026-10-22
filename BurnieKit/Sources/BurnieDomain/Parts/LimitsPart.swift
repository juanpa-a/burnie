import Foundation

/// What a provider reports about its limits: the plan, the meters, how the plan measures usage, and the features. A
/// snapshot carries it stamped as one value, so merge keeps it whole, and its unit survives in the cache (B-8).
public struct LimitsPart: Hashable, Codable, Sendable {
    public var plan: PlanName?
    public var meters: MeterSet
    public var unit: UsageUnit
    public var features: SnapshotFeatures

    public init(plan: PlanName?, meters: MeterSet, unit: UsageUnit = .tokens, features: SnapshotFeatures = .empty) {
        self.plan = plan
        self.meters = meters
        self.unit = unit
        self.features = features
    }
}
