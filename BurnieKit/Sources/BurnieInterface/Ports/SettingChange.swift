import BurnieDomain
import Foundation

/// One setting the user changed, with its new value.
public enum SettingChange: Hashable, Sendable {
    case enabled(Set<ProviderID>)
    case favorite(ProviderID?)
    case ringShown(Bool)
    case weekChartShown(Bool)
    case featureShown(FeatureToggle, Bool)
}
