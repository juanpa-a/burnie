import Foundation

/// A user switch that hides a snapshot feature. Shown only while some enabled snapshot has the feature (B-40).
public enum FeatureToggle: Hashable, Sendable, CaseIterable {
    case onDemand
}
