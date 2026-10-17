import BurnieDomain
import Foundation

/// What Burnie remembers between launches, one key per setting (SPEC section 12).
public protocol SettingsStore: Sendable {
    /// A missing key loads as its default, and a missing `enabledProviders` as `defaultEnabled`.
    func load(defaultEnabled: Set<ProviderID>) -> AppSettings
    /// Writes only the key that changed, so a key the user never touched stays absent.
    func save(_ change: SettingChange)
}
