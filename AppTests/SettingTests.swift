import BurnieCore
import Foundation
import Testing

/// The settings as `UserDefaults` keeps them between launches (SPEC section 12). Each test gets a defaults suite of
/// its own, named by an absolute path, which `CFPreferences` keeps at `<path>.plist` instead of in
/// `~/Library/Preferences`, inside a temporary directory removed when the test ends.
final class SettingTests {
    /// The three display switches, each on by default under its own key.
    enum DisplaySwitch: CaseIterable, Sendable {
        case ring, weekChart, onDemand

        var key: String {
            switch self {
            case .ring: "showRing"
            case .weekChart: "showWeekChart"
            case .onDemand: "showOnDemand"
            }
        }

        func setting(in defaults: UserDefaults) -> Setting<Bool> {
            switch self {
            case .ring: .showRing(defaults)
            case .weekChart: .showWeekChart(defaults)
            case .onDemand: .showOnDemand(defaults)
            }
        }
    }

    private let directory = FileManager.default.temporaryDirectory.appending(path: "burnie-settings-\(UUID().uuidString)")
    private let suiteName: String
    private let defaults: UserDefaults

    init() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        suiteName = directory.appending(path: "defaults").path
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: directory)
    }

    @Test("B-50 first launch: every provider enabled, ring, week chart and on-demand on, and no favorite")
    func firstLaunchDefaults() {
        let enabled: Setting<Set<ProviderID>> = .enabledProviders(defaults)
        let favorite: Setting<ProviderID?> = .favoriteProvider(defaults)
        #expect(enabled.load() == Set(ProviderID.allCases))
        #expect(favorite.load() == nil)
        #expect(DisplaySwitch.allCases.allSatisfy { $0.setting(in: defaults).load() })
        #expect(defaults.object(forKey: "enabledProviders") == nil)
    }

    @Test("enabledProviders saves the provider ids as a sorted array")
    func enabledProvidersSavesASortedArray() {
        let enabled: Setting<Set<ProviderID>> = .enabledProviders(defaults)
        enabled.save([.cursor, .claude])
        #expect(defaults.stringArray(forKey: "enabledProviders") == ["claude", "cursor"])
        #expect(enabled.load() == [.claude, .cursor])
    }

    @Test("enabledProviders saved empty loads as no provider, not as every provider")
    func enabledProvidersSavedEmptyStaysEmpty() {
        let enabled: Setting<Set<ProviderID>> = .enabledProviders(defaults)
        enabled.save([])
        #expect(defaults.stringArray(forKey: "enabledProviders") == [])
        #expect(enabled.load().isEmpty)
    }

    @Test("enabledProviders ignores ids it doesn't know, keeps them stored, and drops them on its next save")
    func enabledProvidersDropsUnknownIdsOnTheNextSave() {
        defaults.set(["gemini", "cursor"], forKey: "enabledProviders")
        let enabled: Setting<Set<ProviderID>> = .enabledProviders(defaults)
        let loaded = enabled.load()
        #expect(loaded == [.cursor])
        #expect(defaults.stringArray(forKey: "enabledProviders") == ["gemini", "cursor"])

        enabled.save(loaded.union([.claude]))
        #expect(defaults.stringArray(forKey: "enabledProviders") == ["claude", "cursor"])
    }

    @Test("B-52 an unknown stored favorite reads as none and the key is left as is")
    func unknownFavoriteReadsAsNone() {
        defaults.set("gemini", forKey: "favoriteProvider")
        let favorite: Setting<ProviderID?> = .favoriteProvider(defaults)
        #expect(favorite.load() == nil)
        #expect(defaults.string(forKey: "favoriteProvider") == "gemini")
    }

    @Test("favoriteProvider saves the provider id, and no favorite removes the key")
    func favoriteProviderSavesTheId() {
        let favorite: Setting<ProviderID?> = .favoriteProvider(defaults)
        favorite.save(.cursor)
        #expect(defaults.string(forKey: "favoriteProvider") == "cursor")
        #expect(favorite.load() == .cursor)

        favorite.save(nil)
        #expect(defaults.object(forKey: "favoriteProvider") == nil)
    }

    @Test("showRing, showWeekChart and showOnDemand are on until saved off, each under its own key", arguments: DisplaySwitch.allCases)
    func displaySwitchIsOnByDefault(_ displaySwitch: DisplaySwitch) {
        let setting = displaySwitch.setting(in: defaults)
        #expect(setting.load())

        setting.save(false)
        #expect(defaults.object(forKey: displaySwitch.key) as? Bool == false)
        #expect(!setting.load())
    }
}
