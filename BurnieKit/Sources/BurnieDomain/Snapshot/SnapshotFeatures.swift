import Foundation

/// What a snapshot carries besides its meter set, each optional and drawn after the meters. They travel inside the
/// limits part, so they change with the plan and merge never splits them from the meters.
public struct SnapshotFeatures: Hashable, Codable, Sendable {
    public static let empty = SnapshotFeatures()

    /// Spend past the included usage, when the plan has it on.
    public var onDemand: Meter?

    public init(onDemand: Meter? = nil) {
        self.onDemand = onDemand
    }

    /// Whether the feature `toggle` hides is here, which is when its switch appears (B-40).
    public func has(_ toggle: FeatureToggle) -> Bool {
        switch toggle {
        case .onDemand: onDemand != nil
        }
    }

    /// Without the features the user switched off.
    public func hiding(_ toggles: Set<FeatureToggle>) -> SnapshotFeatures {
        var shown = self
        for toggle in toggles {
            switch toggle {
            case .onDemand: shown.onDemand = nil
            }
        }
        return shown
    }
}
