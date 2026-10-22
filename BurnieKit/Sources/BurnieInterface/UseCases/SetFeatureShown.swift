import BurnieDomain
import Foundation

/// A feature switch, like "On-demand" (B-40).
public struct SetFeatureShown: Sendable {
    private let action: @MainActor @Sendable (FeatureToggle, Bool) -> Void

    public init(_ action: @escaping @MainActor @Sendable (FeatureToggle, Bool) -> Void) {
        self.action = action
    }

    @MainActor
    public func callAsFunction(_ toggle: FeatureToggle, _ isShown: Bool) {
        action(toggle, isShown)
    }
}
