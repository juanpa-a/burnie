import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInfra

/// The settings as `UserDefaults` keeps them between launches (SPEC section 12). Each test gets a defaults suite of its
/// own, named by an absolute path, which `CFPreferences` keeps at `<path>.plist` instead of in `~/Library/Preferences`,
/// inside a temporary directory removed when the test ends.
final class UserDefaultsSettingsStoreTests {
    private let directory = FileManager.default.temporaryDirectory.appending(path: "burnie-settings-\(UUID().uuidString)")
    private let suiteName: String
    private let defaults: UserDefaults
    private let store: UserDefaultsSettingsStore

    init() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        suiteName = directory.appending(path: "defaults").path
        defaults = try #require(UserDefaults(suiteName: suiteName))
        store = UserDefaultsSettingsStore(defaults: defaults)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: directory)
    }

    @Test("B-50 first launch: every provider enabled, ring, week chart and on-demand on, and no favorite")
    func firstLaunchDefaults() {
        #expect(store.load(defaultEnabled: [.alpha, .beta]) == .defaults(enabled: [.alpha, .beta]))
        #expect(defaults.object(forKey: "enabledProviders") == nil)
    }

    @Test("SPEC 12 enabledProviders saves the provider ids as a sorted array")
    func enabledProvidersSavesASortedArray() {
        store.save(.enabled([.beta, .alpha]))
        #expect(defaults.stringArray(forKey: "enabledProviders") == ["alpha", "beta"])
        #expect(store.load(defaultEnabled: []).enabled == [.alpha, .beta])
    }

    @Test("SPEC 12 enabledProviders saved empty loads as no provider, not as every provider")
    func enabledProvidersSavedEmptyStaysEmpty() {
        store.save(.enabled([]))
        #expect(defaults.stringArray(forKey: "enabledProviders") == [])
        #expect(store.load(defaultEnabled: [.alpha]).enabled.isEmpty)
    }

    @Test("SPEC 12 saving another setting never writes enabledProviders, so an absent key stays absent")
    func otherSettingsLeaveEnabledProvidersAbsent() {
        store.save(.favorite(.alpha))
        store.save(.ringShown(false))
        store.save(.featureShown(.onDemand, false))
        #expect(defaults.object(forKey: "enabledProviders") == nil)
        #expect(store.load(defaultEnabled: [.alpha, .beta]).enabled == [.alpha, .beta])
    }

    @Test("B-52 an unknown stored favorite loads as saved and the key is left as is")
    func unknownFavoriteIsLeftAsIs() {
        defaults.set("gone", forKey: "favoriteProvider")
        #expect(store.load(defaultEnabled: [.alpha]).favorite == ProviderID(rawValue: "gone"))
        #expect(Favorite.effective(stored: store.load(defaultEnabled: [.alpha, .beta]).favorite, enabled: [.alpha, .beta]) == nil)
        #expect(defaults.string(forKey: "favoriteProvider") == "gone")
    }

    @Test("SPEC 12 favoriteProvider saves the provider id, and no favorite removes the key")
    func favoriteProviderSavesTheID() {
        store.save(.favorite(.beta))
        #expect(defaults.string(forKey: "favoriteProvider") == "beta")
        #expect(store.load(defaultEnabled: []).favorite == .beta)

        store.save(.favorite(nil))
        #expect(defaults.object(forKey: "favoriteProvider") == nil)
    }

    @Test("SPEC 12 showRing, showWeekChart and showOnDemand are on until saved off, each under its own key")
    func displaySwitchesAreOnByDefault() {
        #expect(store.load(defaultEnabled: []).showRing)
        store.save(.ringShown(false))
        store.save(.weekChartShown(false))
        store.save(.featureShown(.onDemand, false))
        #expect(defaults.object(forKey: "showRing") as? Bool == false)
        #expect(defaults.object(forKey: "showWeekChart") as? Bool == false)
        #expect(defaults.object(forKey: "showOnDemand") as? Bool == false)
        let settings = store.load(defaultEnabled: [])
        #expect(!settings.showRing && !settings.showWeekChart && settings.hiddenFeatures == [.onDemand])
    }
}
