// expect: D-3
import Foundation

/// Reads a setting straight from the defaults database instead of the SettingsStore port.
enum SettingsReader {
    static func showsRing() -> Bool {
        UserDefaults.standard.bool(forKey: "showRing")
    }
}
