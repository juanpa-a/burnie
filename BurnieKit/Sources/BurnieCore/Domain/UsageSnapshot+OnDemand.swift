import Foundation

extension UsageSnapshot {
    /// Whether the plan has on-demand enabled: only then is there a meter for the On-demand switch to hide.
    public var hasOnDemand: Bool {
        meters.contains { $0.id == .onDemand }
    }

    /// The snapshot without its on-demand meter, for when the On-demand switch is off.
    public func hidingOnDemand() -> UsageSnapshot {
        var snapshot = self
        snapshot.meters.removeAll { $0.id == .onDemand }
        return snapshot
    }
}
