import Foundation
import BurnieCore

extension Setting where Value == Set<ProviderID> {
    /// "enabledProviders": an array of `ProviderID.rawValue`. On first launch every provider is enabled.
    static func enabledProviders(_ defaults: UserDefaults = .standard) -> Setting {
        let key = "enabledProviders"
        return Setting(
            load: {
                guard let saved = defaults.stringArray(forKey: key) else { return Set(ProviderID.allCases) }
                return Set(saved.compactMap(ProviderID.init(rawValue:)))
            },
            save: { defaults.set($0.map(\.rawValue).sorted(), forKey: key) }
        )
    }
}

extension Setting where Value == ProviderID? {
    /// "favoriteProvider": the heart the user marked, never the implicit favorite. Absent until a heart is tapped;
    /// an id Burnie no longer knows reads as no favorite and the key stays as it is.
    static func favoriteProvider(_ defaults: UserDefaults = .standard) -> Setting {
        let key = "favoriteProvider"
        return Setting(
            load: { defaults.string(forKey: key).flatMap(ProviderID.init(rawValue:)) },
            save: { defaults.set($0?.rawValue, forKey: key) }
        )
    }
}

extension Setting where Value == Bool {
    /// "showRing": the Ring in menu bar switch, kept even while it's disabled. On by default.
    static func showRing(_ defaults: UserDefaults = .standard) -> Setting {
        let key = "showRing"
        return Setting(
            load: { defaults.object(forKey: key) as? Bool ?? true },
            save: { defaults.set($0, forKey: key) }
        )
    }
}
