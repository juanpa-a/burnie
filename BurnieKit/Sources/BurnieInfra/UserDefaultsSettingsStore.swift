import BurnieDomain
import BurnieInterface
import Foundation

/// `SettingsStore` over `UserDefaults`, one key per setting, under the names of SPEC section 12. A key the user never
/// touched stays absent and loads as its default.
// `UserDefaults` serializes its own state: Apple documents it as safe to use from any thread.
public struct UserDefaultsSettingsStore: SettingsStore, @unchecked Sendable {
    /// The frozen keys.
    enum Key {
        static let enabledProviders = "enabledProviders"
        static let favoriteProvider = "favoriteProvider"
        static let showRing = "showRing"
        static let showWeekChart = "showWeekChart"

        /// Each feature switch's key; a new toggle adds its own here (SPEC section 12).
        static func shown(_ toggle: FeatureToggle) -> String {
            switch toggle {
            case .onDemand: "showOnDemand"
            }
        }
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Without `enabledProviders`, every provider in `defaultEnabled`, so one added in an update starts enabled. An id
    /// no longer known loads as it was saved; the runtime ignores it, and the next save of the key drops it.
    public func load(defaultEnabled: Set<ProviderID>) -> AppSettings {
        AppSettings(
            enabled: defaults.stringArray(forKey: Key.enabledProviders).map { Set($0.map(ProviderID.init(rawValue:))) } ?? defaultEnabled,
            favorite: defaults.string(forKey: Key.favoriteProvider).map(ProviderID.init(rawValue:)),
            showRing: isOn(Key.showRing),
            showWeekChart: isOn(Key.showWeekChart),
            hiddenFeatures: Set(FeatureToggle.allCases.filter { !isOn(Key.shown($0)) })
        )
    }

    public func save(_ change: SettingChange) {
        switch change {
        case .enabled(let enabled): defaults.set(enabled.map(\.rawValue).sorted(), forKey: Key.enabledProviders)
        case .favorite(let favorite): defaults.set(favorite?.rawValue, forKey: Key.favoriteProvider)
        case .ringShown(let isShown): defaults.set(isShown, forKey: Key.showRing)
        case .weekChartShown(let isShown): defaults.set(isShown, forKey: Key.showWeekChart)
        case .featureShown(let toggle, let isShown): defaults.set(isShown, forKey: Key.shown(toggle))
        }
    }

    /// A switch is on until the user turns it off.
    private func isOn(_ key: String) -> Bool {
        defaults.object(forKey: key) as? Bool ?? true
    }
}
