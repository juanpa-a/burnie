import Foundation

/// What a provider reports about its limits: the plan, the meters and the features. A snapshot carries it stamped as
/// one value, so merge keeps it whole.
public struct LimitsPart: Hashable, Codable, Sendable {
    public var plan: PlanName?
    public var meters: MeterSet
    public var features: SnapshotFeatures

    public init(plan: PlanName?, meters: MeterSet, features: SnapshotFeatures = .empty) {
        self.plan = plan
        self.meters = meters
        self.features = features
    }
}
