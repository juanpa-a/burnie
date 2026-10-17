// expect: none
import Foundation

/// The name a provider goes by. Switching on a provider and spelling its id are still fine on today's layout:
/// G-5 wakes with BurnieProviders, D-6 with BurnieDomain.
public enum ProviderName {
    public static func of(_ id: ProviderID) -> String {
        switch id {
        case .claude: "Claude Code"
        case .cursor: "Cursor"
        }
    }

    public static func isClaude(_ id: ProviderID) -> Bool { id == .claude || id.rawValue == "claude" }
}
