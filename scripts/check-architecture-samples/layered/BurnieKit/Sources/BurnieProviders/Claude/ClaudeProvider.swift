// expect: none
import BurnieDomain
import BurnieInterface
import Foundation

/// Claude's entry point: provider ids, and switches on them, belong in BurnieProviders.
public enum ClaudeProvider {
    public static let descriptor = ProviderDescriptor(id: ProviderID(rawValue: "claude"), name: "Claude Code")

    // A literal URL, so it always parses.
    static let usageURL = URL(string: "https://example.com/api/oauth/usage")!

    static func isClaude(_ id: ProviderID) -> Bool {
        switch id {
        case .claude: true
        default: id == .cursor
        }
    }
}
