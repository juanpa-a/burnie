import Foundation

extension UsageSnapshot {
    /// The snapshot without the features the user switched off (B-40). Only the features change: the meter set,
    /// today's usage, the issue and the stamp stay.
    public func hiding(_ toggles: Set<FeatureToggle>) -> UsageSnapshot {
        guard case .limits(var view, let today) = content else { return self }
        view.value.features = view.value.features.hiding(toggles)
        var shown = self
        shown.content = .limits(view: view, today: today)
        return shown
    }
}
